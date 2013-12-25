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
