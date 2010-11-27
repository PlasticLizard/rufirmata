require "spec_helper"

describe Rufirmata::Board do
  before(:each) do
    Rufirmata.stub(:create_serial_port) {  FakeSerial.new }
    @board = Rufirmata::Board.new("/dev/ttyUSB0")
  end

  describe "handlers" do
    it "should return nil for a failed analog read" do
      @board.analog[3].reporting = true
      @board.analog[3].read.should be_nil
    end

    # This sould set it correctly. 1023 (127, 7 in to 7 bit bytes) is the
    # max value an analog pin will send and it should result in a value 1
    it "should handle an analog message" do
      @board.analog[3].reporting = true
      @board.send(:handle_analog_message,3,127,7)
      @board.analog[3].read.should == 1.0
    end

    # A digital message sets the value for a whole port. We will set pin
    # 5 (That is on port 0) to 1 to test if this is working.
    it "should handle a digital message" do
      @board.digital_ports[0].reporting = true
      @board.digital[5].mode = Rufirmata::INPUT
      mask = 0
      mask |= 1 << 5  # set the bit for pin 5 to to 1
      @board.digital[5].read.should be_nil
      @board.send(:handle_digital_message, 0, mask % 128, mask >> 7)
      @board.digital[5].read.should be_true
    end

    it "should handle report version" do
      @board.firmata_version.should be_nil
      @board.send(:handle_report_version,2,1)
      @board.firmata_version.should == [2,1]
    end

    it "should handle report firmware" do
      @board.firmware.should be_nil
      data  = [2,1]
      "Firmware_name".each_byte { |b|data << b}
      @board.send(:handle_report_firmware,*data)
      @board.firmware.should == 'Firmware_name'
      @board.firmata_version.should == [2,1]
    end

    # type                command  channel    first byte            second byte
    # ---------------------------------------------------------------------------
    # analog I/O message    0xE0   pin #      LSB(bits 0-6)         MSB(bits 7-13)
    describe "incoming analog message" do
      it "should ignore incoming data when reporting=false" do
        @board.serial_port.write_as_chars Rufirmata::ANALOG_MESSAGE + 4, 127, 7
        @board.iterate()
        @board.analog[4].read.should be_nil
      end

      it "should set incoming data on the pin value when reporting=true" do
        @board.analog[4].enable_reporting
        @board.serial_port.clear
        @board.serial_port.write_as_chars Rufirmata::ANALOG_MESSAGE + 4, 127, 7
        @board.iterate
        @board.analog[4].read.should == 1.0
      end
    end

    # type                command  channel    first byte            second byte
    # ---------------------------------------------------------------------------
    # digital I/O message   0x90   port       LSB(bits 0-6)         MSB(bits 7-13)
    describe "incoming digital message" do
      it "should set incoming digital data for input pins" do
        @board.digital[9].mode = Rufirmata::INPUT
        @board.serial_port.clear
        mask = 0; mask |= 1 << (9 - 8) #set the bit for pin 9 to 1
        @board.digital[9].read.should be_nil
        @board.serial_port.write_as_chars Rufirmata::DIGITAL_MESSAGE + 1, mask % 128, mask >> 7
        @board.iterate
        @board.digital[9].read.should be_true
      end
    end

    # version report format
    # -------------------------------------------------
    # 0  version report header (0xF9) (MIDI Undefined)
    # 1  major version (0-127)
    # 2  minor version (0-127)
    describe "incoming report version" do
      it "should set the firmata version" do
        @board.serial_port.write_as_chars Rufirmata::REPORT_VERSION, 2, 1
        @board.iterate
        @board.firmata_version.should == [2,1]
      end
    end

    # Receive Firmware Name and Version (after query)
    # 0  START_SYSEX (0xF0)
    # 1  queryFirmware (0x79)
    # 2  major version (0-127)
    # 3  minor version (0-127)
    # 4  first 7-bits of firmware name
    # 5  second 7-bits of firmware name
    # x  ...for as many bytes as it needs)
    # 6  END_SYSEX (0xF7)
    describe "incoming report firmware" do
      before(:each) do
        @board.serial_port.write_as_chars Rufirmata::START_SYSEX, Rufirmata::REPORT_FIRMWARE, 2, 1
        @board.serial_port.write 'Firmware_name'.split(//)
        @board.serial_port.write_as_chars Rufirmata::END_SYSEX
        @board.iterate
      end
      it "should have set the appropriate firmware name" do
        @board.firmware.should == 'Firmware_name'
      end
      it "should have set the firmata version" do
        @board.firmata_version.should == [2,1]
      end
    end

    # type                command  channel    first byte            second byte
    # ---------------------------------------------------------------------------
    # report analog pin     0xC0   pin #      disable/enable(0/1)   - n/a -
    describe "report analog" do
      it "should write an enable reporting command to the serial port" do
        @board.analog[1].enable_reporting
        @board.serial_port.should have_received_bytes( 0xC0 + 1, 1 )
        @board.analog[1].reporting.should be_true
      end
      it "should write a disable reporting command to the serial port" do
        @board.analog[1].reporting = true
        @board.analog[1].disable_reporting
        @board.serial_port.should have_received_bytes( 0xC0 + 1, 0 )
        @board.analog[1].reporting.should be_false
      end
    end

    # type                command  channel    first byte            second byte
    # ---------------------------------------------------------------------------
    # report digital port   0xD0   port       disable/enable(0/1)   - n/a -
    describe "report digital" do
      before(:each){ @board.digital[8].mode = Rufirmata::INPUT; @board.serial_port.clear }
      # This should enable reporting of whole port 1
      it "should write an enable reporting command for the port" do
        @board.digital[8].enable_reporting
        @board.serial_port.should have_received_bytes( 0xD0 + 1, 1 )
        @board.digital[8].reporting.should be_true
      end

      it "should write a disable reporting command for the port" do
        @board.digital[8].reporting = true
        @board.digital[8].disable_reporting
        @board.serial_port.should have_received_bytes( 0xD0 + 1, 0 )
      end
    end

    # Generic Sysex Message
    # 0     START_SYSEX (0xF0)
    # 1     sysex command (0x00-0x7F)
    # x     between 0 and MAX_DATA_BYTES 7-bit bytes of arbitrary data
    # last  END_SYSEX (0xF7)
    describe "SYSEX" do
      it "should send a sysex message" do
        @board.send_sysex 0x79, [1,2,3]
        @board.serial_port.should have_received_bytes 0xF0, 0x79, 1, 2, 3, 0xF7
      end

      it "should receive a sysex message" do
        @board.serial_port.write [0xF0, 0x79, 2, 1, 'a'[0], 'b'[0], 'c'[0], 0xF7].map{ |b|b.chr}
        while @board.serial_port.length > 0
          @board.iterate
        end
        @board.firmata_version.should == [2,1]
        @board.firmware.should == 'abc'
      end
    end

    describe "sending extraneous data" do
      it "should be ignored" do
        @board.analog[4].enable_reporting
        @board.serial_port.clear
        #Garbage
        @board.serial_port.write_as_chars( *(0..10).to_a )
        #Set analog port 4 to 1
        @board.serial_port.write_as_chars Rufirmata::ANALOG_MESSAGE + 4, 127, 7
        #More garbage
        @board.serial_port.write_as_chars( *(0..10).to_a )
        while @board.serial_port.length > 0
          @board.iterate
        end
        @board.analog[4].read.should == 1.0
      end
    end

    describe "notifications" do
      before :each do
        @changes = []
        @board.subscribe do |type,args|
          @changes << [type,args]
        end
      end


      describe "when a pin is changed" do
        before(:each){@board.analog[0].value = 1.1}

        it "should issue before and after change notifications" do
          @changes.length.should == 2
          @changes[0][0].should == :before_value_changed
          @changes[1][0].should == :after_value_changed
        end

        it "should pass the pin in the event args" do
          @changes[0][1][:pin].should == @board.analog[0]
        end

        it "should provide the previous and new values of the pin" do
          @changes.each do |c|
            c[1][:changes].should == { :from=>nil, :to=>1.1}
          end
        end

      end
    end
  end

end

