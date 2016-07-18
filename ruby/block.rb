class BlockTestNames

  def initialize(names)
    @names = names
  end

  attr_accessor :names

  def addPeopleName(newName)
    @names << newName
  end

  def getAllNames#(&block)    
    for name in @names
      allNames = "#{allNames}, #{name} "

      if block_given?
        #block.call(allNames)
        yield(allNames)
      end

    end
    puts "#{allNames}\n\n"
  end

end

teste = BlockTestNames.new [:rafael, :daniel, :dejair]
teste.addPeopleName "sonia"

teste.getAllNames do |parcialNames|
  puts parcialNames
end

#without block
teste.getAllNames
