# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'rufirmata/version'

Gem::Specification.new do |s|
  s.name         = "rufirmata"
  s.version      = Rufirmata::VERSION
  s.authors      = ["Nathan Stults"]
  s.email        = "hereiam@sonic.net"
  s.homepage     = "http://github.com/PlasticLizard/rufirmata"
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files = Dir.glob("{lib,spec}/**/*") + %w[LICENSE README.rdoc]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency "ruby-serialport"

  s.add_development_dependency 'rspec', '~> 2.1'
  s.add_development_dependency 'fuubar'
end
