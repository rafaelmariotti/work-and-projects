#array
v = [1,2,3,4]
puts v.class
puts v.inspect
puts v

puts "\n"

v = [1, 2, 3, "rafael"]
puts v

puts "\n"

v = Array.new
v.push(100)
v.push(101)
v.push(true)
v.push("rafael")
v.push(0.99)
v.unshift(1)
puts v.inspect
v.pop
puts v.inspect
v.shift
puts v.inspect

puts "\n"

#argument vector (ARGV)

x= ARGV
puts x.inspect
puts ARGV[0]
puts ARGV[1]

puts "\n"
#hashes
hash_ = {"a" => 1, "b" => 2, 999 => "rafael", 1 => 100}
puts hash_.class
puts hash_.inspect
puts hash_[1]
puts hash_["b"]

hash_.merge!({"last" => 12345})
puts hash_.inspect