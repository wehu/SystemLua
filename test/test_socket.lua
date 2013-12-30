require "sl_core"

component("foo", function ()
  socket("bar")
end)

component("foo1", function()
  socket("bar")
end)

local fb = socket("foo.bar")
local f1b = socket("foo1.bar")
fb:bind(f1b)

f1b:register_put(function (data)
  info(data)
end)

fb:put(11)
