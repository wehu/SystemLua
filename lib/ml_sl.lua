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

local function create_connector(p)
  local c = {}
  if p.typ == "tlm_blocking_put" then
    function c:put(packet)
      uvm_sl_ml_request_put(p.id, packet)
    end
  end
  return c
end

function ml_connect(path1, path2)
  local p1 = sl_port.ports[path1]
  local p2 = sl_port.ports[path2]
  --if p1 and p2 then
  --  return p1:connect(p2)
  --elseif p1 and not p2 then
  if p1 then
    p1.peer = create_connector(p1)
  --elseif not p1 and p2 then
  else
  end
  return uvm_sl_ml_connect(path1, path2) 
end

function uvm_sl_ml_request_put_callback(id, packet)
  local p = find_port_by_id(id)
  return p:put(packet)
end
