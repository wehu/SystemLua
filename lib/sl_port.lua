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

require "sl_component"
require "sl_util"

sl_port = {ids=0, ports={}}

sl_port_by_id = {}

function sl_port:new(name, typ)
  if not typ then
    typ = "port"
  end
  sl_checktype(name, "string")
  sl_checktype(typ, "string")
  if not sl_current_component then
    err("attempt to create a port \'"..name.."\' out of component")
  end
  if string.match(name, "%.") then
    err("attempt to create a port \'"..name.."\' whose name includes \".\"")
  end
  local o = {name=name,
    typ=typ,
    path=name,
    peer=nil,
    is_export=false,
    id=sl_port.ids,
    parent=sl_current_component}
  if sl_current_component then
    o.path = sl_current_component.path.."."..name
  end
  sl_port.ids = sl_port.ids + 1
  setmetatable(o, {__index = sl_port})
  sl_port.ports[o.path] = o
  sl_port_by_id[o.id] = o
  return o
end

function sl_port:connect(p)
  self.peer = p
end

function sl_port:check_peer(typ)
  if not self.peer then
    err("port "..self.path.." is not connected")
  end
end

function sl_port:check_connection_type(p, typ)
  if (typ and p.typ ~= typ) or (self.typ ~= p.typ) then
    err("attempt to connect port "..self.path..":"..self.typ.." with different type of port "..p.path..":"..p.typ)
  end
  if self.is_export == p.is_export then
    err("attempt to connect port "..self.path.." with "..p.path..", they are both export:"..self.is_export)
  end
end

function port(name, typ)
  if not typ then
    typ = "port"
  end
  sl_checktype(name, "string")
  sl_checktype(typ, "string")
  local p = nil
  if sl_current_component then
    p = sl_port.ports[sl_current_component.path.."."..name]
  end
  if not p then
    p = sl_port.ports[name]
  end
  if not p then
    p = sl_port:new(name, typ)
  end
  return p
end

function find_port_by_id(id)
  sl_checktype(id, "number")
  local p = sl_port_by_id[id]
  if not p then
    err("cannot find port by id "..id)
  end
  return p
end
