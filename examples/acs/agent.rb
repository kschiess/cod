
require 'cod'

name = ARGV.first


class ServiceClass
  def announce(str)
    @@n ||= 0
    @@n += 1
    # NOP
    
    print '.' if @@n % 10 == 0
    if @@n % 100 == 0
      if defined?(@@l) 
        puts 100.0 / (Time.now - @@l)
      end
      
      @@l = Time.now
    end
  end
end

class Agent
  attr_reader :connection
  attr_reader :name
  attr_reader :url
  
  def initialize(name, url, &factory)
    @name, @url = name, url
    @factory = factory
    
    connect
  end
  
  def connect
    @connection = Cod.tcp(@url)
    
    connection.put [:join, name, @connection]
  end
  
  def run
    loop do
      dispatch_commands
    end
  end
  def dispatch_commands
    while connection.waiting?
      cmd, *rest = connection.get
      case cmd
        when :rpc
          msg, args = *rest
          begin
            instance = @factory.call
            instance.send(msg, args)
          rescue => ex
            p ex
          end
      else 
        puts "unknown: #{cmd.inspect}, #{rest.inspect}"
      end
    end
  end
end

agent = Agent.new(name, 'localhost:12345') { ServiceClass.new }
agent.run

