require 'rubygems'
require 'serialport'
require 'observables'

base_dir = File.dirname(__FILE__)
[
 'version',
 'extensions',
 'pin',
 'port',
 'board',
 'arduino'
].each {|req| require File.join(base_dir,'rufirmata',req)}

module Rufirmata
   # Message command bytes - straight from Firmata.h
  DIGITAL_MESSAGE = 0x90      # send data for a digital pin
  ANALOG_MESSAGE = 0xE0       # send data for an analog pin (or PWM)
  DIGITAL_PULSE = 0x91        # SysEx command to send a digital pulse

  # PULSE_MESSAGE = 0xA0      # proposed pulseIn/Out msg (SysEx)
  # SHIFTOUT_MESSAGE = 0xB0   # proposed shiftOut msg (SysEx)
  REPORT_ANALOG = 0xC0        # enable analog input by pin #
  REPORT_DIGITAL = 0xD0       # enable digital input by port pair
  START_SYSEX = 0xF0          # start a MIDI SysEx msg
  SET_PIN_MODE = 0xF4         # set a pin to INPUT/OUTPUT/PWM/etc
  END_SYSEX = 0xF7            # end a MIDI SysEx msg
  REPORT_VERSION = 0xF9       # report firmware version
  SYSTEM_RESET = 0xFF         # reset from MIDI
  QUERY_FIRMWARE = 0x79       # query the firmware name

  # extended command set using sysex (0-127/0x00-0x7F)
  # 0x00-0x0F reserved for user-defined commands */
  SERVO_CONFIG = 0x70         # set max angle, minPulse, maxPulse, freq
  STRING_DATA = 0x71          # a string message with 14-bits per char
  SHIFT_DATA = 0x75           # a bitstream to/from a shift register
  I2C_REQUEST = 0x76          # send an I2C read/write request
  I2C_REPLY = 0x77            # a reply to an I2C read request
  I2C_CONFIG = 0x78           # config I2C settings such as delay times and power pins
  REPORT_FIRMWARE = 0x79      # report name and version of the firmware
  SAMPLING_INTERVAL = 0x7A    # set the poll rate of the main loop
  SYSEX_NON_REALTIME = 0x7E   # MIDI Reserved for non-realtime messages
  SYSEX_REALTIME = 0x7F       # MIDI Reserved for realtime messages


  # Pin modes.
  # except from UNAVAILABLE taken from Firmata.h
  UNAVAILABLE = -1
  INPUT = 0          # as defined in wiring.h
  OUTPUT = 1         # as defined in wiring.h
  ANALOG = 2         # analog pin in analogInput mode
  PWM = 3            # digital pin in PWM output mode

  # Pin types
  DIGITAL = OUTPUT   # same as OUTPUT below
  # ANALOG is already defined above

  BOARD_TYPES = {
    :arduino => {
      :digital_pins => (0..13).to_a,
      :analog_pins => (0..5).to_a,
      :pwm_pins => [3, 5, 6, 9, 10, 11],
      :use_ports => true,
      :disabled_pins => [0, 1, 14, 15] #Rx, Tx, Crystal
    },
    :arduino_mega => {
      :digital_pins => (0..53).to_a,
      :analog_pins => (0..15).to_a,
      :pwm_pints => (2..14).to_a,
      :use_ports => true,
      :disabled_pins => [0, 1, 14, 15] #Rx, Tx, Crystal
    }
  }

  class << self
    attr_reader :serial_ports

    def create_serial_port(options={})
      @serial_ports ||= {}
      options = {
        :serial_port => "/dev/ttyUSB0",
        :baud_rate => 57600,
        :parity => SerialPort::NONE,
        :data_bits => 8,
        :stop_bits => 1
      }.merge(options)

      sp = options[:serial_port]
      @serial_ports[options] =
        SerialPort.new(sp,
                       options[:baud_rate],
                       options[:data_bits],
                       options[:stop_bits],
                       options[:parity])
    end

  end

end
