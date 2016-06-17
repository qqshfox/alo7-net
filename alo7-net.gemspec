# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alo7/net/version'

Gem::Specification.new do |spec|
  spec.name          = 'alo7-net'
  spec.version       = Alo7::Net::VERSION
  spec.authors       = ['Hanfei Shen']
  spec.email         = ['qqshfox@gmail.com']

  spec.summary       = 'A TCP server/client library used at ALO7.'
  spec.description   = 'alo7-net is the TCP server/client library we developed specifically for our ALO7 Learning Platform. This library provides a way to write asynchronous code in a straight-line fashion using fibers.'
  spec.homepage      = 'https://github.com/qqshfox/alo7-net'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'eventmachine', '~> 1.0'
  spec.add_runtime_dependency 'em-synchrony', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency 'rubocop'
end
