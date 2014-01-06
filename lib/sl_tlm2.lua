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

function sl_phase:new(p)
  sl_checktype(p, "string")
  local o = {type="phase", value=p}
  setmetatable(o, {__index = sl_phase})
  return o
end

function phase(p)
  return sl_phase:new(p)
end

function initiator_b_transport_port(name)
  local p = port(name, "tlm_blocking_master")
  function p:b_transport(trans, delay)
    sl_checktype(trans, "transaction")
    sl_checktype(delay, "time")
    self:check_peer()
    if not self.peer.b_transport then
      err("cannot find \'b_transport\' function in peer")
    end
    return self.peer:b_transport(trans, delay)
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_blocking_slave")
    self.peer = ap
    ap.peer = self
  end
  return p 
end

function target_b_transport_port(name, imp)
  local p = port(name, "tlm_blocking_slave")
  function p:b_transport(trans, delay)
    sl_checktype(trans, "transaction")
    sl_checktype(delay, "time")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans, delay)
    end 
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_blocking_master")
    ap.peer = self
    self.peer = ap
  end
  return p
end

function initiator_nb_transport_port(name, imp)
  local p = port(name, "tlm_nonblocking_master")
  function p:nb_transport_fw(trans, phase, delay)
    sl_checktype(trans, "transaction")
    sl_checktype(phase, "phase")
    sl_checktype(delay, "time")
    self:check_peer()
    if not self.peer.nb_transport_fw then
      err("cannot find \'nb_transport_fw\' function in peer")
    end
    return self.peer:nb_transport_fw(trans, phase, delay)
  end
  function p:nb_transport_bw(trans, phase, delay)
    sl_checktype(trans, "transaction")
    sl_checktype(phase, "phase")
    sl_checktype(delay, "time")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans, phase, delay)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_nonblocking_slave")
    self.peer = ap
    ap.peer = self
  end
  return p
end

function target_nb_transport_port(name)
  local p = port(name, "tlm_nonblocking_slave")
  function p:nb_transport_bw(trans, phase, delay)
    sl_checktype(trans, "transaction")
    sl_checktype(phase, "phase")
    sl_checktype(delay, "time")
    self:check_peer()
    if not self.peer.nb_transport_bw then
      err("cannot find \'nb_transport_bw\' function in peer")
    end
    return self.peer:nb_transport_bw(trans, phase, delay)
  end
  function p:nb_transport_fw(trans, phase, delay)
    sl_checktype(trans, "transaction")
    sl_checktype(phase, "phase")
    sl_checktype(delay, "time")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans, phase, delay)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_nonblocking_master")
    self.peer = ap
    ap.peer = self
  end
  return p
end

function initiator_transport_dbg_port(name)
  local p = port(name, "tlm_master")
  function p:transport_dbg(trans)
    sl_checktype(trans, "transaction")
    self:check_peer()
    if not self.peer.transport_dbg then
      err("cannot find \'transport_dbg\' function in peer")
    end
    return self.peer:transport_dbg(trans)
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_slave")
    self.peer = ap
    ap.peer = self
  end
  return p
end

function target_transport_dbg_port(name, imp)
  local p = port(name, "tlm_slave")
  function p:transport_dbg(trans)
    sl_checktype(trans, "transaction")
    if imp then
      sl_checktype(imp, "function")
      return imp(self, trans)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_master")
    ap.peer = self
    self.peer = ap
  end
  return p
end

function generic_payload()
  local gp = transaction()
  gp.command = ""
  return gp
end

ml_register_packer("generic_payload", function(packet, gp)
  table.insert(packet, gp.command)
  return packet
end)

ml_register_unpacker("generic_payload", function(packet)
  local gp = generic_payload()
  gp.command = packet[3]
  return gp
end)

