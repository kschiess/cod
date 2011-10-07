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
    def values(&block)
      values = []
      block = lambda { |e| e } unless block   # identity
      
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

    # Converts this to a hash.
    #
    def to_hsh
      @h
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

      # Nothing is ready
      return {} unless r
      
      # Prepare a nice return value: The original hash, where the fds are
      # ready.
      groups.keep_if { |e| fds.include?(e) }.to_hsh
    end
  private
    def to_read_fd(single)
      return single.to_read_fds if single.respond_to?(:to_read_fds)
      return single
    end
  end
end