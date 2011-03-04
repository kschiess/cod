
# A mailbox that you can stuff messages into and that on the other end, you
# can read messages from. 
#
class Cod::Mailbox
  class << self # class methods
    # Produces an anonymous mailbox. 
    #
    def anonymous
      new
    end
  end
  
  # Writes a message to the mailbox. This will never block. 
  #
  def write(message)
  end
  
  # Returns true when the mailbox has messages waiting to be delivered. 
  #
  def data_waiting?
    true
  end
  
  # Mainly for rspec and people who like to type.
  #
  alias has_data_waiting? data_waiting?

  def read
    'foo'
  end
end