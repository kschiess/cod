require 'spec_helper'

describe "IPC queue" do
  describe "basic operation" do
    it "like in ipc_queue example" do
      Cod.setup(:default, :method => :pipe)

      mailbox = Cod::Mailbox.anonymous

      mailbox.write('foo')
      mailbox.write('bar')

      mailbox.should be_waiting
      mailbox.read.should == 'foo'
      mailbox.read.should == 'bar'
      
      mailbox.should_not be_waiting
    end 
  end
end