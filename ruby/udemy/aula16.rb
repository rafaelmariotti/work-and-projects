def soma(a, b)
	puts "o resultado é :#{a+b}"
end

soma 5, 5
soma(5, 5)

CONSTANT = "constant"
constant = "variable"

puts constant
puts CONSTANT

str = "pao,de,batata"
str_split = str.split(",")
str_join = str_split.join(" ")

puts str_split
puts str_join

x = eval("10+10")
puts x

puts x.instance_of?(Fixnum)
puts x.instance_of?(Array)

(1..10).each do |x|
	puts x
end

(1...10).each do |x|
	puts x
end

