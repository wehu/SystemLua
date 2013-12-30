require "sl_core"

component("foo", function ()
  socket("bar")
end)

component("foo1", function()
  socket("bar")
end)

