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

require "sl_util"

sl_event = {}

function sl_event:new(name)
  if name then
    sl_checkarg(name, "string")
  end
  local o = {callbacks={}, name=name}
  setmetatable(o.callbacks, {__mode = "k"})
  setmetatable(o, {__index = self})
  if name then
    self[name] = o
  end
  return o
end

function sl_event:register(callback)
  sl_checkarg(callback, "function")
  self.callbacks[callback] = callback
  return callback
end

function sl_event:unregister(callback)
  sl_checkarg(callback, "function")
  self.callbacks[callback] = nil
end

function sl_event:notify(...)
  for cb in pairs(self.callbacks) do
    cb(unpack(arg))
  end
end

function event(name)
  if name then
    sl_checkarg(name, "string")
  end
  local e = sl_event[name]
  if not e then
    e = sl_event:new(name)
  end
  return e
end

require "sl_simtime"

function event_or(...)
  local e = sl_event:new()
  local counter = 0
  local ct = sl_simtime.timeline
  for i,v in ipairs(arg) do
    v:register(function(...)
      if ct ~= sl_simtime.timeline then
        counter = 0
      end
      ct = sl_simtime.timeline
      counter = counter + 1
      if counter == 1 then
        e:notify(unpack(arg))
      end
    end)
  end
  return e
end

function event_and(...)
  local e = sl_event:new()
  local max = 0
  local counter = 0
  local ct = sl_simtime.timeline
  for i,v in ipairs(arg) do
    max = max + 1
    v:register(function(...)
      if ct ~= sl_simtime.timeline then
        counter = 0
      end
      ct = sl_simtime.timeline
      counter = counter + 1
      if counter == max then
        counter = 0
        e:notify(unpack(arg))
      end
    end)
  end
  return e
end

