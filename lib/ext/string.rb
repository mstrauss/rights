class String
  
  def is_oct?
    "%o" % [self.oct] == self
  end
  
end
