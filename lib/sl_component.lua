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

require "sl_object"
require "sl_logger"
require "sl_util"

sl_component = sl_object:new()

sl_current_component_heir_path = ""

function sl_component:new(name, body)
  sl_checktype(name, "string")
  if string.match(name, "%.") then
    err("attempt to create a component \'"..name.."\' whose name includes \".\"")
  end
  if body then
    sl_checktype(body, "function")
  end
  local o = sl_object:new()
  setmetatable(o, {__index = sl_component})
  o.name = name
  o.path = sl_current_component_heir_path..name
  if body then
    o:_new(body)
  end
  sl_component[o.path] = o
  return o
end

function sl_component:_new(body)
  local saved_sl_current_component_heir_path = sl_current_component_heir_path
  sl_current_component_heir_path = self.path.."."
  local _, e = pcall(body)
  sl_current_component_heir_path = saved_sl_current_component_heir_path
  if e then error(e) end
end

function component(name, body)
  sl_checktype(name, "string")
  local c = sl_component[name]
  if not c then
    c = sl_component[sl_current_component_heir_path..name]
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

