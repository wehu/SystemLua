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

sl_simtime = {timeline=0, simtimes={}, size=0, stopped=true}
setmetatable(sl_simtime.simtimes, {__mode = "k"})

function pairs_by_keys (t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0      -- iterator variable
  local iter = function ()   -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function sl_simtime:st(t)
  local ts = self.simtimes[t]
  if not ts then
    self.simtimes[t] = {}
    setmetatable(self.simtimes[t], {__mode = "k"})
    ts = self.simtimes[t]
  end
  return ts
end

function sl_simtime:new(delay)
  sl_checktype(delay, "number")
  local o = {callbacks={}, typ="simtime"}
  self.size = self.size + 1
  setmetatable(o.callbacks, {__mode = "k"})
  setmetatable(o, {__index = self})
  t = self.timeline + delay
  self:st(t)[o] = o
  return o
end

function sl_simtime:register(callback)
  sl_checktype(callback, "function")
  self.callbacks[callback] = callback
  return callback
end

function sl_simtime:unregister(callback)
  sl_checktype(callback, "function")
  self.callbacks[callback] = nil
end

function sl_simtime:notify(...)
  for cb in pairs(self.callbacks) do
    cb(unpack(arg))
  end
end

function sl_simtime:run(delta, max)
  self.stopped = false
  local ct = sl_simtime.timeline
  if delta then
    sl_checktype(delta, "number")
  end
  if max then
    sl_checktype(max, "number")
  end
  if not max then
    max = delta
  end
  for t, ts in pairs_by_keys(self.simtimes) do
    if self.stopped then
      return
    end
    if not delay or t <= ct + delay then
      sl_simtime.timeline = t
      if not max or t <= ct + max then
        for st in pairs(ts) do
          if self.stopped then
            return
          end
          st:notify()
          self.size = self.size - 1
        end
        self.simtimes[t] = nil
      end
      if not delta then
        break
      end
    else
      break
    end
  end
  if delay then
    sl_simtime.timeline = ct + delay
  end
end

function sl_simtime:stop()
  self.stopped = true
end

function simtime(delay, callback)
  sl_checktype(delay, "number")
  local st = sl_simtime:new(delay)
  if callback then
    sl_checktype(callback, "function")
    st:register(callback)
  end
  return st
end

