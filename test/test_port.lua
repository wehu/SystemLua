require "sl_core"

component("foo", function ()
  blocking_put_port("bp")
  blocking_get_port("bg")
end)

component("foo1", function()
  blocking_put_imp("bpi", function(self, packet)
    info(packet)
  end)
  blocking_get_imp("bgi", function(self)
    return "get"
  end)
end)

local bp = port("foo.bp")
local bpi = port("foo1.bpi")
bp:connect(bpi)

local bg = port("foo.bg")
local bgi = port("foo1.bgi")
bg:connect(bgi)


bp:put(15)

info(find_port_by_id(bp.id).path)

info(bg:get())
