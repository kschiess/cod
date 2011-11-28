module Cod
  # The simplest of all serializers, one that uses Marshal.dump and
  # Marshal.load as a message format. Use this as a template for your own wire
  # format serializers.
  #
  class SimpleSerializer
    def en(obj)
      Marshal.dump(obj)
    end
    
    def de(io)
      if block_given?
        Marshal.load(io, Proc.new)
      else
        Marshal.load(io)
      end
    end
  end
end