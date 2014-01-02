function packet(data)
  local p = {}
  p.typ = "packet"
  p.data = data or 17
  return p
end

component("sltop", function(self)
  blocking_put_port("p0")
  blocking_put_port_imp("p1", function(self, data)
    info("AAA "..data)
  end)
  blocking_get_port("p2")
  blocking_get_port_imp("p3", function(self)
    --wait(1)
    return 3
  end)
  blocking_put_port("p4")
  blocking_get_port("p5")
  info("SL sltop::new")
  function self:build()
    info("SL sltop::build")
    ml_register_port("sltop.p5")
  end
  function self:connect()
    info("SL sltop::connect")
    ml_connect("sltop.p0", "sltop.p1")
    ml_connect("sltop.p2", "sltop.p3")
    ml_connect("sltop.p4", "svtop.put_export")
    --ml_connect("sltop.p5", "svtop.get_export")
    info(port("sltop.p0").peer)
  end
  function self:run()
    while true do
     wait(2)
     info("SL sltop::run")
     port("sltop.p0"):put(1)
     info(port("sltop.p2"):get("number"))
     port("sltop.p4"):put(packet(1000))
     info(port("sltop.p5"):get("packet").data)
    end
  end
  component("slchild", function(self)
    info("SL slchild:new")
    function self:build()
      info("SL slchild::build")
    end
    function self:run()
      while true do
       wait(3)
       info("SL slchild::run")
      end
    end
  end)
end)

ml_register_packer("packet", function(o, p)
  table.insert(o, p.data)
  return o
end)

ml_register_unpacker("packet", function(p)
  return packet(p[3])
end)

ml_set_packet_size("packet", 1)

