
 #   A Mock object for ruby's Serial. Functions as a fifo-stack. Push to
 #   it with ``write``, read from it with ``read``.
 #
 #   >>> s = Serial.new('someport', 4800)
 #   >>> s.read()
 #   ''
 #   >>> s.write(chr(100))
 #   >>> s.write('blaat')
 #   >>> s.write(100000)
 #   >>> s.read(2)
 #   ['d', 'blaat']
 #   >>> s.read()
 #   100000
 #   >>> s.read()
 #   ''
 #   >>> s.read(2)
 #   ['', '']
 #   >>> s.close()
class FakeSerial < Array

  def getc
    read[0]
  end

  def read(count=1)
    if count > 1
      val = []
      [i..count].each do |i|
          val << (shift || '')
      end
    else
      val = (shift || '')
    end
    val
  end

  def write(value)
    (self << value).flatten!
  end

  def write_as_chars(*vals)
    write vals.map{ |v| v.chr }
  end

  def close
    clear()
  end

end
