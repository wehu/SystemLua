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

sl_pipe = {ids=0}

function sl_pipe:new(name)
  if name then
    sl_checktype(name, "string")
  end
  if string.match(name, "%.") then
    err("attempt to create a signal \'"..name.."\' whose name includes \".\"")
  end
  local o = {event_rd=event(),
       event_wr=event(),
       event_pk=event(),
       queue={},
       id=sl_pipe.ids,
       parent=sl_current_component,
       name=name,
       typ="pipe"}
  sl_pipe.ids = sl_pipe.ids + 1
  if name then
    if sl_current_component then
      o.path = sl_current_component.path.."."..name
    else
      o.path = name
    end
  end
  setmetatable(o, {__index = self})
  if name then
    self[o.path] = o
  end
  return o
end

function sl_pipe:write(data)
  table.insert(self.queue, data)
  self.event_wr:notify(data)
end

function sl_pipe:read()
  local data = self.queue[1]
  table.remove(self.queue, 1)
  self.event_rd:notify(data)
  return data
end

function sl_pipe:peek()
  local data = self.queue[1]
  self.event_pk:notify(data)
  return data
end

function sl_pipe:is_empty()
  return (table.getn(self.queue) == 0)
end

function sl_pipe:size()
  return table.getn(self.queue)
end

function pipe(name)
  if name then
    sl_checktype(name, "string")
  end
  local p = nil
  if name and sl_current_component then
    p = sl_pipe[sl_current_component.path.."."..name]
  end
  if name and not p then
    p = sl_pipe[name]
  end
  if not p then
    p = sl_pipe:new(name)
  end
  return p
end


