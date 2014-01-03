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

local sl_path = string.gsub(debug.getinfo(1).source, "^@(.+\/)[^\/]+$", "%1").."?.lua"

if package.path then
  package.path = package.path..";"..sl_path
else
  package.path = sl_path
end

require "sl_simtime"
require "sl_scheduler"
require "sl_event"
require "sl_signal"
require "sl_pipe"
require "sl_simulator"
require "sl_logger"
require "sl_util"

require "sl_component"
require "sl_port"
require "sl_tlm1"

require "ml_sl"

function wait(e)
  if type(e) ~= "number" then
    sl_checktype(e, "event")
  end
  local th = sl_scheduler.current
  sl_checktype(th, "thread")
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
  if e and type(e) ~= "number" then
    sl_checktype(e, "event")
  end
  sl_checktype(body, "function")
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
  sl_checktype(body, "function")
  return sl_scheduler:thread(function()
    wait(0)
    body()
  end)
end

function fork(body)
  sl_checktype(body, "function")
  return initial(body)
end

function fork_join_all(...)
  local th = sl_scheduler.current
  sl_checktype(th, "thread")
  local e = event()
  local n = table.getn(arg)
  e:register(function ()
    n = n - 1
    if n == 0 then
      sl_scheduler:wake(th)
    end
  end)
  for i, v in ipairs(arg) do
    sl_checktype(v, "function")
    fork(function (...)
      v(unpack(arg))
      e:notify()
    end)
  end
  if n > 0 then
    sl_scheduler:sleep()
  end
end

function fork_join_any(...)
  local th = sl_scheduler.current
  sl_checktype(th, "thread")
  local e = event()
  local n = 1
  e:register(function ()
    n = n - 1
    if n == 0 then
      sl_scheduler:wake(th)
    end
  end)
  for i, v in ipairs(arg) do
    sl_checktype(v, "function")
    fork(function (...)
      v(unpack(arg))
      e:notify()
    end)
  end
  if n > 0 then
    sl_scheduler:sleep()
  end
end

function run(body, delay)
  if body then
    sl_checktype(body, "function")
  end
  if delay then
    sl_checktype(delay, "number")
  end
  sl_simulator:run(body, delay)
end

function stop()
  sl_simulator:stop()
end

