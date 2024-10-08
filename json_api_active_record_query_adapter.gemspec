Gem::Specification.new do |s|
  s.name        = "json_api_active_record_query_adapter"
  s.version     = "2.0.0"
  s.date        = "2023-04-19"
  s.summary     = "Syntax query definition and adapter for using with active record."
  s.description = "Syntax query definition and adapter for using with active record."
  s.authors     = ["Lucas Hunter, Luiz Filipe, Leonardo Baptista, Rafael C. Abreu"]
  s.email       = "ops@prosas.com.br"
  s.files       = ["lib/json_api_active_record_query_adapter.rb"]
  s.require_paths = ["lib"]
  s.homepage    = "https://github.com/prosas/json_api_active_record_query_adapter"
  s.license     = "MIT"
  s.metadata['allowed_push_host'] = 'https://rubygems.org'

  s.add_runtime_dependency "activesupport", [">= 6"]
  s.add_development_dependency "rake", [">= 13"]
  s.add_development_dependency "minitest", [">= 5"]
  s.add_development_dependency "byebug", [">= 11"]
end
