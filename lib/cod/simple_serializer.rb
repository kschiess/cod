module Cod
  class SimpleSerializer
    def en(obj)
      Marshal.dump(obj)
    end
    
    def de(io, context=nil)
      Marshal.load(io)
    end
  end
end