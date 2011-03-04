
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
  
  def initialize
    @backend = Cod.backend(:default).anonymous
  end
  
  # Writes a message to the mailbox. This will never block. 
  #
  def write(message)
    @backend.write(message)
  end
  
  # Returns true when the mailbox has messages waiting to be delivered. 
  #
  def data_waiting?
    @backend.data_waiting?
  end
  
  # Mainly for rspec and people who like to type.
  #
  alias has_data_waiting? data_waiting?

  # Returns one message from the mailbox.
  #
  def read
    @backend.read
  end
end