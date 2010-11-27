module Rufirmata
  #A Pin representation
  class Pin
    include Observables::Base

    attr_reader :board, :pin_number, :pin_type, :mode, :port, :pwm, :reporting, :value

    def initialize(board,pin_number,pin_type,port = nil)
      @board = board
      @port = port
      @pin_number = pin_number
      @pin_type = pin_type
      @reporting = false
      @value = nil
      @pwm = false
      @mode = Rufirmata::INPUT
      if pin_type == Rufirmata::DIGITAL
        @pwm = board.board_type[:pwm_pins].include?(pin_number)
        @mode = board.board_type[:disabled_pins].include?(pin_number) ?
        Rufirmata::UNAVAILABLE : Rufirmata::OUTPUT
      end
    end

    def to_s
      type = self.pin_type == Rufirmata::ANALOG ? "Analog" : "Digital"
      "#{type} pin #{pin_number}"
    end


    # Set the mode of operation for the pin
    # Can be one of the pin modes: INPUT, OUTPUT, ANALOG or PWM
    def mode=(mode)
      #Can be Rufirmata::INPUT, OUTPUT, ANALOG, PWM or UNAVAILABLE
      return if @mode == mode #Nothing is changing, so nothing to do

      raise "#{to_s} does not have PWM capabilities" if mode == Rufirmata::PWM and !pwm
      raise "#{to_s} cannot be used through Firmata" if @mode == Rufirmata::UNAVAILABLE

      changing :pin_mode_changed, :changes=>{ :from=>@mode, :to=>mode } do
        @mode = mode
        unless mode == Rufirmata::UNAVAILABLE
          board.write_command(Rufirmata::SET_PIN_MODE, pin_number, mode)
          enable_reporting if mode == Rufirmata::INPUT
        end
      end

    end

    def reporting=(reporting)
      return if @reporting == reporting
      changing :reporting_changed, :changes=>{ :from=>@reporting, :to=>reporting } do
        @reporting = reporting
      end
    end

    def value=(new_value)
      return if @value == new_value
      changing :value_changed, :changes=>{  :from=>@value, :to=>new_value } do
        @value = new_value
      end
    end

    #Set an input pin to report values
    def enable_reporting
      raise "#{to_s} is not an input and therefore cannot report" unless mode == Rufirmata::INPUT
      if pin_type == Rufirmata::ANALOG
        self.reporting = true
        board.write_command(Rufirmata::REPORT_ANALOG + pin_number, 1)
      elsif port
        port.enable_reporting
      end
    end

    # Disable the reporting of an input pin
    def disable_reporting
      if pin_type == Rufirmata::ANALOG
        @reporting = false
        board.write_command(Rufirmata::REPORT_ANALOG + pin_number, 0)
      elsif port
        port.disable_reporting
      end
    end

    #Returns the output value of the pin. This value is updated by the
    #boards `Board.iterate` method. Value is always in the range 0.0 - 1.0
    def read
      raise "Cannot read pin #{to_s} because it is marked as UNAVAILABLE" if mode == Rufirmata::UNAVAILABLE
      value
    end

    #Output a voltage from the pin
    #
    #   :arg value: Uses value as a boolean if the pin is in output mode, or
    #       expects a float from 0 to 1 if the pin is in PWM mode.
    def write(new_value)
      raise "#{to_s} cannot be used through Firmata" if mode == Rufirmata::UNAVAILABLE
      raise "#{to_s} is set up as an INPUT and therefore cannot be written to" if mode == Rufirmata::INPUT
      if (new_value != value)
        @value = new_value
        if mode == Rufirmata::OUTPUT
          port ? port.write() :
            board.write_command(Rufirmata::DIGITAL_MESSAGE, pin_number, value)
        elsif mode == Rufirmata::PWM
          val = (@value * 255).to_i
          board.write_command(Rufirmata::ANALOG_MESSAGE + pin_number, val % 128, val >> 7)
        end
      end
    end #write

    def send_sysex(sysex_cmd, data=[])
      #Sends a SysEx message.
      # :arg sysex_cmd: A sysex command byte
      # :arg data: A list of data values
      board.write_command(Rufirmata::START_SYSEX)
      board.write_command(systex_cmd)
      data.each do |byte|
        byte = begin; byte.chr; rescue RangeError; (byte >> 7).chr; end
        board.write(byte)
      end
      board.write_command(Rufirmata::END_SYSEX)
    end
  end
end
