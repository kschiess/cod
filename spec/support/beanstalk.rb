module BeanstalkHelper
  # Ok, this is a mess, I admit it. I wrote it, and I will fix it, ok?
  #
  # Clears a beanstalk tube given by name, DELETING all jobs that remain in
  # that tube. 
  #
  def clear_tube(name, server='localhost:11300')
    beanstalk = Cod.tcp(server, Cod::Beanstalk::Serializer.new)

    # 'enhance' the tcp channel
    class << beanstalk
      def cmd(*cmd)
        put cmd
        code, *rest = get

        fail "beanstalk_cmd detected failure: #{code.inspect}" \
          unless [:watching, :ok, :reserved, :deleted].include?(code)

        [code, *rest]
      end
    end
    
    beanstalk.cmd :watch, name
    last_ready = nil
    loop do
      # Get how many jobs are waiting: 
      code, *rest = beanstalk.cmd :'stats-tube', name
      stats = YAML.load(rest.first)
      
      ready = stats['current-jobs-ready']
      break if ready == 0
      
      if last_ready && ready != last_ready-1
        fail "#clear_tube seems to be failing"
      end
      last_ready = ready
      
      code, *rest = beanstalk.cmd :reserve
      id, (*) = rest
      beanstalk.cmd :delete, id
    end
    
  ensure
    beanstalk.close
  end
end