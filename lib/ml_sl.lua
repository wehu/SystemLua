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
require "sl_tlm2"
require "sl_scheduler"
require "sl_util"
require "sl_logger"
require "ml_packer"

local call_id = 0
local calls = {}
local callback_id = 0
local callbacks = {}

local requests = {}

--local call_phases = {}
--local call_delays = {}

local function create_connector(p)
  local c = {}
  if p.type == "tlm_blocking_put" and not p.is_export then
    function c:put(data)
      call_id = uvm_sl_ml_assign_transaction_id()
      callback_id = call_id
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      local disable, done = uvm_sl_ml_request_put(p.id, call_id, callback_id, ml_pack(data))
      if not done then
        sl_scheduler:sleep()
      end
    end
    function c:can_put()
      return uvm_sl_ml_can_put(p.id)
    end
  elseif p.type == "tlm_blocking_put" then
  elseif p.type == "tlm_nonblocking_put" and not p.is_export then
    function c:try_put(data)
      return uvm_sl_ml_nb_put(p.id, ml_pack(data))
    end
    function c:can_put()
      return uvm_sl_ml_can_put(p.id)
    end
  elseif p.type == "tlm_nonblocking_put" then
  elseif p.type == "tlm_blocking_get" and not p.is_export then
    function c:get()
      call_id = uvm_sl_ml_assign_transaction_id()
      callback_id = call_id
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      local data, disable, done = uvm_sl_ml_request_get(p.id, call_id, callback_id)
      if done then
        return ml_unpack(data)
      else
        sl_scheduler:sleep()
        return ml_unpack(uvm_sl_ml_get_requested(p.id, call_id, callback_id))
      end
    end
    function c:can_get()
      return uvm_sl_ml_can_get(p.id)
    end
  elseif p.type == "tlm_blocking_get" then
  elseif p.type == "tlm_nonblocking_get" and not p.is_export then
    function c:try_get()
      local data, r = uvm_sl_ml_nb_get(p.id)
      return ml_unpack(data), r
    end
    function c:can_get()
      return uvm_sl_ml_can_get(p.id)
    end
  elseif p.type == "tlm_nonblocking_get" then
  elseif p.type == "tlm_blocking_peek" and not p.is_export then
    function c:peek()
      call_id = uvm_sl_ml_assign_transaction_id()
      callback_id = call_id
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      local data, disable, done = uvm_sl_ml_request_peek(p.id, call_id, callback_id)
      if done then
        return ml_unpack(data)
      else
        sl_scheduler:sleep()
        return ml_unpack(uvm_sl_ml_peek_requested(p.id, call_id, callback_id))
      end
    end
    function c:can_peek()
      return uvm_sl_ml_can_peek(p.id)
    end
  elseif p.type == "tlm_blocking_peek" then
  elseif p.type == "tlm_nonblocking_peek" and not p.is_export then
    function c:try_peek()
      local data, r = uvm_sl_ml_nb_peek(p.id)
      return ml_unpack(data), r
    end
    function c:can_peek()
      return uvm_sl_ml_can_peek(p.id)
    end
  elseif p.type == "tlm_nonblocking_peek" then
  elseif p.type == "tlm_blocking_transport" and not p.is_export then
    function c:transport(data)
      call_id = uvm_sl_ml_assign_transaction_id()
      callback_id = call_id
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      local data, disable, done = uvm_sl_ml_request_transport(p.id, call_id, callback_id, ml_pack(data))
      if done then
        return ml_unpack(data)
      else
        sl_scheduler:sleep()
        return ml_unpack(uvm_sl_ml_transport_response(p.id, call_id, callback_id))
      end
    end
  elseif p.type == "tlm_blocking_transport" then
  elseif p.type == "tlm_nonblocking_transport" and not p.is_export then
    function c:nb_transport(data)
      local ndata, r = uvm_sl_ml_nb_transport(p.id, ml_pack(data))
      return ml_unpack(ndata), r
    end
  elseif p.type == "tlm_analysis" then
    function c:write(data)
      uvm_sl_ml_write(p.id, ml_pack(data))
    end
  elseif p.type == "tlm_nonblocking_transport" then
  elseif p.type == "TLM2" and p.type2 == "tlm2_blocking_transport" and not p.is_target then
    function c:b_transport(trans, delay)
      call_id = uvm_sl_ml_assign_transaction_id()
      callback_id = call_id
      local th = sl_scheduler.current
      sl_checktype(th, "thread")
      local cb = function(call_id, callback_id)
        sl_scheduler:wake(th)
        --callbacks[callback_id] = nil
        calls[call_id] = nil
      end
      calls[call_id] = cb
      --callbacks[callback_id] = cb
      local ntrans, ndelay, disable, done = uvm_sl_ml_tlm2_request_b_transport(p.id, call_id, callback_id, ml_pack(trans), delay.value)
      if done then
        ml_set_packet_type(ntrans, trans)
        ntrans = ml_unpack(ntrans)
        for k, v in pairs(ntrans) do
          trans[k] = v
        end
        delay.value = ndelay
        return trans, delay
      else
        sl_scheduler:sleep()
        local ntrans, ndelay = uvm_sl_ml_tlm2_b_transport_response(p.id, call_id, callback_id)
        ml_set_packet_type(ntrans, trans)
        ntrans = ml_unpack(ntrans)
        for k, v in pairs(ntrans) do
          trans[k] = v
        end
        delay.value = ndelay
      end
    end
  elseif p.type == "TLM2" and p.type2 == "tlm2_blocking_transport" then
  elseif p.type == "TLM2" and p.type2 == "tlm2_nonblocking_transport" and not p.is_target then
    function c:nb_transport_fw(trans, phase, delay)
      local trans_id = uvm_sl_ml_assign_transaction_id()
      --call_phases[trans.id] = phase
      --call_delays[trans.id] = delay
      local ntrans, nphase, ndelay, res = uvm_sl_ml_tlm2_nb_transport_fw(p.id, trans_id, ml_pack(trans), phase.value, delay.value)
      ml_set_packet_type(ntrans, trans)
      ntrans = ml_unpack(ntrans)
      for k, v in pairs(ntrans) do
        trans[k] = v
      end
      phase.value = nphase
      delay.value = ndelay
      return res
    end
  elseif p.type == "TLM2" and p.type2 == "tlm2_nonblocking_transport" and p.is_target then
    function c:nb_transport_bw(trans, phase, delay)
      local trans_id = uvm_sl_ml_assign_transaction_id()
      --call_phases[trans.id] = phase
      --call_delays[trans.id] = delay
      local ntrans, nphase, ndelay, res = uvm_sl_ml_tlm2_nb_transport_bw(p.id, trans_id, ml_pack(trans), phase.value, delay.value)
      ml_set_packet_type(ntrans, trans)
      ntrans = ml_unpack(ntrans)
      for k, v in pairs(ntrans) do
        trans[k] = v
      end
      phase.value = nphase
      delay.value = ndelay
      return res
    end
  elseif p.type == "TLM2" and p.type2 == "tlm2_transport_dbg" and not p.is_target then
    function c:transport_dbg(trans)
      return uvm_sl_ml_tlm2_transport_dbg(p.id, ml_pack(trans))
    end
  else
    err("unsupported connector type "..p.type)
  end
  return c
