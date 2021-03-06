class RCBClassNode
  attr_accessor :name, :superclass, :subclasses
  
  def initialize(klass)
    @class = klass
    @name = klass.name
    @superclass = klass.class == Module ? Object : klass.superclass
    @subclasses = []
  end
  
  def <=>(other)
    @name <=> other.name
  end
  
  def instance_methods
    (@class == Object ? @class.instance_methods : @class.instance_methods(false)).sort
  end
  
  def class_methods
    (@class == Object ? @class.methods : @class.methods(false)).sort
  end
end