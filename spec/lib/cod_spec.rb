require 'spec_helper'

describe Cod do
  describe '#uuid' do
    it "generates unique numbers for each thread" do
      threads = 10.times.map {
        Thread.start do
          Thread.current[:uuids] ||= []
          uuids = Thread.current[:uuids]
          
          100.times do
            uuids << Cod.uuid
          end
        end
      }
      
      # Wait for all threads to complete
      threads.each { |t| t.join }
      
      # Make sure that none of the UUIDs match
      merged = Set.new
      threads.each { |t| merged += t[:uuids] }
      
      # NOTE This may seem naive, since the chance of UUIDs colliding is ... 
      # very small. But if the UUID library is not reinitialized for every
      # thread and process, this chance is actually close to one. This spec
      # should catch that. 
      merged.should have(10*100).entries
    end
    it "generates unique numbers for each process" do
      children = Cod.pipe
      
      2.times do
        fork do
          master = children # rename the pipe
          
          10.times do master.put Cod.uuid end
        end
      end
      
      Process.waitall
      
      merged = Set.new
      while children.waiting?
        merged << children.get
      end
      
      children.close
      
      merged.should have(20).entries
    end
  end
end