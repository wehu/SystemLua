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

sl_scheduler = {running_q_size = 0, running_q={}, sleeping_q={}, stopped=true}
setmetatable(sl_scheduler.running_q, {__mode = "k"})
setmetatable(sl_scheduler.sleeping_q, {__mode = "k"})

function sl_scheduler:thread(body)
  sl_checktype(body, "function")
  local th = coroutine.create(body)
  self.running_q[th] = th
  self.running_q_size = self.running_q_size + 1
  return th
end

function sl_scheduler:sleep()
  local th = self.current
  sl_checktype(th, "thread")
  self.sleeping_q[th] = th
  if self.running_q[th] then
    self.running_q[th] = nil
    self.running_q_size = self.running_q_size - 1
  end
  coroutine.yield()
end

function sl_scheduler:wake(th)
  sl_checktype(th, "thread")
  self.running_q[th] = th
  self.running_q_size = self.running_q_size + 1
  self.sleeping_q[th] = nil
end

function sl_scheduler:run()
  self.stopped = false
  while self.running_q_size > 0 and not self.stopped do
    for th in pairs(self.running_q) do
      if self.stopped then
        break
      end
      self.current = th
      local _, e = coroutine.resume(th)
      if e then
        err(e)
      end
      if coroutine.status(th) == "dead" then
        if self.running_q[th] then
          self.running_q[th] = nil
          self.running_q_size = self.running_q_size - 1
        end
        if self.sleeping_q[th] then
          self.sleeping_q[th] = nil
        end
      end
    end
  end
end

function sl_scheduler:stop()
  self.stopped = true
end
