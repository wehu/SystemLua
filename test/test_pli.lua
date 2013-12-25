bind_signal("clk", "tb.clk")
bind_signal("foo", "tb.foo")

local i = 0

always(signal("clk").anyedge, function()
  signal("foo"):write(i)
  i = i + 1
  if i >10 then
    sim_finish()
  end
end)

signal("foo"):write(1)
