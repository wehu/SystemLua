require "sl_core"

run(function()
  always(signal("aaa").anyedge, function ()
    info("aaa")
  end)
  always(event_or(signal("aaa").anyedge, signal("bbb").anyedge), function ()
    info("bbb")
  end)
  always(event_and(signal("aaa").anyedge, signal("bbb").anyedge), function ()
    info("ccc")
  end)
  always(3, function ()
    info("b")
  end)
  initial(function ()
    signal("aaa"):write(1)
    wait(1)
    signal("aaa"):write(0)
    signal("bbb"):write(1)
    wait(1)
    signal("aaa"):write(1)
    --wait(1)
    signal("bbb"):write(0)
    pipe("p"):write(2)
    wait(1)
    pipe("p"):write(3)
  end)
  always(pipe("p").event_wr, function()
    info(pipe("p"):peek())
    info(pipe("p"):size())
    info(pipe("p"):read())
  end)
end, 10)

