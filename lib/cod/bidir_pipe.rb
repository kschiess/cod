module Cod
  class BidirPipe < Channel
    # The Cod::Pipe instance we're currently #put'ting to. 
    attr_reader :w
    # The Cod::Pipe instance we're currently #get'ting from. 
    attr_reader :r
    
    def initialize(serializer=nil, pipe_pair=nil)
      @serializer = serializer || SimpleSerializer.new
      @r, @w = pipe_pair || [Cod.pipe(@serializer), Cod.pipe(@serializer)]
    end
    
    def put(msg)
      w.put(msg)
    end
    
    def get
      r.get
    end
    
    def close
      r.close
      w.close
    end
    
    # Swaps the end of this pipe around. 
    #
    def swap!
      @r, @w = w, r
    end
  end
end