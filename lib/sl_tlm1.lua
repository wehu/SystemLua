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

function blocking_put_port(name)
  local p = port(name, "tlm_blocking_put")
  function p:put(data)
    self:check_peer()
    self.peer:put(data)
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_blocking_put")
    self.peer = ap
  end
  return p
end

function blocking_put_port_imp(name, put_imp)
  local p = port(name, "tlm_blocking_put")
  p.is_export = true
  function p:put(data)
    if put_imp then
      sl_checktype(put_imp, "function")
      put_imp(self, data)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_blocking_put")
    ap.peer = self
  end
  return p
end

function blocking_get_port(name)
  local p = port(name, "tlm_blocking_get")
  function p:get()
    self:check_peer()
    return self.peer:get()
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_blocking_get")
    self.peer = ap
  end
  return p
end

function blocking_get_port_imp(name, get_imp)
  local p = port(name, "tlm_blocking_get")
  p.is_export = true
  function p:get()
    if get_imp then
      sl_checktype(get_imp, "function")
      return get_imp(self)
    end
  end
  function p:connect(ap)
    self:check_connection_type(ap, "tlm_blocking_get")
    ap.peer = self
  end
  return p
end

