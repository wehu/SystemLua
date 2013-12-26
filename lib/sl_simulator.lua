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
require "sl_event"
require "sl_simtime"
require "sl_scheduler"

sl_simulator = {stopped=true}

function sl_simulator:run(body, delay)
  self.stopped = false
  if body then
     sl_checktype(body, "function")
     body()
  end
  if delay then
    sl_checktype(delay, "number")
  end
  local deadline = (delay and sl_simtime.timeline + delay) or sl_simtime.timeline
  repeat
    if self.stopped then
      return
    end
    sl_simtime:run(nil, delay)
    if not delay or sl_simtime.timeline <= deadline then
      sl_scheduler:run()
    end
  until sl_simtime.size == 0 or (delay and sl_simtime.timeline >= deadline)
  if delay then
    sl_simtime.timeline = deadline
  end
end

function sl_simulator:stop()
  self.stopped = true
  sl_simtime:stop()
  sl_scheduler:stop()
end
