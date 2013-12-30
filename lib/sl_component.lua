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

sl_component = {ids=0}

sl_current_component = nil

function sl_component:new(name, body)
  sl_checktype(name, "string")
  if string.match(name, "%.") then
    err("attempt to create a component \'"..name.."\' whose name includes \".\"")
  end
  if body then
    sl_checktype(body, "function")
  end
  local o = {name=name, typ="component", path=name,
    parent=sl_current_component,
    children={},
    id=sl_component.ids}
  sl_component.ids = sl_component.ids + 1
  if sl_current_component then
    o.path = sl_current_component.path.."."..name
    table.insert(sl_current_component.children, o)
  end
  setmetatable(o, {__index = sl_component})
  if body then
    o:_new(body)
  end
  sl_component[o.path] = o
  return o
end

function sl_component:_new(body)
  local saved_sl_current_component = sl_current_component
  sl_current_component = self
  local _, e = pcall(function()
    body(self)
  end)
  sl_current_component = saved_sl_current_component
  if e then error(e) end
end

function sl_component:notify_phase(name)
  sl_checktype(name, "string")
  for i, v in ipairs(self.children) do
    v:notify_phase(name)
  end
  if self[name] then
    self.name()
  end
end

function component(name, body)
  sl_checktype(name, "string")
  local c = sl_component[name]
  if not c and sl_current_component then
    c = sl_component[sl_current_component.path.."."..name]
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

