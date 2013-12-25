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

sl_pipe = {}

function sl_pipe:new(name)
  if name then
    sl_checkarg(name, "string")
  end
  local o = {event_rd=event(),
       event_wr=event(),
       event_pk=event(),
       queue={},
       name=name}
  setmetatable(o, {__index = self})
  if name then
    self[name] = o
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
    sl_checkarg(name, "string")
  end
  local p = sl_pipe[name]
  if not p then
    p = sl_pipe:new(name)
  end
  return p
end


