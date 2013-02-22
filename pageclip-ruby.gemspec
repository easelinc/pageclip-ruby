# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pageclip-ruby/version'

Gem::Specification.new do |gem|
  gem.name          = "pageclip-ruby"
  gem.version       = Pageclip::Ruby::VERSION
  gem.authors       = ["Matt Colyer"]
  gem.email         = ["matt@easel.io"]
  gem.description   = %q{A simple interface for the Pageclip screenshot service}
  gem.summary       = %q{A simple interface for the Pageclip screenshot service}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency('rspec', ["~> 2.12.0"])
  gem.add_development_dependency('webmock', ["~> 1.9.3"])
end