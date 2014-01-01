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

function ml_pack(data)
  local typ = type(data)
  local packet = {}
  local id = 0
  if typ == "table" and data.typ then
    typ = data.typ
  end
  local id = uvm_sl_ml_get_type_id(typ)
  if typ == "number" then
    id = uvm_sl_ml_get_type_id("unsigned")
    table.insert(packet, id)
    table.insert(packet, data)
  else
    err("unsupported packed data type "..typ)
  end
  return packet
end

function ml_unpack(packet)
  local id =  packet[1]
  local typ = uvm_sl_ml_get_type_name(id)
  local data = nil
  if typ == "unsigned" then
    data = packet[2]
  else
    err("unsupported packed data type "..typ)
  end
  return data
end

function ml_packet_size(typ)
  sl_checktype(typ, "string")
  local size = 0
  if typ == "unsigned" then
    size = 2
  else
    err("unsupported packed data type "..typ)
  end
  return size
end
