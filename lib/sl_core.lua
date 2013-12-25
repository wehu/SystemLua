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

require "sl_simtime"
require "sl_scheduler"
require "sl_event"
require "sl_signal"
require "sl_pipe"
require "sl_simulator"
require "sl_logger"

function wait(e)
  local th = sl_scheduler.current
  if type(e) == "number" then
    e = simtime(e)
  end
  local cb = nil
  cb = e:register(function()
    sl_scheduler:wake(th)
    e:unregister(cb) 
  end)
  sl_scheduler:sleep()
end

function always(e, body)
  if not body then
    body, e = e, nil
  end
  return sl_scheduler:thread(function()
    while true do
      if e then
        wait(e)
      end
      body()
    end
  end)
end

function initial(body)
  return sl_scheduler:thread(function()
    wait(0)
    body()
  end)
end

function run(body, delay)
  sl_simulator:run(body, delay)
end

function stop()
  sl_simulator:stop()
end

