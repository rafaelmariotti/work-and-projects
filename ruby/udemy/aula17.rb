class Pessoa
	def initialize(my_name)
		@my_name = my_name

	end

	attr_accessor :my_name
	#same as
	#def my_name
	#	@my_name
	#end

	#def my_name=(my_name)
	#	@my_name = my_name
	#end

	def introduce_yourself
		puts "Hello"
	end

	def what_is_my_id_number?
		puts self.object_id
	end
end