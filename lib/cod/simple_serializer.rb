module Cod
  class SimpleSerializer
    def serialize(obj)
      Marshal.dump(obj)
    end
    
    def deserialize(io)
      Marshal.load(io)
    end
  end
end