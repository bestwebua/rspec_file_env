lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec_file_chef/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec_file_chef'
  spec.version       = RspecFileChef::VERSION
  spec.authors       = ['Vladislav Trotsenko']
  spec.email         = ['admin@bestweb.com.ua']

  spec.summary       = %q{RspecFileChef}
  spec.description   = %q{RSpec File Environment control. Keeper of current state of tracked files and temporary files cleaner.}
  spec.homepage      = 'https://github.com/bestwebua/rspec_file_chef'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.5.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.require_paths = ['lib']

  spec.add_dependency "dry-configurable", "0.7"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 13.0", ">= 13.0.1"
end
