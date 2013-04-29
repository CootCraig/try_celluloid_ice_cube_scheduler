require 'rubygems'
require 'bundler/setup'

require 'celluloid'
require 'ice_cube'

module Scheduler
  require 'date'
  def scheduled_blocks
    @scheduled_blocks = [] unless defined?(@scheduled_blocks)
    @scheduled_blocks
  end
  def run_on_schedule(schedule,method,*args)
    scheduled_block = ScheduledBlock.new(schedule,self,method,args)
    scheduled_blocks << scheduled_block
    scheduled_block
  end
  class ScheduledBlock
    def initialize(schedule,actor,method,args)
      @schedule,@actor,@method,@args = schedule,actor,method,args
      schedule_next
    end
    def schedule_next
      @actor.after(3) {@actor.async(@method,*@args); schedule_next}
    end
  end
end
class AnActor
  include Celluloid
  include Scheduler

  def hello(*args)
    puts "hello #{Time.now} args #{args}"
  end
end

o = AnActor.new
o.run_on_schedule(nil,:hello,3,2,1)
sleep 20

