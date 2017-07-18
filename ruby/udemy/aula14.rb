x = "rails"
puts "Ruby on #{x}"

string_vector = %w(creating a string vector)
puts string_vector.inspect

names = %w(Rafael Daniel Michel Gabriel)
names.each do |name_|
	puts "Hello #{name_}"
end

puts "Ruby"+" on "+"Rails for " + names[0]
puts "Ruby" << " on " << "Rails for " + names[1]

text="Ruby" << " on " << "Rails for " + names[2]
text.gsub!("Michel", "everybody")
puts text

text="Rafael Mariotti"
puts text.object_id
text="Mr. " + text
puts text.object_id
text=text << " be careful"
puts text.object_id

hash_with_symbol1 = {:a => 123, :b => "456"}
hash_with_symbol2 = {a: 123, b: "456"}
puts "hash #{hash_with_symbol1} is equivalent to #{hash_with_symbol2}"