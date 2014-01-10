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

function ml_pack(data, packet, nonnull)
  local typ = type(data)
  if not packet then
    packet = {}
  end
  sl_checktype(packet, "table")
  if typ == "table" and data.type then
    typ = data.type
  end
  if nonnull and typ == "nil" then
    err("a nil is packed")
  end
  if typ == "nil" then
    table.insert(packet, 0)
  elseif packers[typ] and packers[typ].sl_pack then
    local id = uvm_sl_ml_get_type_id(typ)
    if not nonnull then
      table.insert(packet, 1)
    end
    table.insert(packet, id)
    packers[typ].sl_pack(data, packet)
    --id = uvm_sl_ml_get_type_id("unsigned")
    --table.insert(packet, id)
    --table.insert(packet, data)
  else
    err("unsupported packed data type "..typ)
  end
  return packet
end

function ml_unpack(packet, nonnull)
  sl_checktype(packet, "table")
  if packet[1] == 0 and not nonnull then
    return nil
  end
  if not nonnull then
    table.remove(packet, 1)
  end
  local id =  packet[1]
  table.remove(packet, 1)
  local typ = uvm_sl_ml_get_type_name(id)
  local data = nil
  if packers[typ] and packers[typ].sl_unpack then
    data = packers[typ].sl_unpack(packet)
  else
    err("unsupported packed data type "..typ)
  end
  return data
end

local b32 = 2^32

function ml_pack_int(data, packet, size)
  sl_checktype(data, "number")
  sl_checktype(packet, "table")
  if not size then
    size = 32
  end
  sl_checktype(size, "number")
  local len = math.ceil(size/32)
  for i = 1, len do
    table.insert(packet, data%b32)
    data = math.floor(data/b32)
  end
  return packet
end

function ml_unpack_int(packet, size)
  sl_checktype(packet, "table")
  if not size then
    size = 32
  end
  local data = 0
  local rest = 0
  local len = math.ceil(size/32)
  for i = 1, len do
    rest = packet[1]
    for j = 1, i-1 do
      rest = rest * b32
    end
    data = data + rest
    table.remove(packet, 1)
  end
  return data
end

ml_register_packer("number", function(data, packet)
  table.insert(packet, data)
  return packet
end)

ml_register_unpacker("number", function(packet)
  local data = 0
  data = ml_unpack_int(packet)
  return data
end)

