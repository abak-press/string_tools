# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'string_tools/version'

Gem::Specification.new do |spec|
  spec.name          = 'string_tools'
  spec.version       = StringTools::VERSION
  spec.authors       = ['Sergey D.']
  spec.email         = ['sclinede@gmail.com']

  spec.summary       = %q{String Tools}
  spec.description   = %q{String Tools}
  spec.homepage      = 'https://github.com/abak-press/string_tools'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rails', '>= 4.2', '< 5'
  spec.add_runtime_dependency 'actionpack', '>= 4.2.0'
  spec.add_runtime_dependency 'activesupport', '>= 4.2.0'
  spec.add_runtime_dependency 'rchardet19', '~> 1.3.5'
  spec.add_runtime_dependency 'addressable', '>= 2.3.2'
  spec.add_runtime_dependency 'ru_propisju', '>= 2.1.4'
  spec.add_runtime_dependency 'sanitize', '>= 3.1.2'
  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'simpleidn', '>= 0.0.5'
  spec.add_runtime_dependency 'pg'

  spec.add_development_dependency 'bundler', '~> 1.17.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec-rails', '~> 3.0'
  spec.add_development_dependency 'combustion', '>= 0.5.4'
  spec.add_development_dependency 'appraisal', '>= 1.0.2'
  spec.add_development_dependency 'simplecov', '>= 0.9'
  spec.add_development_dependency 'pry-byebug'
end
