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

require "sl_port"
require "sl_tlm1"
require "sl_scheduler"
require "sl_util"
require "sl_logger"
require "ml_packer"

local call_id = 0
local calls = {}
local callback_id = 0
local callbacks = {}

local requests = {}

local function create_connector(p)
  local c = {}
  if p.typ == "tlm_blocking_put" then
    function c:put(data)
      call_id = call_id + 1
      callback_id = callback_id + 1
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      uvm_sl_ml_request_put(p.id, call_id, callback_id, ml_pack(data))
      sl_scheduler:sleep()
    end
  elseif p.typ == "tlm_blocking_get" then
    function c:get(typ)
      sl_checktype(typ, "string")
      call_id = call_id + 1
      callback_id = callback_id + 1
      local size = ml_packet_size(typ)
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      uvm_sl_ml_request_get(p.id, call_id, callback_id)
      sl_scheduler:sleep()
      return ml_unpack(uvm_sl_ml_get_requested(p.id, call_id, callback_id, size))
    end
  else
    err("unsupported connector type "..p.typ)
  end
  return c
end

function ml_connect(path1, path2)
  local p1 = sl_port.ports[path1]
  local p2 = sl_port.ports[path2]
  --if p1 and p2 then
  --  return p1:connect(p2)
  --end
  if p1 and not p1.is_export then
    p1.peer = create_connector(p1)
  --elseif not p1 and p2 then
  end
  if p2 and not p2.is_export then
    p2.peer = create_connector(p2)
  end
  return uvm_sl_ml_connect(path1, path2) 
end

function uvm_sl_ml_notify_end_blocking_callback(call_id, callback_id)
  --callbacks[callback_id](call_id, callback_id)
  if not calls[call_id] then
    err("unknown callback id "..call_id)
  end
  calls[call_id](call_id, callback_id)
end

function uvm_sl_ml_request_put_callback(id, call_id, callback_id, packet)
  local p = find_port_by_id(id)
  fork(function()
    p:put(ml_unpack(packet))
    uvm_sl_ml_notify_end_blocking(call_id, callback_id)
  end)
end

function uvm_sl_ml_request_get_callback(id, call_id, callback_id)
  local p = find_port_by_id(id)
  fork(function()
    requests[call_id] = p:get()
    uvm_sl_ml_notify_end_blocking(call_id, callback_id)
  end)
end

function uvm_sl_ml_get_requested_callback(id, call_id, callback_id)
  --local p = find_port_by_id(id)
  local data = requests[call_id]
  requests[call_id] = nil
  return ml_pack(data)
end


