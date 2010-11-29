module Rufirmata

  class Board
    include Observables::Base

    attr_reader :serial_port, :name, :analog, :digital, :digital_ports, :board_type,
    :taken,:firmata_version,:firmware, :listening

    def initialize(serial_port, options={})
      options[:serial_port] = serial_port
      @serial_port ||= Rufirmata.create_serial_port(options)
      @name = options[:name] || serial_port
      @board_type =
        case options[:board_type]
        when Hash : options[:board_type]
        when Symbol : Rufirmata::BOARD_TYPES[options[:board_type]]
        else Rufirmata::BOARD_TYPES[:arduino]
        end
      @taken = { :analog => { }, :digital =>{ } }
      @listening = false
      initialize_layout
      #This is critical. Sending commands before the board is ready will lock it up.
      sleep 2
    end

    def to_s
      "Board #{name} on #{serial_port}"
    end

    def write_command(*commands)
      message = commands.shift.chr
      commands.each { |command| message += command.chr }
      @serial_port.write(message)
    end

    def write(data)
      @serial_port.write(data)
    end

    #    Sends a SysEx msg.
    #    :arg sysex_cmd: A sysex command byteggg
    #    :arg data: A list of data values
    def send_sysex(sysex_cmd, data=[])
      write_command Rufirmata::START_SYSEX
      write_command sysex_cmd
      data.each do |b|
        begin
          byte = b.chr
        rescue
          byte = (b >> 7).chr
        end#TODO send multiple bytes
        write(byte)
      end
      write_command Rufirmata::END_SYSEX
    end

    def close
      @listening = false
      @serial_port.close()
    end
    alias stop close

    def start_listening
      @listening = true
      @listener = Thread.new do
        while @listening
          begin
            iterate
            sleep 0.001
          rescue Exception => e
            puts e.message
            puts e.backtrace.inspect
          end
        end
      end
    end


    # Reads and handles data from the microcontroller over the serial port.
    #This method should be called in a main loop, or in an
    #:class:`Iterator` instance to keep this boards pin values up to date
    def iterate
      data = @serial_port.getc
      return unless data

      received_data = []

      if data < Rufirmata::START_SYSEX
        command = data & 0xF0
        handler = find_handler(command)
        return unless handler
        received_data << (data & 0x0F)
        while received_data.length < method(handler).arity
          received_data << @serial_port.getc
        end

      elsif data == Rufirmata::START_SYSEX

        data = @serial_port.getc
        handler = find_handler(data)
        return unless handler
        data = @serial_port.getc
        while data != Rufirmata::END_SYSEX
          received_data << data
          data = @serial_port.getc
        end

      else
        handler = find_handler(data)
        return unless handler
        while received_data.length < method(handler).arity
          received_data << @serial_port.getc
        end
      end

      send(handler,*received_data) if handler

    end

    private

    def find_handler(command)
      case command
      when Rufirmata::ANALOG_MESSAGE  : :handle_analog_message
      when Rufirmata::DIGITAL_MESSAGE : :handle_digital_message
      when Rufirmata::REPORT_VERSION  : :handle_report_version
      when Rufirmata::REPORT_FIRMWARE : :handle_report_firmware
      else return
      end
    end

    def handle_analog_message(pin_number, lsb, msb)
      value = (((msb << 7) + lsb).to_f / 1023).prec(4)
      self.analog[pin_number].value = value if self.analog[pin_number].reporting
    end

    #Digital messages always go by the whole port. This means we have a
    # bitmask wich we update the port.
    def handle_digital_message(port_number, lsb, msb)
      mask = (msb << 7) + lsb
      self.digital_ports[port_number].update(mask) if self.digital_ports[port_number]
    end

    def handle_report_version(major, minor)
      @firmata_version = [major,minor]
    end

    def handle_report_firmware(*data)
      major = data.shift
      minor = data.shift
      @firmata_version = [major,minor]
      # TODO this is more complicated, values is send as 7 bit bytes
      @firmware = data.map{|byte|byte.chr}.join('')
    end

    def initialize_layout
      @analog, @digital, @digital_ports  = [], [], []

      @board_type[:analog_pins].each do |pin|
        @analog << Rufirmata::Pin.new(self, pin, Rufirmata::ANALOG)
      end

      digital_pins = @board_type[:digital_pins]

      if @board_type[:use_ports]
        (0...digital_pins.length/7).each  { |port| @digital_ports << Port.new(self, port)}
      else
        (0..digital_pins).each do |pin|
          @digital << Rufirmata::Pin.new(self, pin, Rufirmata::DIGITAL)
        end
      end

      (@digital + @analog).each do |pin|
        pin.set_observer do |sender, type, args|
          notifier.publish type, args.merge(:pin=>sender)
        end
      end

    end #init layout


  end #board

end #rufirmata
