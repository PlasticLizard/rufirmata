require 'rubygems'
require 'serialport'

base_dir = File.dirname(__FILE__)
[
 'version'
].each {|req| require File.join(base_dir,'rufirmata',req)}

module Rufirmata
end
