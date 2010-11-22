class Arduino < Rufirmata::Board
  def initialize(serial_port_id)
    super(serial_port_id, :board_type=>:arduino)
  end
end
