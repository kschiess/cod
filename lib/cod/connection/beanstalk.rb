module Cod
  # Wraps the lower level beanstalk connection and exposes only methods that
  # we need; also makes tube handling a bit more predictable. 
  #
  # This class is NOT thread safe.
  #
  class Connection::Beanstalk
    # The url that was used to connect to the beanstalk server. 
    attr_reader :url
    
    # Connection to the beanstalk server. 
    attr_reader :connection
    
    def initialize(url)
      @url = url
      connect
    end
    
    def initialize_copy(from)
      @url = from.url
      connect
    end
    
    # Writes a raw message as a job to the tube given by name. 
    #
    def put(name, message)
      connection.use name
      # TODO throws EOFError when the beanstalkd server goes away
      connection.put message
    end
    
    # Returns true if there are jobs waiting in the tube given by 'name'
    def waiting?(name)
      connection.stats_tube(name)['current-jobs-ready'] > 0
    rescue Beanstalk::NotFoundError
      # Tube could not be found. No one has written to it! Nothing is waiting.
      false
    end
    
    # Removes and returns the next message waiting in the tube given by name.
    #
    def get(name, opts={})
      watch(name) do
        job = connection.reserve(opts[:timeout])
        job.delete
        
        job.body
      end
    end
    
    # Closes the connection
    #
    def close
      connection.close
      @connection = nil
    end
    
    # Creates a connection 
    # 
    def connect
      # TODO throws Errno::ECONNREFUSED if the beanstalkd doesn't answer
      @connection = Beanstalk::Connection.new(url)
      @watching = nil
    end
  private
    def watch(name)
      unless @watching == name
        connection.ignore(@watching)
        connection.watch(name)
        @watching = name
      end
      
      yield
    end
  end
end