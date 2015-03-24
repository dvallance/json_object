# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_object/version'

Gem::Specification.new do |spec|
  spec.name          = "json_object"
  spec.version       = JsonObject::VERSION
  spec.authors       = ["Dave Vallance"]
  spec.email         = ["davevallance@gmail.com"]
  spec.summary       = %q{Instead of accessing JSON Hashs the usual way, this allows creating custom classes to represent and access the JSON values.}
  spec.description   = %q{Quickly build objects to represent, store and access JSON Hash values. You can control the accessor method names, default values and provide procs to do more complex computation.}
  spec.homepage      = "https://github.com/dvallance/json_object"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
