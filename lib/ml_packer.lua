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
require "sl_logger"

local packers = {}

function ml_register_packer(typ, body)
  sl_checktype(typ, "string")
  sl_checktype(body, "function")
  if not packers[typ] then
    packers[typ] = {}
  end
  packers[typ].sl_pack = body
end

function ml_register_unpacker(typ, body)
  sl_checktype(typ, "string")
  sl_checktype(body, "function")
  if not packers[typ] then
    packers[typ] = {}
  end
  packers[typ].sl_unpack = body
end

function ml_set_packet_size(typ, size)
  sl_checktype(typ, "string")
  sl_checktype(size, "number")
  if not packers[typ] then
    packers[typ] = {}
  end
  packers[typ].sl_size = size + 2
end

function ml_set_packet_type(packet, data)
  sl_checktype(packet, "table")
  local typ = type(data)
  if typ == "table" and data.type then
    typ = data.type
  end
  local id = uvm_sl_ml_get_type_id(typ)
  packet[2] = id
end

function ml_pack(data, packet, size)
  local typ = type(data)
  if not packet then
    packet = {}
  end
  if not size then
    size = 1
  end
  if typ == "table" and data.type then
    typ = data.type
  end
  if typ == "nil" then
    table.insert(packet, 0)
  elseif packers[typ] and packers[typ].sl_pack then
    local id = uvm_sl_ml_get_type_id(typ)
    table.insert(packet, 1)
    table.insert(packet, id)
    packers[typ].sl_pack(packet, data, size)
    --id = uvm_sl_ml_get_type_id("unsigned")
    --table.insert(packet, id)
    --table.insert(packet, data)
  else
    err("unsupported packed data type "..typ)
  end
  return packet
end

function ml_unpack(packet, size)
  if packet[1] == 0 then
    return nil
  end
  if not size then
    size = 0
  end
  local id =  packet[2]
  local typ = uvm_sl_ml_get_type_name(id)
  local data = nil
  if packers[typ] and packers[typ].sl_unpack then
    data = packers[typ].sl_unpack(packet, size)
  else
    err("unsupported packed data type "..typ)
  end
  return data
end

function ml_packet_size(typ)
  sl_checktype(typ, "string")
  local size = 0
  if typ == "nil" then
    return 1
  end
  if packers[typ] and packers[typ].sl_size then
    size = packers[typ].sl_size
  else
    err("unsupported packed data type "..typ)
  end
  return size
end

--[[
function uvm_sl_ml_check_type_size(id, size)
  local typ = uvm_sl_ml_get_type_name(id)
  local packet_size = ml_packet_size(typ)
  if packet_size ~= size then
    err("the packet size of type "..typ.." expect "..packet_size.." but got "..size)
  end
end
--]]

local b32 = 2^32

ml_register_packer("number", function(packet, data, size)
  if size == 64 then
    table.insert(packet, data%b32)
    table.insert(packet, math.floor(data/b32))
  else
    table.insert(packet, data)
  end
  return packet
end)

ml_register_unpacker("number", function(packet, size)
  table.remove(packet, 1)
  table.remove(packet, 1)
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
end)

