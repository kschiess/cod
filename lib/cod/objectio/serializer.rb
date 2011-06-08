module Cod::ObjectIO
  class Serializer
    attr_reader :transformer
    
    def initialize(transformer)
      @transformer = transformer
    end
    
    # NOTE: source_io is provided to be able to provide back-channels through
    # that same, not to read from it. Reading from this IO object will block
    # you. 
    #
    def deserialize(source_io, buffer_io)
      Marshal.load(buffer_io, proc { 
        |obj| transformer.transform(source_io, obj) }) 
    end
    
    def serialize(message)
      Marshal.dump(message)
    end
  end
end