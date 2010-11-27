# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'rufirmata/version'

Gem::Specification.new do |s|
  s.name         = "rufirmata"
  s.version      = Rufirmata::VERSION
  s.authors      = ["Nathan Stults"]
  s.email        = "hereiam@sonic.net"
  s.homepage     = "http://github.com/PlasticLizard/rufirmata"
  s.summary      = "A ruby firmata client for interfacing with microcontollers running firmata compatible firmware"
  s.description  = "A Ruby port of pyFirmata, software for interfacing with firmata-enabled microcontrollers"

  s.files = Dir.glob("{lib,spec}/**/*") + %w[LICENSE README.rdoc]
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency "ruby-serialport"
  s.add_dependency "observables"

  s.add_development_dependency 'rspec', '~> 2.1'
  s.add_development_dependency 'fuubar'
end
