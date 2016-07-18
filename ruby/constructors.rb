class MyConstructor

  def initialize(newMessage, newConstant)
    @tryCons = newConstant
    puts "#{newMessage}"
  end

  def getCons
    puts "#{@tryCons}"
  end

end

#constructor1 = MyConstructor.new
constructor2 = MyConstructor.new("new message from constructor", 100)
constructor2.getCons
