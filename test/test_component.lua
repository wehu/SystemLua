require "sl_core"

component("foo", function(self)
  component("bar", function()
    component("zoo")
  end)
  function self:build()
    info("build")
  end
end)

info(component("foo").name)
info(component("foo.bar").name)
info(component("foo.bar.zoo").name)

notify_phase("common", "build")

info(find_component_by_id(component("foo").id).name)
