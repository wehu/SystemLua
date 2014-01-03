--[[
Copyright (c) 2013 Wei Hu, huwei04@hotmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

require "sl_logger"
require "sl_util"
require "sl_scheduler"

sl_component = {ids=0, components={}}

sl_component_by_id = {}

sl_current_component = nil

sl_top_components = {}

function sl_component:new(name, body)
  sl_checktype(name, "string")
  if string.match(name, "%.") then
    err("attempt to create a component \'"..name.."\' whose name includes \".\"")
  end
  if body then
    sl_checktype(body, "function")
  end
  local o = {name=name, type="component", path=name,
    parent=sl_current_component,
    virtual=false,
    foreign=false,
    children={},
    static_phases={
      build=true,
      connect=true
    },
    runtime_phases={
      run=true
    },
    phases_done={},
    id=sl_component.ids}
  sl_component.ids = sl_component.ids + 1
  if not sl_current_component then
    table.insert(sl_top_components, o)
  end
  if sl_current_component then
    o.path = sl_current_component.path.."."..name
    table.insert(sl_current_component.children, o)
  end
  setmetatable(o, {__index = sl_component})
  if body then
    o:_new(body)
  end
  sl_component.components[o.path] = o
  sl_component_by_id[o.id] = o
  return o
end

function sl_component:_new(body)
  local saved_sl_current_component = sl_current_component
  sl_current_component = self
  local o = self
  local _, e = pcall(function()
    body(o)
  end)
  sl_current_component = saved_sl_current_component
  if e then error(e) end
end

function sl_component:notify_phase(group, name, action)
  sl_checktype(group, "string")
  sl_checktype(name, "string")
  if action then sl_checktype(action, "number") end
  for i, v in ipairs(self.children) do
    v:notify_phase(group, name, action)
  end
  if self[name] and not self.phases_done[name] and self.static_phases[name] then
    if sl_simulator.started then
      err("attempt to notify static phase "..name.." after simulation is started")
    end
    self.phases_done[name] = true
    self[name](self)
  elseif self.runtime_phases[name] then
  end
end

function sl_component:notify_runtime_phase(group, name, action)
  sl_checktype(group, "string")
  sl_checktype(name, "string")
  if action then sl_checktype(action, "number") end
  for i, v in ipairs(self.children) do
    v:notify_runtime_phase(group, name, action)
  end
  if self[name] and not self.phases_done[name] and self.runtime_phases[name] then
    self.phases_done[name] = true
    local o = self
    sl_scheduler:thread(function ()
      self[name](o)
    end)
  end
end

function component(name, body)
  sl_checktype(name, "string")
  local c = nil
  if sl_current_component then
    c = sl_component.components[sl_current_component.path.."."..name]
  end
  if not c then
    c = sl_component.components[name]
  end
  if not c then
    c = sl_component:new(name)
  end
  if body then
    sl_checktype(body, "function")
    c:_new(body) 
  end
  return c
end

function notify_phase(group, name, action)
  sl_checktype(name, "string")
  for i, v in ipairs(sl_top_components) do
    if not v.virtual then
      v:notify_phase(group, name, action)
    end
  end
end

function notify_runtime_phase(group, name, action)
  sl_checktype(name, "string")
  for k, v in pairs(sl_top_components) do
    if not v.virtual then
      v:notify_runtime_phase(group, name, action)
    end
  end
end

local virtual_component = component("virtual")
virtual_component.virtual = true 

function uvm_sl_ml_create_component(class, name, parent_full_path, parent_fwid, parent_id)
  local saved_parent = sl_current_component
  sl_current_component = virtual_component
  virtual_component.path = parent_full_path
  local c = nil
  local _, e = pcall(function ()
    if not _G[class] then
      err("cannot find component class "..class)
    end
    c = _G[class](name)
  end)
  if e then
    err(e)
  end
  c.parent_full_path = parent_full_path
  c.parent_fwid = parent_fwid
  c.parent_id = parent_id
  if parent_full_path == "" then
    table.insert(sl_top_components, c)
  end
  virtual_component.path = "virtual"
  sl_current_component = saved_parent
  return c
end

function component_proxy(target_fwind, class, name)
  local cp = component(name)
  cp.foreign = true
  cp.target_fwind = target_fwind
  cp.class = class
  cp.proxy_id = uvm_sl_ml_create_component_proxy(target_fwind, class, name, cp.path, cp.id)
  function cp:notify_phase(group, name, action)
    uvm_sl_ml_notify_tree_phase(self.target_fwind, self.proxy_id, group, name)
  end
  return cp
end

function find_component_by_id(id)
  sl_checktype(id, "number")
  local c = sl_component_by_id[id]
  if not c then
    err("unknown component by id "..id)
  end
  return c
end

function notify_phase_by_id(id, group, phase, action)
  local c = find_component_by_id(id)
  c:notify_phase(group, phase, action)
end

function find_component_by_full_name(name)
  sl_checktype(name, "string")
  local c = sl_component.components[name]
  if not c then
    err("unknown component by full name "..name)
  end
  return c
end

