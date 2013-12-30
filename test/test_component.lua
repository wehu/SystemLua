require "sl_core"

component("foo", function()
  component("bar", function()
    component("zoo")
  end)
end)

info(component("foo").name)
info(component("foo.bar").name)
info(component("foo.bar.zoo").name)
