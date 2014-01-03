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

local function generate_tlm1_port(pre, typ)
  local pn = pre.."_"..typ.."_port"
  local pt = "tlm_"..pre.."_"..typ
  local can_typ = "can_"..typ
  _G[pn] = function(name)
     local p = port(name, pt)
     p[typ] = function(self, ...)
       self:check_peer()
       if not self.peer[typ] then
         err("cannot find \'"..typ.."\' function in peer")
       end
       return self.peer[typ](self.peer, unpack(arg))
     end
     p[can_typ] = function(self, ...)
       self:check_peer()
       if not self.peer[can_typ] then
         err("cannot find \'"..can_typ.."\' function in peer")
       end
       return self.peer[can_typ](self.peer, unpack(arg))
     end
     function p:connect(ap)
       self:check_connection_type(ap, pt)
       self.peer = ap
     end
     return p
   end
  local pni = pre.."_"..typ.."_port_imp"
  _G[pni] = function(name, imp, can_imp)
    local p = port(name, pt)
    p.is_export = true
    p[typ] = function(self, ...)
      if imp then
        sl_checktype(imp, "function")
        return imp(self, unpack(arg))
      end
    end
    p[can_typ] = function(self, ...)
      if can_imp then
        sl_checktype(can_imp, "function")
        return can_imp(self, unpack(arg))
      end
    end
    function p:connect(ap)
      self:check_connection_type(ap, pt)
      ap.peer = self
    end
    return p
  end
end

generate_tlm1_port("blocking", "put")
generate_tlm1_port("blocking", "get")
generate_tlm1_port("blocking", "peek")

generate_tlm1_port("nonblocking", "put")
generate_tlm1_port("nonblocking", "get")
generate_tlm1_port("nonblocking", "peek")

