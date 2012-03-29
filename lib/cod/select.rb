module Cod
  # A shortcurt for constructing a {Select}. See {Select#do} for more
  # information.
  #
  # @param timeout [Number] seconds to block before giving up
  # @param groups channels or io selectors to wait for
  # @return [Hash,Array,Cod::Channel,IO]
  # 
  def select(timeout, groups)
    # TODO create an overload without the timeout
    Select.new(timeout, groups).do
  end
  module_function :select
  
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
    # @return [Hash,Array,Cod::Channel,IO]
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