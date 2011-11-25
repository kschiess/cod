module Cod
  # A select group is a special kind of hash, basically. It contains group
  # names as keys (probably symbols) and has either array values or single 
  # object instances. 
  # 
  # A number of operations is defined to make it easier to filter such 
  # hashes during IO.select. The API user only ever gets to see the resulting
  # hash.
  #
  class SelectGroup # :nodoc:
    def initialize(hash_or_value)
      if hash_or_value.respond_to?(:each)
        @h = hash_or_value
        @unpack = false
      else
        @h = {box: hash_or_value}
        @unpack = true
      end
    end
    
    # Returns all values as a single flat array. NOT like Hash#values.
    #
    def values(&block)
      values = []
      block ||= lambda { |e| e } # identity
      
      @h.each do |_,v|
        if v.respond_to?(:to_ary)
          values << v.map(&block)
        else
          values << block.call(v)
        end
      end
      values.flatten
    end
    
    # Keeps values around with their respective keys if block returns true
    # for the values. Deletes everything else. NOT like Hash#keep_if.
    #
    def keep_if(&block)
      old_hash = @h
      @h = Hash.new
      old_hash.each do |key, values|
        # Now values is either an Array like structure that we iterate 
        # on or it is a single value. 
        if values.respond_to?(:to_ary)
          ary = values.select { |e| block.call(e) }
          @h[key] = ary unless ary.empty?
        else
          value = values
          @h[key] = value if block.call(value)
        end
      end
      
      self
    end
    
    # EXACTLY like Hash#keys.
    def keys
      @h.keys
    end

    # Converts this to a result value. If this instance was constructed with a 
    # simple ruby object, return the object. Otherwise return the resulting
    # hash.
    #
    def unpack
      if @unpack
        @h[:box]
      else
        @h
      end
    end
    
    # Returns something that will represent the empty result to our client. 
    # If this class was constructed with just a single object, the empty 
    # result is nil. Otherwise the empty result is an empty hash. 
    #
    def empty
      if @unpack
        nil
      else
        {}
      end
    end
  end
end