require "sl_core"

component("foo", function ()
  socket("bar")
  blocking_put_port("bp")
  blocking_get_port("bg")
end)

component("foo1", function()
  socket("bar")
  blocking_put_port_imp("bpi", function(self, packet)
    info(packet)
  end)
  blocking_get_port_imp("bgi", function(self)
    return "get"
  end)
end)

local fb = socket("foo.bar")
local f1b = socket("foo1.bar")
fb:bind(f1b)

local bp = port("foo.bp")
local bpi = port("foo1.bpi")
bp:connect(bpi)

local bg = port("foo.bg")
local bgi = port("foo1.bgi")
bg:connect(bgi)


f1b:register_put(function (data)
  info(data)
end)

fb:put(11)

bp:put(15)

info(find_port_by_id(bp.id).path)

info(bg:get())
