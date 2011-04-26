module Cod
  # Wraps the lower level beanstalk connection and exposes only methods that
  # we need; also makes tube handling a bit more predictable. 
  #
  class Connection::Beanstalk
    # The url that was used to connect to the beanstalk server. 
    attr_reader :url
    
    # Connection to the beanstalk server. 
    attr_reader :connection
    
    def initialize(url)
      @url = url
      @connection = Beanstalk::Connection.new(url)
    end
    
    # Writes a raw message as a job to the tube given by name. 
    #
    def put(name, message)
      connection.use name
      connection.put message
    end
    
    # Returns true if there are jobs waiting in the tube given by 'name'
    def waiting?(name)
      watch(name) do  
        !! connection.peek_ready
      end
    end
    
    # Removes and returns the next message waiting in the tube given by name.
    #
    def get(name)
      watch(name) do
        job = connection.reserve
        job.delete
        
        job.body
      end
    end
    
    # Closes the connection
    #
    def close
      @connection = nil
    end
    
  private
    def watch(name)
      connection.watch(name)
      yield
    ensure
      connection.ignore(name)
    end
  end
end