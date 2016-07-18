class MyAttribute
  @attribute

  def set_attribute=(attribute_value)
    @attribute = attribute_value
  end

  def get_attribute
    puts "My attribute value is #{@attribute}"
  end

  attr_accessor :myname
  attr_reader :myage
end

attribute = MyAttribute.new
attribute.set_attribute = "abc"
attribute.get_attribute

attribute.myname = "rafael"
puts "My name is #{attribute.myname}"
