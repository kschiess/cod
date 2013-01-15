module Cod
  module Callbacks
    def using_callbacks(*args)
      Thread.current[:callbacks] = []
      
      result = yield
      
      Thread.current[:callbacks].each do |cb|
        cb.call(*args)
      end
      
      return result
    ensure
      Thread.current[:callbacks] = nil
    end
    
    def callbacks_enabled?
      Thread.current[:callbacks]
    end
    def register_callback(&block)
      Thread.current[:callbacks] << block
    end
  end
end
