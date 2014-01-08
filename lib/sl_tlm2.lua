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
  gp.command = UVM_TLM_IGNORE_COMMAND
  gp.data = {}
  gp.length = 0
  gp.response_status = TLM_INCOMPLETE_RESPONSE
  gp.dmi = 0
  gp.byte_enable = {}
  gp.byte_enable_length = 0
  gp.streaming_width = 0
  gp.extensions = {}
  return gp
end

function print_gp(gp)
  print("type: "..gp.type)
  print("address: "..gp.address)
  print("command: "..gp.command)
  print("data: ")
  for i, v in ipairs(gp.data) do
    print("  "..v)
  end
  print("length: "..gp.length)
  print("response_status: "..gp.response_status)
  print("dmi: "..gp.dmi)
  print("byte_enable: ")
  for i, v in ipairs(gp.byte_enable) do
    print("  "..v)
  end
  print("byte_enable_length: "..gp.byte_enable_length)
  print("streaming_width: "..gp.streaming_width)
  print("extension size: "..table.getn(gp.extensions))
end

local b8 = 2^8
local b16 = 2^16
local b24 = 2^24
local b32 = 2^32

local function pack_int(data, packet, size)
  if size == 64 then
    table.insert(packet, data%b32)
    table.insert(packet, math.floor(data/b32))
  else
    table.insert(packet, data)
  end
  return packet
end

local function unpack_int(packet, size)
  local data = 0
  if size == 64 then
    data = packet[1] + packet[2] * b32
    table.remove(packet, 1)
    table.remove(packet, 1)
  else
    data = packet[1]
    table.remove(packet, 1)
  end
  return data
end

ml_register_packer("uvm_tlm_generic_payload", function(packet, gp)
  -- little endian
  pack_int(gp.address, packet, 64)
  pack_int(gp.command, packet)
  local dl = table.getn(gp.data)
  pack_int(dl, packet)
  --local d = 0
  for i, v in ipairs(gp.data) do
  --  d = d * b8 + v
  --  if i % 4 == 0 then
  --    pack_int(d, packet)
    pack_int(v, packet)
  --    d = 0
  --  end
  end
  --if dl % 4 ~= 0 then
  --  pack_int(d, packet)
  --end
  pack_int(gp.length, packet)
  pack_int(gp.response_status, packet)
  pack_int(0, packet)
  dl = table.getn(gp.byte_enable)
  pack_int(dl, packet)
  --d = 0
  for i, v in ipairs(gp.byte_enable) do
    --d = d * b8 + v
    --if i % 4 == 0 then
    --  pack_int(d, packet)
    pack_int(v, packet)
    --  d = 0
    --end
  end
  --if dl % 4 ~= 0 then
  --  pack_int(d, packet)
  --end
  pack_int(gp.byte_enable_length, packet)
  pack_int(gp.streaming_width, packet)
  pack_int(table.getn(gp.extensions), packet)
  for i, v in ipairs(gp.extensions) do
    ml_pack(v, packet)
  end
  return packet
end)

ml_register_unpacker("uvm_tlm_generic_payload", function(packet)
  local gp = generic_payload()
  -- copy pakcet first???
  if packet[1] == 0 then
    return nil
  end
  table.remove(packet, 1)
  table.remove(packet, 1)
  gp.address = unpack_int(packet, 64)
  gp.command = unpack_int(packet)
  local dl = unpack_int(packet)
  for i = 1, dl do
    local d = unpack_int(packet)
    table.insert(gp.data, d) --d%b8)
    --if dl - i == 3 then
    --  table.insert(gp.data, math.floor((d%b16)/b8))
    --end
    --if dl - i == 2 then
    --  table.insert(gp.data, math.floor((d%b24)/b16))
    --end
    --if dl - i == 1 then
    --  table.insert(gp.data, math.floor(d/b24))
    --end
  end
  gp.length = unpack_int(packet)
  gp.response_status = unpack_int(packet)
  unpack_int(packet)
  local el = unpack_int(packet)
  for i = 1, el do
    local d = unpack_int(packet)
    table.insert(gp.byte_enable, d) --d%b8)
    --if el - i == 3 then
    --  table.insert(gp.byte_enable, math.floor((d%b16)/b8))
    --end
    --if el - i == 2 then
    --  table.insert(gp.byte_enable, math.floor((d%b24)/b16))
    --end
    --if el - i == 1 then
    --  table.insert(gp.byte_enable, math.floor(d/b24))
    --end
  end
  gp.byte_enable_length = unpack_int(packet)
  gp.streaming_width = unpack_int(packet)
  el = unpack_int(packet)
  for i = 1,el do
    table.insert(gp.extensions, ml_unpack(packet))
  end
  return gp
end)

