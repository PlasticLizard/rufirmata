module Rufirmata
  #An 8-bit port on the board
  class Port

    attr_reader :board, :port_number, :pins
    attr_accessor :reporting

    def initialize(board, port_number)
      @board = board
      @port_number = port_number
      @reporting = false
      @pins = []
      (0..7).each do |pin|
        pin_num = pin + port_number * 8
        pins << (pin = Rufirmata::Pin.new(board, pin_num, Rufirmata::DIGITAL, self))
        board.digital << pin
      end
    end

    def to_s; "Digital Port #{port_number}"; end

    #Enable reporting of values for the whole port
    def enable_reporting
      @reporting = true
      board.write_command(Rufirmata::REPORT_DIGITAL + port_number, 1)
      pins.each {|pin|pin.reporting = true}
    end

    #Disable reporting of values for the whole port
    def disable_reporting
      @reporting = false
      board.write_command(Rufirmata::REPORT_DIGITAL + port_number, 0)
    end

    #Set the output pins of the port to the correct state
    def write
      mask = 0
      pins.each do |pin|
        if (pin.mode == Rufirmata::OUTPUT)
          if (pin.value == 1)
            pin_nr = pin.pin_number - port_number * 8
            mask |= 1 << pin_nr
          end
        end
      end
      board.write_command(Rufirmata::DIGITAL_MESSAGE + port_number, mask % 128, mask >> 7)
    end

    #Update the values for the pins marked as input with the mask
    def update(mask)
      if reporting
        pins.each do |pin|
          if pin.mode == Rufirmata::INPUT
            pin_nr = pin.pin_number - port_number * 8
            pin.value = (mask & (1 << pin_nr)) > 1
          end
        end
      end
    end

  end
end
