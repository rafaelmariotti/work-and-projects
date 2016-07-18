class MyArray

  def initialize
    createArray
  end

  def createArray
    @array = Array.new
  end

  def add_value(value)
    @array << value
  end

  def get_size
    puts "My array size is #{@array.size}"
  end

  def list_values_index
    for index in 0 .. @array.size
      puts @array[index]
    end
  end

  def list_values_each
    @array.each do |value|
      puts value
    end
  end

  def list_fast_values
    puts @array
  end
end


class MyHash
  def createHash
    @hash = Hash.new
  end

  def add_info(arguments)
    @hash[:nome] = arguments[:nome]
    @hash[:sobrenome] = arguments[:sobrenome]
    @hash[:idade] = arguments[:idade]
  end

  def get_hash
    @hash
  end

end


class ArraySort

  def initialize

    @arrayHash = [
      {id: 1,
       nome: "rafael",
       idade: 24
      },
      {id: 3,
       nome: "estela",
       idade: 20
      },

      {id: 2,
       nome: "dejair",
       idade: 65
      }
    ]
  end

  def sortByArrayAndHash
    @arrayHash.sort_by { |information| information[:nome] }.each do |information|
      puts "Hi #{information[:nome]}"
    end
  end

end


test1 = MyArray.new

#puts test1.methods

test1.add_value :abc
test1.add_value "123"
test1.add_value "xyz"

test1.get_size
test1.list_values_each
#test1.list_values_index
#or
puts test1.list_fast_values

###
test2 = MyHash.new

test2.createHash
test2.add_info :idade => 24, :nome => "rafael", :sobrenome => "mariotti"

puts test2.get_hash

###
test3 = ArraySort.new
test3.sortByArrayAndHash
