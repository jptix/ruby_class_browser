class RCBTreeConstructor
  attr_reader :classes
  
  def initialize
    @classes = {}
    # require_stdlib
  end
  
  def create
    ObjectSpace.each_object(Class) do |obj|
      next if obj.name =~ /^RCB/
      @classes[obj.name] ||= RCBClassNode.new(obj) 
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

  def require_stdlib
    Dir["/System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/1.8/*.rb"].each do |f|
      next if f =~ /debug|profile|cgi|mathn|tk|tempfile/
      # log("*** -> " + f)
      require(f)
    end
  end
  
end

class RCBClassNode
  attr_accessor :name, :superclass, :subclasses
  
  def initialize(klass)
    @class = klass
    @name = klass.name
    @superclass = klass.superclass
    @subclasses = []
  end
  
  def <=>(other)
    @name <=> other.name
  end
  
  def instance_methods
    if @name == 'Object'
      Object.instance_methods.sort
    else
      (@class.instance_methods - @class.ancestors.map { |e| e.instance_methods } - Object.methods).sort
    end
  end
  
  def class_methods
    (@class.methods - @class.ancestors.map { |e| e.methods }  - Object.methods).sort
  end
end



if __FILE__ == $0
  require "pp"
  t = RCBTreeConstructor.new
  t.create
  pp t.classes
end
