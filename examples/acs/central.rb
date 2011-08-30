
require 'cod'

class Central
  attr_reader :url
  attr_reader :connection
  attr_reader :agents
  
  def initialize(url)
    @url = url
    
    @agents = {}
    
    connect
  end
  
  def run
    loop do
      dispatch_incoming
      
      check_agents
    end
  end

  def dispatch_incoming
    @n ||= 0
    @n += 1
    
    if @n%100 == 0
      if @l
        puts 100.0 / (Time.now-@l)
      end
      
      @l = Time.now
    end
    
    cmd, *rest = connection.get
    case cmd
      when :join
        name, conn = *rest
        agents[name] = conn
        puts "Subscribed #{name}."
      when :rpc
        check_agents
        agents.each { |name, conn| conn.put [:rpc, *rest] }
    else
      puts "unknown: #{cmd.inspect} #{rest.inspect}"
    end
  end

  def check_agents
    unsubscribe = []
    agents.each do |name, conn|
      unless conn.connected?
        puts "Unsubscribed #{name}."
        unsubscribe << name
      end
    end
    
    unsubscribe.each { |name| agents.delete(name) }
  end
  
  def connect
    @connection = Cod.tcpserver(url)
  end
end

central = Central.new('localhost:12345')
central.run