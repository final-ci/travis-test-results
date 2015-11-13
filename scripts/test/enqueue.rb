require 'rubygems'
require 'travis/support'
require 'travis/support/amqp'
require 'multi_json'
require 'hashr'

Travis::Amqp.config = {
  host: 'localhost',
  port: 5672,
  username: 'travisci_worker',
  password: 'travisci_worker_password',
  virtual_host: 'travisci.development'
}

class QueueTester
  def start
    Travis::Amqp.connect
    @publisher = Travis::Amqp::Publisher.jobs(
      'test_results',
      unique_channel: true,
      dont_retry: true
    )
    @publisher.channel.prefetch = 1
  end

  def stop
    Travis::Amqp.disconnect
    true
  end

  def queue_job
    @publisher.publish(payload)
  end
end

def payload
  {
    id: 1, # job_id
    name: "test step no. #{rand(10)} name",
    classname: "test case no. #{rand(10)} name",
    result: rand(2) == 0 ? 'success' : 'failure',
    duration: rand(1000)
  }
end

puts "about to start the queue tester\n\n"

@queue_tester = QueueTester.new
@queue_tester.start

Signal.trap('INT') { @queue_tester.stop; exit }

puts "queue tester started! \n\n"

loop do
  print 'press enter to push test_result message, or exit to quit : '

  output = gets.chomp

  @queue_tester.stop && exit if output == 'exit'

  @queue_tester.queue_job

  puts "build payload sent!\n\n"
end
