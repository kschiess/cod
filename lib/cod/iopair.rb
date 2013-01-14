module Cod
  IOPair = Struct.new(:r, :w) do
    def initialize(r=nil, w=nil)
      if r && w
        super(r, w)
      else
        super(*IO.pipe)
      end
    end
    
    # Performs a deep copy of the structure. 
    def initialize_copy(other)
      super
      self.r = other.r.dup if other.r
      self.w = other.w.dup if other.w
    end
    def write(buf)
      raise Cod::ReadOnlyChannel unless w
      w.write(buf)
    end
    def read(serializer)
      raise Cod::WriteOnlyChannel unless r
      serializer.de(r)
    end
    def close
      close_r
      close_w
    end
    def close_r
      r.close if r
      self.r = nil
    end
    def close_w
      w.close if w
      self.w = nil
    end
  end
end