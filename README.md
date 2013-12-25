# SystemLua

## A lua version of SystemC

SystemLua is a lua version of SystemC.
It can co-simulate with verilog by VPI.

## Example

### Standalone

	-- file test.lua
	
	require "sl_core"
	
	run(function()
	  always(signal("foo").anyedge, function ()
	    info("foo")
	  end)
	  always(3, function ()
	    info("bar")
	  end)
	  initial(function ()
	    signal("foo"):write(1)
	    wait(1)
	    signal("foo"):write(0)
	  end)
	end, 10)

### Co-simulation

	-- file test_pli.lua

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

	// file tb.v

	module tb();
	  reg clk;
	  reg foo;
	  always #1 clk <= ~clk;
	  always@(foo) begin
	    $display("%0d foo", $time());
	  end
	  initial begin
	    clk = 0;
	    $sys_lua("test_pli.lua");
	    #100 $finish();
	  end
	endmodule

