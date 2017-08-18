class Pessoa
	attr_accessor :nome, :endereco
end

#require_relative "pessoa.rb"
class PessoaJuridica < Pessoa
	attr_accessor :cnpj, :nome_fantasia
end

class PessoaFisica < Pessoa
	attr_accessor :cpf, :data_nascimento
end