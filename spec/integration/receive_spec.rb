require "travis/test-results"
require "travis/support"
require "travis/support/amqp"
require "travis/test-results/receive/queue"
require 'travis/test-results/services/process_test_results'
require "travis/test-results/helpers/database"

class FakeAmqpQueue
  def subscribe(opts, &block)
    @block = block
  end

  def call(*args)
    @block.call(*args)
  end
end

describe "receive_test-results" do
  let(:queue) { FakeAmqpQueue.new }

  it "stores the log part in the database" do
    allow(Travis::Amqp::Consumer).to receive(:jobs) { queue }
    allow(Travis.config).to receive(:pusher_client) { double("pusher_client", :[] => double("channel", trigger: nil)) }
    db = Travis::TestResults::Helpers::Database.create_sequel
    db[:step_results].delete
    Travis::TestResults.database_connection = Travis::TestResults::Helpers::Database.connect
    Travis::TestResults::Receive::Queue.subscribe("test-results", Travis::TestResults::Services::ProcessTestResults)
    message = double("message", ack: nil)
    queue.call(message, '{"steps":[{"job_id":123,"name":"step1","position":1,"class_name":"class1","class_position":1}]}')
    log = db[:step_results].first

    expect(log[:job_id]).to eq(123)
  end

  it 'uses the default prefetch' do
    expect(Travis::Amqp::Consumer).to receive(:jobs).with('test-results', channel: { prefetch: 1 }) { queue }
    Travis::TestResults::Receive::Queue.subscribe('test-results', Travis::TestResults::Services::ProcessTestResults)
  end

  it 'uses a custom prefetch given in the config' do
    allow(Travis.config.amqp).to receive(:prefetch) { 2 }
    expect(Travis::Amqp::Consumer).to receive(:jobs).with('test-results', channel: { prefetch: 2 }) { queue }
    Travis::TestResults::Receive::Queue.subscribe('test-results', Travis::TestResults::Services::ProcessTestResults)
  end
end
