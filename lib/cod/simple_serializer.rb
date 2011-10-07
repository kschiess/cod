module Cod
  class SimpleSerializer
    def en(obj)
      Marshal.dump(obj)
    end
    
    def de(io)
      Marshal.load(io)
    end
  end
end