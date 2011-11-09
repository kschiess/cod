module TransportHelper
  Transport = Struct.new(:name, :init_block) do
    def init
      instance_eval(&init_block)
    end
    
    # Define a DSL method NAME that stores a block for later usage. You can 
    # call the block using VERB_NAME. 
    # 
    # Example: 
    #
    #   # in here
    #   define_block_storage :get, :bread
    #   # and in the definition of a transport: 
    #   bread { return :bread }
    #   # and then later on
    #   transport.get_bread
    def self.define_block_storage(verb, name)
      define_method(name) do |&block|
        @blocks ||= Hash.new
        @blocks[name] = block
      end
      define_method("#{verb}_#{name}") do
        @blocks[name].call
      end
    end

    define_block_storage :get, :server
    define_block_storage :get, :client
    define_block_storage :call, :close
  end
  
  def transport(name, &block)
    Transport.new(name, block)
  end
end