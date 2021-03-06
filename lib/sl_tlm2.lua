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
require "sl_util"
require "ml_packer"

sl_transaction = {ids=0}

--sl_transaction_by_id = {}

function sl_transaction:new()
  local o = {type="transaction", id=sl_transaction.ids}
  sl_transaction.ids = sl_transaction.ids + 1
  setmetatable(o, {__index = sl_transaction})
  --sl_transaction_by_id[o.id] = o
  return o
end

--function find_transaction_by_id(id)
--  sl_checktype(id, "number")
--  if not sl_transaction_by_id[id] then
--    err("cannot find transaction by id "..id)
--  end
--  return sl_transaction_by_id[id]
--end

function transaction()
  return sl_transaction:new()
end

sl_time = {}

function sl_time:new(t)
  if not t then
    t = 0
  end
  sl_checktype(t, "number")
  local o = {type="time", value=t}
  setmetatable(o, {__index = sl_time})
  return o
end

function time(t)
  return sl_time:new(t)
end

sl_phase = {}

UNINITIALIZED_PHASE = 0
BEGIN_REQ = 1
END_REQ = 2
BEGIN_RESP = 3
END_RESP = 4

function sl_phase:new(p)
  sl_checktype(p, "number")
  local o = {type="phase", value=p}
  setmetatable(o, {__index = sl_phase})
  return o
end

function phase(p)
  return sl_phase:new(p)
end

function initiator_b_transport(name)
  local p = port(name, "TLM2")
  p.type2 = "tlm2_blocking_transport"
  function p:b_transport(trans, delay)
    --sl_checktype(trans, "transaction")
    --sl_checktype(delay, "time")
    self:check_peer()
    if not self.peer.b_transport then
      err("cannot find \'b_transport\' function in peer")
    end
    return self.peer:b_transport(trans, delay)
  end
  function p:connect(ap)
    self:check_connection_type(ap, "TLM2")
    self.peer = ap
    ap.peer = self
  end
  return p 
end

function target_b_transport(name, imp)
  local p = port(name, "TLM2")
  p.type2 = "tlm2_blocking_transport"
  p.is_target = true
  function p:b_transport(trans, delay)
    --sl_checktype(trans, "transaction")
    --sl_checktype(delay, "time")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans, delay)
    end 
  end
  function p:connect(ap)
    self:check_connection_type(ap, "TLM2")
    ap.peer = self
    self.peer = ap
  end
  return p
end

TLM_ACCEPTED = 0
TLM_UPDATED = 1
TLM_COMPLETED = 2

function initiator_nb_transport(name, imp)
  local p = port(name, "TLM2")
  p.type2 = "tlm2_nonblocking_transport"
  function p:nb_transport_fw(trans, phase, delay)
    --sl_checktype(trans, "transaction")
    --sl_checktype(phase, "phase")
    --sl_checktype(delay, "time")
    self:check_peer()
    if not self.peer.nb_transport_fw then
      err("cannot find \'nb_transport_fw\' function in peer")
    end
    return self.peer:nb_transport_fw(trans, phase, delay)
  end
  function p:nb_transport_bw(trans, phase, delay)
    --sl_checktype(trans, "transaction")
    --sl_checktype(phase, "phase")
    --sl_checktype(delay, "time")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans, phase, delay)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "TLM2")
    self.peer = ap
    ap.peer = self
  end
  return p
end

function target_nb_transport(name, imp)
  local p = port(name, "TLM2")
  p.type2 = "tlm2_nonblocking_transport"
  p.is_target = true
  function p:nb_transport_bw(trans, phase, delay)
    --sl_checktype(trans, "transaction")
    --sl_checktype(phase, "phase")
    --sl_checktype(delay, "time")
    self:check_peer()
    if not self.peer.nb_transport_bw then
      err("cannot find \'nb_transport_bw\' function in peer")
    end
    return self.peer:nb_transport_bw(trans, phase, delay)
  end
  function p:nb_transport_fw(trans, phase, delay)
    --sl_checktype(trans, "transaction")
    --sl_checktype(phase, "phase")
    --sl_checktype(delay, "time")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans, phase, delay)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "TLM2")
    self.peer = ap
    ap.peer = self
  end
  return p
end

function initiator_transport_dbg(name)
  local p = port(name, "TLM2")
  p.type2 = "tlm2_transport_dbg"
  function p:transport_dbg(trans)
    --sl_checktype(trans, "transaction")
    self:check_peer()
    if not self.peer.transport_dbg then
      err("cannot find \'transport_dbg\' function in peer")
    end
    return self.peer:transport_dbg(trans)
  end
  function p:connect(ap)
    self:check_connection_type(ap, "TLM2")
    self.peer = ap
    ap.peer = self
  end
  return p
end

function target_transport_dbg(name, imp)
  local p = port(name, "TLM2")
  p.type2 = "tlm2_transport_dbg"
  p.is_target = true
  function p:transport_dbg(trans)
    --sl_checktype(trans, "transaction")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "TLM2")
    ap.peer = self
    self.peer = ap
  end
  return p
