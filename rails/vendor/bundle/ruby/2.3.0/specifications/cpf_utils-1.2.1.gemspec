# -*- encoding: utf-8 -*-
# stub: cpf_utils 1.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "cpf_utils".freeze
  s.version = "1.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jackson Pires".freeze]
  s.date = "2014-04-09"
  s.description = "Uma su\u{ed}te de funcionalidades para o CPF.".freeze
  s.email = ["jackson.pires@gmail.com".freeze]
  s.homepage = "https://github.com/jacksonpires/cpf_utils".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.5.2".freeze
  s.summary = "Gera CPF para testes no formado tradicional ou apenas num\u{e9}rico, testa se determinado n\u{fa}mero de CPF \u{e9} v\u{e1}lido, al\u{e9}m muitas outras funcionalidades descritas na documenta\u{e7}\u{e3}o.".freeze

  s.installed_by_version = "2.5.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.14.1"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.14.1"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.14.1"])
  end
end