end

function ml_register_port(path)
  sl_checktype(path, "string")
  local p = sl_port.ports[path]
  if p then
    p.peer = create_connector(p)
  end
end

function ml_connect(path1, path2)
  sl_checktype(path1, "string")
  sl_checktype(path2, "string")
  local p1 = sl_port.ports[path1]
  local p2 = sl_port.ports[path2]
  --if p1 and p2 then
  --  return p1:connect(p2)
  --end
  if p1 then
    p1.peer = create_connector(p1)
  end
  if p2 then
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

function uvm_sl_ml_can_put_callback(id)
  local p = find_port_by_id(id)
  return p:can_put()
end

function uvm_sl_ml_nb_put_callback(id, packet)
  local p = find_port_by_id(id)
  return p:try_put(ml_unpack(packet))
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

function uvm_sl_ml_can_get_callback(id)
  local p = find_port_by_id(id)
  return p:can_get()
end

function uvm_sl_ml_nb_get_callback(id)
  local p = find_port_by_id(id)
  local data, r = p:try_get()
  return ml_pack(data), (r ~= false)
end

function uvm_sl_ml_request_peek_callback(id, call_id, callback_id)
  local p = find_port_by_id(id)
  fork(function()
    requests[call_id] = p:peek()
    uvm_sl_ml_notify_end_blocking(call_id, callback_id)
  end)