end

TLM_READ_COMMAND = 0
TLM_WRITE_COMMAND = 1
TLM_IGNORE_COMMAND = 2

TLM_OK_RESPONSE = 1
TLM_INCOMPLETE_RESPONSE = 0
TLM_GENERIC_ERROR_RESPONSE = -1
TLM_ADDRESS_ERROR_RESPONSE = -2
TLM_COMMAND_ERROR_RESPONSE = -3
TLM_BURST_ERROR_RESPONSE = -4
TLM_BYTE_ENABLE_ERROR_RESPONSE = -5

function generic_payload()
  local gp = transaction()
  gp.type = "uvm_tlm_generic_payload"
  gp.address = 0
  gp.command = TLM_IGNORE_COMMAND
  gp.data = {}
  --gp.length = 0
  gp.response_status = TLM_INCOMPLETE_RESPONSE
  gp.dmi = 0
  gp.byte_enable = {}
  --gp.byte_enable_length = 0
  gp.streaming_width = 0
  gp.extensions = {}
  return gp
end

function print_gp(gp)
  print("type: "..gp.type)
  print("address: "..gp.address)
  if gp.command == 0 then
    print("command: TLM_READ_COMMAND")
  elseif gp.command == 1 then
    print("command: TLM_WRITE_COMMAND")
  elseif gp.command == 2 then
    print("command: TLM_IGNORE_COMMAND")
  else
    print("command: "..gp.command)
  end
  print("data: ")
  for i, v in ipairs(gp.data) do
    print("  "..v)
  end
  print("length: "..table.getn(gp.data))
  if gp.response_status == 1 then
    print("response_status: TLM_OK_RESPONSE")
  elseif gp.response_status == 0 then
    print("response_status: TLM_INCOMPLETE_RESPONSE")
  elseif gp.response_status == -1 then
    print("response_status: TLM_GENERIC_ERROR_RESPONSE")
  elseif gp.response_status == -2 then
    print("response_status: TLM_ADDRESS_ERROR_RESPONSE")
  elseif gp.response_status == -3 then
    print("response_status: TLM_COMMAND_ERROR_RESPONSE")
  elseif gp.response_status == -4 then
    print("response_status: TLM_BURST_ERROR_RESPONSE")
  elseif gp.response_status == -5 then
    print("response_status: TLM_BYTE_ENABLE_ERROR_RESPONSE")
  else
    print("response_status: "..gp.response_status)
  end
  print("dmi: "..gp.dmi)
  print("byte_enable: ")
  for i, v in ipairs(gp.byte_enable) do
    print("  "..v)
  end
  print("byte_enable_length: "..table.getn(gp.byte_enable))
  print("streaming_width: "..gp.streaming_width)
  print("extension size: "..table.getn(gp.extensions))
end

ml_register_packer("uvm_tlm_generic_payload", function(gp, packet)
  -- little endian
  ml_pack_int(gp.address, packet, 64)
  ml_pack_int(gp.command, packet)
  local l = table.getn(gp.data)
  ml_pack_int(l, packet)
  for i, v in ipairs(gp.data) do
    ml_pack_int(v, packet)
  end
  --ml_pack_int(gp.length, packet)
  ml_pack_int(l, packet)
  ml_pack_int(gp.response_status, packet)
  ml_pack_int(0, packet)
  l = table.getn(gp.byte_enable)
  ml_pack_int(l, packet)
  for i, v in ipairs(gp.byte_enable) do
    ml_pack_int(v, packet)
  end
  --ml_pack_int(gp.byte_enable_length, packet)
  ml_pack_int(l, packet)
  ml_pack_int(gp.streaming_width, packet)
  ml_pack_int(table.getn(gp.extensions), packet)
  for i, v in ipairs(gp.extensions) do
    ml_pack(v, packet, true)
  end
  return packet
end)

ml_register_unpacker("uvm_tlm_generic_payload", function(packet)
  local gp = generic_payload()
  gp.address = ml_unpack_int(packet, 64)
  gp.command = ml_unpack_int(packet)
  local l = ml_unpack_int(packet)
  for i = 1, l do
    local d = ml_unpack_int(packet)
    table.insert(gp.data, d)
  end
  --gp.length =
  ml_unpack_int(packet)
  gp.response_status = ml_unpack_int(packet)
  ml_unpack_int(packet)
  l = ml_unpack_int(packet)
  for i = 1, l do
    local d = ml_unpack_int(packet)
    table.insert(gp.byte_enable, d)
  end
  --gp.byte_enable_length =
  ml_unpack_int(packet)
  gp.streaming_width = ml_unpack_int(packet)
  el = ml_unpack_int(packet)
  for i = 1,el do
    table.insert(gp.extensions, ml_unpack(packet, true))
  end
  return gp
end)

