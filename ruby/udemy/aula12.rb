#gets, \n, chomp and cast
puts "\nHello, type your name:"
name_ = gets.chomp
puts "\nYour name is " + name_.capitalize!.inspect + "\n"

puts "\nType your age:"
age_ = gets.chomp.to_i
puts "\nYour next age is " + (age_+1).to_s + "\n\n"

#if, else, unless, case and "?"
if age_ >= 18
	puts "You already are an adult, pay your rent!"
else
	puts "Sorry little child, go back to kindergarten!"
end

unless age_ < 21
	puts "Congrats, you can drive!"
else
	puts "You still have to take a bus"
end

case age_
when 18
	puts "You are turning an adult this year"
when 21
	puts "Now you can drive!"
end

age_ <= 10 ? (puts "you shouldn't use this computer") : (puts "You have enough age to use this computer!")

#while, until, for and do
i=age_.to_i

while i < 50
	puts "\nNow your age is " + i.to_s
	i+=1
end
puts "Your 50th anniversary is coming, half-of-a-century age!"

until i<=0
	puts "Traveling through with your Delorian, now you have " + i.to_s
	i-=1
end

for i in 0..100
	puts "count: " + i.to_s
end

[1,2,3,4,5].each do |j|
  puts "running through array: " + j.to_s
end