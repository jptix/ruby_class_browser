require "rcb_class_node"

class RCBTreeConstructor
  attr_reader :classes, :methods
  
  def initialize
    @classes = {}
    @methods = Hash.new { |h, k| h[k] = [] }
    # require_stdlib
  end
  
  def create
    ObjectSpace.each_object(Module) do |obj|
      next if obj.name =~ /^(RCB|RiOutputter)|^$/
      name = obj.name.empty? ? obj.to_s : obj.name
      node = (@classes[obj.name] ||= RCBClassNode.new(obj))
      
    #   obj.instance_methods(false).each do |meth|
    #     arr = @methods[meth] 
    #     arr << node unless arr.include?(node)
    #   end
    #   
    #   obj.methods(false).each do |meth|
    #     arr = @methods[meth] 
    #     arr << node unless arr.include?(node)
    #   end
    end
    
    @classes.delete(nil)
    @classes.values.each do |node|
      if parent_node = @classes[node.superclass.to_s]
        parent_node.subclasses << node
      end
    end
    
    @classes.values.each { |node| node.subclasses.sort!  }
    @classes
  end
  
  private

  # buggy...
  def require_stdlib
    Dir["/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/*.rb"].each do |f|
      next if f =~ /tk/
      begin
        require(f)
      rescue Exception => e 
        log(e.message)
        next
      end
    end
  end
  
end

if __FILE__ == $0
  require "pp"
  t = RCBTreeConstructor.new
  classes = t.create
  # require 'rubygems'; require 'ruby-debug'
  # debugger
  pp classes
end
