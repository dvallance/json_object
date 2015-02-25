# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_object/version'

Gem::Specification.new do |spec|
  spec.name          = "json_object"
  spec.version       = JsonObject::VERSION
  spec.authors       = ["Dave Vallance"]
  spec.email         = ["davevallance@gmail.com"]
  spec.summary       = %q{Assign custom accessors for a json hash.}
  spec.description   = %q{A json hash is stored internally and you define how you wish to access the values. You can control the accessor names, default values and provide procs to do more complex computation}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
