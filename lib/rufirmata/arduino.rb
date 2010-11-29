class Arduino < Rufirmata::Board
  def initialize(serial_port_id, options={})
    super(serial_port_id, options.merge(:board_type=>:arduino))
    start_listening unless options[:auto_start] == false
  end
end
