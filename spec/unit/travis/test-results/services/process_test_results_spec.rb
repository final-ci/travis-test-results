require 'travis/test-results'
require 'travis/support'
require 'travis/test-results/services/process_test_results'
require 'travis/test-results/helpers/database'

class FakeDatabase
  attr_reader :logs, :log_parts

  def initialize
    @steps = []
  end

  def create_step_result(job_id, data)
    @steps << { id: job_id, data: data }
    job_id
  end

  def step_result_by_job_id(job_id)
    @steps.find_all { |t| t == job_id }
  end
end

module Travis::TestResults::Services
  describe ProcessTestResults do
    let(:payload) do
      { 'steps' => [{
        'job_id'      => 2,
        'name'        => 'step1',
        'postion'     => 1,
        'class_name'  => 'TestCase1',
        'class_postion' => 1,
        'result' => 'fail'
      }]
      }
    end
    let(:database) { FakeDatabase.new }
    let(:pusher_client) { double('pusher-client', push: nil) }

    let(:service) { described_class.new(payload, database, pusher_client) }

    before(:each) do
      Travis::TestResults.config.channels_existence_check = true
      Travis::TestResults.config.channels_existence_metrics = true
      allow(Metriks).to receive(:meter).and_return(double('meter', mark: nil))
      allow(service).to receive(:channel_occupied?) { true }
      allow(service).to receive(:channel_name) { 'channel' }
    end

    context 'without an existing log' do
      it 'creates a step result' do
        service.run

        expect(database.step_result_by_job_id(2)).not_to be_nil
      end
    end

    describe 'existence check' do
      it 'sends a step_results if channel is not occupied but the existence check is disabled' do
        expect(service).to receive(:existence_check?) { false }
        expect(service).to receive(:channel_occupied?) { false }
        expect(service).to receive(:mark).with('pusher.ignore')

        service.run

        pusher_client.should have_received(:push).with(any_args)
      end

      it 'ignores a step_result if channel is not occupied' do
        expect(service).to receive(:channel_occupied?) { false }
        expect(service).to receive(:mark).with('pusher.ignore')

        service.run

        pusher_client.should_not have_received(:push)
      end

      it 'sends a step_result if channel is occupied' do
        expect(service).to receive(:channel_occupied?) { true }
        expect(service).to receive(:mark).with('pusher.send')

        service.run

        pusher_client.should have_received(:push).with(any_args)
      end
    end

    context 'when pusher.secure is true' do
      before(:each) do
        Travis::TestResults.config.pusher.secure = true
      end

      it 'notifies pusher on a private channel' do
        service.run

        pusher_client.should have_received(:push).with('id' => 2,
                                                       'data' => {
                                                         'steps' => [{
                                                           'job_id' => 2,
                                                           'name' => 'step1',
                                                           'postion' => 1,
                                                           'class_name' => 'TestCase1',
                                                           'class_postion' => 1,
                                                           'result' => 'fail'
                                                         }]
                                                       })
      end
    end

    context 'when pusher.secure is false' do
      before(:each) do
        Travis::TestResults.config.pusher.secure = false
      end

      it 'notifies pusher on a regular channel' do
        service.run

        pusher_client.should have_received(:push).with('id' => 2,
                                                       'data' => {
                                                         'steps' => [{
                                                           'job_id' => 2,
                                                           'name' => 'step1',
                                                           'postion' => 1,
                                                           'class_name' => 'TestCase1',
                                                           'class_postion' => 1,
                                                           'result' => 'fail'
                                                         }]
                                                       })
      end
    end
  end
end
