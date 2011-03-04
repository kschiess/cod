class Cod::Backends::Pipe::Factory
  def anonymous
    Cod::Backends::Pipe::Mailbox.new
  end
end