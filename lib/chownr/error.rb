module Chownr
  
  class Error < RuntimeError
    
    def user_info
      "#{self.class}: #{self.message}"
    end
    
  end
  
end