end

function uvm_sl_ml_peek_requested_callback(id, call_id, callback_id)
  --local p = find_port_by_id(id)
  local data = requests[call_id]
  requests[call_id] = nil
  return ml_pack(data)
end

function uvm_sl_ml_can_peek_callback(id)
  local p = find_port_by_id(id)
  return p:can_peek()
end

function uvm_sl_ml_nb_peek_callback(id)
  local p = find_port_by_id(id)
  local data, r = p:try_peek()
  return ml_pack(data), (r ~= false)
end

function uvm_sl_ml_request_transport_callback(id, call_id, callback_id, packet)
  local p = find_port_by_id(id)
  fork(function()
    requests[call_id] = p:transport(ml_unpack(packet))
    uvm_sl_ml_notify_end_blocking(call_id, callback_id)
  end)
end

function uvm_sl_ml_transport_response_callback(id, call_id, callback_id)
  --local p = find_port_by_id(id)
  local data = requests[call_id]
  requests[call_id] = nil
  return ml_pack(data)
end

function uvm_sl_ml_nb_transport_callback(id, packet)
  local p = find_port_by_id(id)
  local data, r = p:nb_transport(ml_unpack(packet))
  return ml_pack(data), (r ~= false)
end

function uvm_sl_ml_write_callback(id, packet)
  local p = find_port_by_id(id)
  p:write(ml_unpack(packet))
end

function uvm_sl_ml_tlm2_request_b_transport_callback(id, call_id, callback_id, packet, delay)
  local p = find_port_by_id(id)
  fork(function()
    local trans = ml_unpack(packet)
    delay = time(delay)
    p:b_transport(trans, delay)
    requests[call_id] = {trans, delay}
    uvm_sl_ml_notify_end_blocking(call_id, callback_id)
  end)
end

function uvm_sl_ml_tlm2_b_transport_response_callback(id, call_id, callback_id)
  --local p = find_port_by_id(id)
  local rsp = requests[call_id]
  requests[call_id] = nil
  return ml_pack(rsp[1]), rsp[2].value
end

function uvm_sl_ml_tlm2_nb_transport_fw_callback(id, trans_id, trans_packet, _phase, delay)
  local p = find_port_by_id(id)
  local trans = nil
  --if sl_transaction_by_id[trans_id] then
  --  trans = sl_transaction_by_id[trans_id]
  --  for k, v in pairs(ml_unpack(trans_packet)) do
  --    trans[k] = v
  --  end
  --else
    trans = ml_unpack(trans_packet)
  --end
  _phase = phase(_phase)
  delay = time(delay)
  local res = p:nb_transport_fw(trans, _phase, delay)
  return ml_pack(trans), _phase.value, delay.value, res
end

function uvm_sl_ml_tlm2_nb_transport_bw_callback(id, trans_id, trans_packet, _phase, delay)
  local p = find_port_by_id(id)
  local trans = nil
  --if sl_transaction_by_id[trans_id] then
  --  trans = sl_transaction_by_id[trans_id]
  --  for k, v in pairs(ml_unpack(trans_packet)) do
  --    trans[k] = v
  --  end
  --else
    trans = ml_unpack(trans_packet)
  --end
  _phase = phase(_phase)
  delay = time(delay)
  local res = p:nb_transport_bw(trans, _phase, delay)
  return ml_pack(trans), _phase.value, delay.value, res
end

function uvm_sl_ml_tlm2_transport_dbg_callback(id, packet)
  local p = find_port_by_id(id)
  return p:transport_dbg(ml_unpack(packet))
end

function ml_set_trace_mode(mode)
  if not mode then
    mode = 1
  end
  sl_checktype(mode, "number")
  uvm_sl_ml_set_trace_mode(mode)
end

function ml_set_match_types(type1, type2)
  sl_checktype(type1, "string")
  sl_checktype(type2, "string")
  local res = uvm_sl_ml_set_match_types(type1, type2)
  if res == 0 then
    err("ml_set_match_types: "..type1.." and "..type2.." failed")
  end
end

ml_set_match_types("SL:uvm_tlm_generic_payload", "SC:tlm_generic_payload")
ml_set_match_types("SL:uvm_tlm_generic_payload", "SV:uvm_tlm_generic_payload")
