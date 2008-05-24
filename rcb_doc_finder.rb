require "rdoc/ri/ri_driver"
require "stringio"

class RCBDocFinder
  def initialize
    @ri_options = RI::Options.instance
    @ri_options.parse(%w(--format html))
    @ri = RiDriver.new
  end

  def find(meth)
    output = StringIO.new
    old_stdout = $stdout
    $stdout = output
    begin
      @ri.get_info_for(meth)
    rescue RiError => e
      log(e.message)
      e.message
    ensure
      $stdout = old_stdout
    end
    output.rewind
    output.read
  end
  
end

if __FILE__ == $0
  require 'osx/cocoa'
  include OSX
  docs = RCBDocFinder.new
  p docs.find("Array.new")
end
