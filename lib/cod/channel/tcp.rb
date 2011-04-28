module Cod
  module Channel::TCP
    def split_uri(uri)
      colon = uri.index(':')
      raise ArgumentError, 
        "TCP points must include a port number, #{uri.inspect} does not." \
        unless colon
      
      [
        colon == 0 ? nil : uri[0...colon], 
        Integer(uri[colon+1..-1])]
    end
  end
end