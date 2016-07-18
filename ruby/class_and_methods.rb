class Pessoa
  def talk_hi
    "hello people!"
  end

  def talk_goodbye(message = "Good bye, bitches!")
    "#{message}"
  end

  def talk_ask_something(message = "how are you?")
    "Rafael asks: #{message}"
  end
end

class Pessoa
  def eat_something(comida)
    puts self.talk_hi
    #talk_hi
    "eating #{comida}! Yammy!"
  end

  def eat_lot_of_food(*food)
    puts "eating #{food.size} foods: #{food}"
  end

end

rafael = Pessoa.new
puts rafael.talk_hi

question1 = rafael.talk_ask_something("how old are you?")
question2 = rafael.talk_ask_something

puts question1
puts question2

puts rafael.eat_something :hamburguer
rafael.eat_lot_of_food "pao", "queijo", "presunto", "ricota"

puts rafael.talk_goodbye("See ya!")
