puts "digite o ano em que estamos"
year = gets

class String
  def is_integer? 
    self.to_i.to_s == self
  end
end

puts year.is_integer?

if year.is_integer?
  puts "right answer!"
else
  raise ArgumentError, "error: wrong year!"
end

###

puts "digite o ano em que voce nasceu"
year = gets.to_i
begin
  result = year + 18
  puts "in #{result} you had 18 years old"

rescue
  puts "not a valid year. please, type only numbers"
  exit
end

###
#
puts "Digite a sua idade"
year = gets.to_i

def verificaIdade(idade)
  unless idade > 18
    raise ArgumetError, "menor de idade"
  end
end
