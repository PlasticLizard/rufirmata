require "spec_helper"

describe Rufirmata::Pin do
  before(:each) do
    Rufirmata.stub(:create_serial_port) {  FakeSerial.new }
    @board = Rufirmata::Board.new("/dev/ttyUSB0")
  end

  describe "notifications" do
    before :each do
      @changes = []
      @pin = Rufirmata::Pin.new(@board, 2, Rufirmata::DIGITAL)
      @pin.subscribe do |type, args|
        @changes << [type, args]
      end
    end

    describe "#mode" do
      before(:each) { @pin.mode = Rufirmata::INPUT }

      it "should issue a change notice before and after the change" do
        @changes.count.should == 2
        @changes[0][0].should == :before_pin_mode_changed
        @changes[1][0].should == :after_pin_mode_changed
      end

      it "should notify changes to the pin mode" do
        @changes.each do |c|
          c[1].changes[:from].should == Rufirmata::OUTPUT
          c[1].changes[:to].should == Rufirmata::INPUT
        end
      end

      it "should not issue a notification if nothing changed" do
        @changes.clear
        @pin.mode = Rufirmata::INPUT
        @changes.length.should == 0
      end

    end

    describe "#reporting" do
      before(:each){  @pin.reporting = true }

      it "should issue a change before and after reporting changed" do
        @changes.length.should == 2
        @changes[0][0].should == :before_reporting_changed
        @changes[1][0].should == :after_reporting_changed
      end

      it "should notify changes to reporting" do
        @changes.each do |c|
          c[1].changes[:from].should == false
          c[1].changes[:to].should == true
        end
      end

      it "should not issue a change when not changed" do
        @changes.clear
        @pin.reporting = true
        @changes.length.should == 0
      end
    end

    describe "#reporting" do
      before(:each){  @pin.value = 1 }

      it "should issue a change before and after value changed" do
        @changes.length.should == 2
        @changes[0][0].should == :before_value_changed
        @changes[1][0].should == :after_value_changed
      end

      it "should notify changes to value" do
        @changes.each do |c|
          c[1].changes[:from].should == nil
          c[1].changes[:to].should == 1
        end
      end

      it "should not issue a change when not changed" do
        @changes.clear
        @pin.value = 1
        @changes.length.should == 0
      end
    end

  end
end
