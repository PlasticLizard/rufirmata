require 'rubygems'

$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'rufirmata'
require 'rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
Dir["#{File.dirname(__FILE__)}/stubs/**/*.rb"].each {|f| require f}

require 'rspec/expectations'

RSpec::Matchers.define :have_received_bytes do |*expected|
  match do |actual|
    res = actual.read()
    serial_msg = res
    until res.nil? or res.empty?
      res = actual.read()
      serial_msg += res
    end
    expected = expected.map{|b|b.chr}.join('')
    actual.instance_eval "def last_received; '#{serial_msg.inspect}'; end"
    expected == serial_msg
  end
  failure_message_for_should do |actual|
    "expected to receive #{expected.inspect} but received #{actual.last_received}"
  end
end

Rspec.configure do |config|
  # == Mock Framework

  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.before(:each) do

  end

end
