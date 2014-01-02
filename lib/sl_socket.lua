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

sl_socket = {ids=0, sockets={}}

function sl_socket:new(name)
  sl_checktype(name, "string")
  if not sl_current_component then
    err("attempt to create a socket \'"..name.."\' out of component")
  end
  if string.match(name, "%.") then
    err("attempt to create a socket \'"..name.."\' whose name includes \".\"")
  end
  local o = {name=name,
    type="socket",
    path=name,
    peer=nil,
    id=sl_socket.ids,
    parent=sl_current_component,
    tlm1_cbs={},
    tlm2_cbs={}}
  if sl_current_component then
    o.path = sl_current_component.path.."."..name
  end
  sl_socket.ids = sl_socket.ids + 1
  setmetatable(o, {__index = sl_socket})
  sl_socket.sockets[o.path] = o
  return o
end

function sl_socket:is_bound()
  return self.peer
end

function sl_socket:check_peer()
  if not self.peer then
    err("socket "..self.path.." is not bound")
  end
end

function sl_socket:bind(p)
  sl_checktype(p, "socket")
  self.peer = p
  p.peer = self
end

function sl_socket:check_tlm1_cb(cb_name)
  if not self.tlm1_cbs[cb_name] then
    err("socket \'"..self.name.."\' has no callback for \'"..cb_name.."\'")
  end
end

function sl_socket:put(...)
  self:check_peer()
  self.peer:check_tlm1_cb("put")
  return self.peer.tlm1_cbs["put"](...)
end

function sl_socket:register_put(cb)
  sl_checktype(cb, "function")
  self.tlm1_cbs["put"] = cb
end

function sl_socket:unregister_put()
  self.tlm1_cbs["put"] = nil
end

function sl_socket:get()
  self:check_peer()
  self.peer:check_tlm1_cb("get")
  return self.peer.tlm1_cbs["get"]()
end

function sl_socket:register_get(cb)
  sl_checktype(cb, "function")
  self.tlm1_cbs["get"] = cb
end

function sl_socket:unregister_get()
  self.tlm1_cbs["get"] = nil
end

function sl_socket:peek()
  self:check_peer()
  self.peer:check_tlm1_cb("peek")
  return self.peer.tlm1_cbs["peek"]()
end

function sl_socket:register_peek(cb)
  sl_checktype(cb, "function")
  self.tlm1_cbs["peek"] = cb
end

function sl_socket:unregister_peek()
  self.tlm1_cbs["peek"] = nil
end

function sl_socket:check_tlm2_cb(cb_name)
  if not self.tlm2_cbs[cb_name] then
    err("socket \'"..self.name.."\' has no callback for \'"..cb_name.."\'")
  end
end

function sl_socket:b_transport(trans, delay)
  self:check_peer()
  self.peer:check_tlm2_cb("b_transport")
  return self.peer.tlm2_cbs["b_transport"](trans, delay)
end

function sl_socket:register_b_transport(cb)
  sl_checktype(cb, "function")
  self.tlm2_cbs["b_transport"] = cb
end

function sl_socket:unregister_b_transport()
  self.tlm2_cbs["b_transport"] = nil
end

function sl_socket:nb_transport_fw(trans, phase, delay)
  self:check_peer()
  self.peer:check_tlm2_cb("nb_transport_fw")
  return self.peer.tlm2_cbs["nb_transport_fw"](trans, phase, delay)
end

function sl_socket:register_nb_transport_fw(cb)
  sl_checktype(cb, "function")
  self.tlm2_cbs["nb_transport_fw"] = cb
end

function sl_socket:unregister_nb_transport_fw()
  self.tlm2_cbs["nb_transport_fw"] = nil
end

function sl_socket:nb_transport_bw(trans, phase, delay)
  self:check_peer()
  self.peer:check_tlm2_cb("nb_transport_bw")
  return self.peer.tlm2_cbs["nb_transport_bw"](trans, phase, delay)
end

function sl_socket:register_nb_transport_bw(cb)
  sl_checktype(cb, "function")
  self.tlm2_cbs["nb_transport_bw"] = cb
end

function sl_socket:unregister_nb_transport_bw()
  self.tlm2_cbs["nb_transport_bw"] = nil
end

function sl_socket:transport_dbg(trans)
  self:check_peer()
  self.peer:check_tlm2_cb("transport_dbg")
  return self.peer.tlm2_cbs["transport_dgb"](trans, delay)
end

function sl_socket:register_transport_dbg(cb)
  sl_checktype(cb, "function")
  self.tlm2_cbs["transport_dbg"] = cb
end

function sl_socket:unregister_transport_dbg()
  self.tlm2_cbs["transport_dbg"] = nil
end

function socket(name)
  sl_checktype(name, "string")
  local s = nil
  if sl_current_component then
    s = sl_socket.sockets[sl_current_component.path.."."..name]
  end
  if not s then
    s = sl_socket.sockets[name]
  end
  if not s then
    s = sl_socket:new(name)
  end
  return s
end
