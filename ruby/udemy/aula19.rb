require_relative "aula19_module"

class TestModulo
	include Pagamento

	def runPagamento
		puts "digite o tipo de pagamento (credito ou debito)"
		tipo_pagamento = gets.chomp
	
		puts "o pagamento escolhido foi #{Pagamento::TIPO_PAGAMENTO[tipo_pagamento]}"

		puts "digite o valor"
		valor = gets.chomp

		realizar_pagamento(valor, tipo_pagamento)

		pag_seguro = Pagamento::PagSeguro.new

		puts "adeus!"
	end

end