require 'spec_helper'

describe "IPC queue" do
  describe "basic operation" do
    it "like in ipc_queue example" do
      Cod.setup(:default, :method => :pipe)

      mailbox = Cod::Mailbox.anonymous

      mailbox.write('foo')
      mailbox.write('bar')

      mailbox.should have_data_waiting
      mailbox.read.should == 'foo'
      mailbox.read.should == 'bar'
    end 
  end
end