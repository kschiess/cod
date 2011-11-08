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
  
  # Performs an IO.select on a list of file descriptors and Cod channels. 
  # Construct this like so: 
  #   Select.new(
  #     0.1,                    # timeout
  #     foo: single_fd,         # a single named FD
  #     bar: [one, two, three], # a group of FDs.
  #   )
  #
  class Select
    attr_reader :timeout
    attr_reader :groups
    
    def initialize(timeout, groups)
      @timeout = timeout
      @groups = SelectGroup.new(groups)
    end
    
    # Performs the IO.select and returns a thinned out version of that initial
    # groups, containing only FDs and channels that are ready for reading. 
    #
    def do
      fds = groups.values { |e| to_read_fd(e) }
      
      # Perform select  
      r,w,e = IO.select(fds, nil, nil, timeout)

      # Nothing is ready if r is nil
      return groups.empty unless r
      
      # Prepare a return value: The original hash, where the fds are ready.
      groups.
        keep_if { |e| r.include?(to_read_fd(e)) }.
        unpack
    end
  private
    def to_read_fd(single)
      return single.to_read_fds if single.respond_to?(:to_read_fds)
      return single
    end
  end
end