require 'rubygems'
require 'bundler/setup'

require 'date'
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
      @method_timer = nil
      @schedule_timer = nil
      schedule_next
    end
    def cancel_schedule
      cancel_timers
      @actor.scheduled_blocks.delete self
    end
    def cancel_timers
      unless @method_timer.nil?
        @method_timer.cancel
        @method_timer = nil
      end
      unless @schedule_timer.nil?
        @schedule_timer.cancel
        @schedule_timer = nil
      end
    end
    def schedule_next
      cancel_timers
      seconds = seconds_to_next
      if seconds>0
        @method_timer = @actor.after(seconds) {@actor.async(@method,*@args)}
      end
      @schedule_timer = @actor.after(seconds+1) {schedule_next}
    end
    def seconds_to_next
      now = Time.now
      next_time = @schedule.next_occurrence.to_time + 0.1
      seconds = (next_time - now).ceil
      seconds>0 ? seconds : 0
    end
  end
end
class AnActor
  include Celluloid
  include Scheduler

  def hello(*args)
    puts "hello #{Time.now} args #{args}"
  end
  def no(*args)
    puts "no #{Time.now} args #{args}"
  end
end

o = AnActor.new
s1 = IceCube::Schedule.new
s1.add_recurrence_rule IceCube::Rule.secondly(5)
puts "secondly(5) next_occurence #{s1.next_occurrence}"
o.hello 'direct'
secondly_schedule = o.run_on_schedule(s1,:hello,'secondly(5)')

now = Time.now
s2 = IceCube::Schedule.new Time.local(now.year,now.month,now.day,23,30)
s2.add_recurrence_rule IceCube::Rule.daily
puts "daily 23:30 next_occurence #{s2.next_occurrence}"
o.run_on_schedule(s2,:hello,'daily')

start = Time.now - 120
[1,12,22,28,46,51,55].each do |sec|
  s = IceCube::Schedule.new Time.local(start.year,start.month,start.day,start.hour,start.min,sec)
  s.add_recurrence_rule IceCube::Rule.minutely
  o.run_on_schedule(s,:no,"minutely on the #{sec}")
end
sleep 45
puts "cancel secondly_schedule"
secondly_schedule.cancel_schedule
sleep 4*60

