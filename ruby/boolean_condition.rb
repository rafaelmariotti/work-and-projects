def find_your_name_and_year (name, year, state)
  #
  case name
  when "Rafael"
    puts "Correct name!"
  else
    puts "Wrong name!"
  end

  #
  case year
  when 2015
    puts "Correct year!"
  else
    puts "Wrong year!"
  end

  #
  if(state=="Single")
    puts "You are single"
  else
    puts "Not a valid state!"
  end

end

puts find_your_name_and_year("Rafael", 2014, "single".capitalize)
