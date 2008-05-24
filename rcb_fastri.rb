require "rinda/ring"

class RCBFastRi
  def initialize
    @path = "/usr/bin/fastri-server"
    @task   = NSTask.alloc.init
    @stdout  = NSPipe.alloc.init
    @stderr  = NSPipe.alloc.init

    @fast_ri_options = {
      :extended  => true,
      :formatter => 'plain'
    }
    run
  end

  def info(meth)
    @fast_ri.info(meth, @fast_ri_options)
  end

  private
  
  def run
    # launch fastri-server
    @task.setLaunchPath(@path)
    @task.setStandardError(@stderr)
    @task.setStandardOutput(@stdout)
    at_exit { @task.terminate }
    @task.launch

    # find the resource
    DRb.start_service
    if ring = Rinda::RingFinger.new.lookup_ring_any(2)
      @fast_ri = ring.read_all([:name, :FastRI, nil, nil])[2][2]
    else
      raise "Could not connect to FastRi"
    end
  end
  
end

if __FILE__ == $0
  require 'osx/cocoa'
  include OSX
  fast_ri = RCBFastRi.new
  puts fast_ri.info("Array.new")
end
