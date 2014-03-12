# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "adhearsion-ivr/version"

Gem::Specification.new do |s|
  s.name        = "adhearsion-ivr"
  s.version     = AdhearsionIVR::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Klang", "Ben Langfeld"]
  s.email       = "dev@adhearsion.com"
  s.homepage    = "http://adhearsion.com"
  s.summary     = "IVR building blocks for Adhearsion applications"
  s.description = "This provides a consistent way of implementing Interactive Voice Response prompts, including reprompting and error handling"

  s.license = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', [">= 3.0.0", "< 5.0.0"]
  s.add_runtime_dependency 'adhearsion', ["~> 2.0"]
  s.add_runtime_dependency 'state_machine'

  s.add_development_dependency 'rspec', ["~> 2.11"]
end
