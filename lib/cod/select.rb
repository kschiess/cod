module Cod
  def select(timeout, groups)
    Select.new(timeout, groups).do
  end
  module_function :select
  
  # A select group is a special kind of hash, basically. It contains group
  # names as keys (probably symbols) and has either array values or single 
  # object instances. 
  # 
  # A number of operations is defined to make it easier to filter such 
  # hashes during IO.select. The API user only ever gets to see the resulting
  # hash.
  #
  class SelectGroup
    def initialize(hash)
      @h = hash
    end
    
    # Returns all values as a single flat array. NOT like Hash#values.
    #
    def values
      values = []
      @h.each do |_,v|
        values << v
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
  end
  
  class Select
    attr_reader :timeout
    attr_reader :groups
    
    def initialize(timeout, groups)
      @timeout = timeout
      @groups = groups
    end
    
    def do
      # Gather all file descriptors
      fds = []
      fds = groups.map { |_, v| 
        to_read_fds(v) }.
        flatten
      
      # Perform select  
      r,w,e = IO.select(fds, nil, nil, timeout)

      # Nothing is ready
      return {} unless r
      
      # Prepare a nice return value: The original hash, where the fds are
      # ready.
      groups.inject({}) { |hash, (name, value)| 
        hash[name] = if value.respond_to?(:to_ary)
          value.select { |e| r.include?(to_read_fd(e)) }
        else
          r.include?(to_read_fd(value)) ? value : nil
        end
        
        hash
      }
    end
  private
    def to_read_fds(ary_or_single)
      if ary_or_single.respond_to?(:to_ary)
        return ary_or_single.map { |e| to_read_fd(e) }
      else
        return to_read_fd(ary_or_single)
      end
    end
    def to_read_fd(single)
      return single.to_read_fds if single.respond_to?(:to_read_fds)
      return single
    end
  end
end