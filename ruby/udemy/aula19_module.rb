module Pagamento
	TIPO_PAGAMENTO = {"debito" => 1, "credito" => 2}

	def realizar_pagamento(valor, tipo_pagamento)
		puts "Pagamento de #{valor} efetuado com sucesso no tipo #{TIPO_PAGAMENTO[tipo_pagamento]}"
	end

	class PagSeguro
		def initialize
			puts "pagSeguro iniciado"
		end
	end

end