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
    proxy=false,
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

function sl_component:notify_phase(name)
  sl_checktype(name, "string")
  for i, v in ipairs(self.children) do
    v:notify_phase(name)
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

function sl_component:notify_runtime_phase(name)
  sl_checktype(name, "string")
  --for i, v in ipairs(self.children) do
  --  v:notify_runtime_phase(name)
  --end
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

function notify_phase(name)
  sl_checktype(name, "string")
  for i, v in ipairs(sl_top_components) do
    if name ~= "proxy" then
      v:notify_phase(name)
    end
  end
end

function notify_runtime_phase(name)
  sl_checktype(name, "string")
  for k, v in pairs(sl_component.components) do
    if v.name ~= "proxy" then
      v:notify_runtime_phase(name)
    end
  end
end

local comp_proxy = component("proxy")
comp_proxy.proxy = true 

function component_proxy(class, name, parent_full_path, parent_fwid, parent_id)
  local saved_parent = sl_current_component
  sl_current_component = comp_proxy
  comp_proxy.path = parent_full_path
  local cp = nil
  local _, e = pcall(function ()
    cp = _G[class](name)
  end)
  cp.proxy = true
  cp.parent_full_path = parent_full_path
  cp.parent_fwid = parent_fwid
  cp.parent_id = parent_id
  if parent_full_path == "" then
    table.insert(sl_top_components, cp)
  end
  comp_proxy.path = "proxy"
  sl_current_component = saved_parent
  if e then
    error(e)
  end
  return cp
end

function foreign_component(target_fwind, class, name)
  local fc = component(name)
  fc.foreign = true
  fc.target_fwind = target_fwind
  fc.class = class
  function fc:notify_phase(name)
    uvm_sl_ml_notify_phase(self.target_fwind, self.parent.id, name)
  end
  return fc
end

function find_component_by_id(id)
  sl_checktype(id, "number")
  local c = sl_component_by_id[id]
  if not c then
    err("unknown component by id "..id)
  end
  return c
end

function find_component_by_full_name(name)
  sl_checktype(name, "string")
  local c = sl_component.components[name]
  if not c then
    err("unknown component by full name "..name)
  end
  return c
end

