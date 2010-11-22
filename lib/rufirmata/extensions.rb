class Float
  def prec(x)
    sprintf("%.0" + x.to_i.to_s + "f", self).to_f
  end
end
