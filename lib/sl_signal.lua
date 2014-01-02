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

require "sl_component"
require "sl_util"
require "sl_event"

sl_signal = {ids=0, signals={}}
--setmetatable(sl_signal.signals, {__mode = "k"})

local sl_binding_signals = {}

function sl_signal:new(name, data)
  if name then
    sl_checktype(name, "string")
  end
  if string.match(name, "%.") then
    err("attempt to create a signal \'"..name.."\' whose name includes \".\"")
  end
  if not data then
    data = 0
  end
  local o = {posedge=event(),
       negedge=event(),
       anyedge=event(),
       new_data=data,
       old_data=data,
       name=name,
       parent=sl_current_component,
       id=sl_signal.ids,
       type="signal"}
  sl_signal.ids = sl_signal.ids + 1
  if name then
    if sl_current_component then
      o.path = sl_current_component.path.."."..name
    else
      o.path = name
    end
  end
  setmetatable(o, {__index = self})
  if name then
    self.signals[o.path] = o
  end
  return o
end

function sl_signal:write(data, nosync)
  self.new_data = data
  if nosync then
    sl_checktype(nosync, "boolean")
  end
  if data ~= self.old_data then
    self.anyedge:notify(data)
  end
  if data > self.old_data then
    self.posedge:notify(data)
  end
  if data < self.old_data then
    self.negedge:notify(data)
  end
  if self.old_data ~= data and sl_binding_signals[self.name] and not nosync then
    sim_write_signal(sl_binding_signals[self.name], data)
  end 
  self.old_data = data
end

function sl_signal:read()
  return self.old_data
end

function signal(name, data)
  if name then
    sl_checktype(name, "string")
  end
  local s = nil
  if name and sl_current_component then
    s = sl_signal.signals[sl_current_component.path.."."..name]
  end
  if name and not s then
    s = sl_signal.signals[name]
  end
  if not s then
    s = sl_signal:new(name, data)
  end
  return s
end

local sl_binding_paths = {}

function bind_signal(name, path)
  sl_checktype(name, "string")
  sl_checktype(path, "string")
  sl_binding_signals[name] = path
  if not sl_binding_paths[path] then
    sl_binding_paths[path] = true
    sim_bind_signal(path)
  end
end

function unbind_signal(name)
  sl_checktype(name, "string")
  sl_binding_signals[name] = nil
end

function sync_signals()
  for k, v in pairs(sl_binding_signals) do
    signal(k):write(sim_read_signal(v), true)
  end
end
