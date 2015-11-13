require 'ostruct'
require 'travis/test-results'
require 'travis/test-results/app'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

module Travis::TestResults
  describe App do
    include Rack::Test::Methods

    def app
      Travis::TestResults::App.new(nil, pusher)
    end

    let(:pusher) { double(:pusher) }
    let(:existence) { Travis::TestResults::Existence.new }

    before do
      existence.vacant!('foo')
      existence.vacant!('bar')
    end

    describe 'GET /uptime' do
      it 'returns 204' do
        response = get '/uptime'
        response.status.should == 204
      end
    end

    describe 'POST /pusher/existence' do
      it 'sets proper properties on channel' do
        existence.occupied?('foo').should be_false
        existence.occupied?('bar').should be_false

        webhook = OpenStruct.new(valid?: true, events: [
          { 'name' => 'channel_occupied', 'channel' => 'foo' },
          { 'name' => 'channel_vacated',  'channel' => 'bar' }
        ])
        pusher.should_receive(:webhook) do |request|
          expect(request.path_info).to eq '/pusher/existence'
          webhook
        end

        response = post '/pusher/existence'
        response.status.should == 204

        existence.occupied?('foo').should be_true
        existence.occupied?('bar').should be_false

        webhook = OpenStruct.new(valid?: true, events: [
          { 'name' => 'channel_vacated', 'channel' => 'foo' },
          { 'name' => 'channel_occupied', 'channel' => 'bar' }
        ])
        pusher.should_receive(:webhook) do |request|
          expect(request.path_info).to eq '/pusher/existence'
          webhook
        end

        response = post '/pusher/existence'
        response.status.should == 204

        existence.occupied?('foo').should be_false
        existence.occupied?('bar').should be_true
      end

      it 'responds with 401 with invalid webhook' do
        webhook = OpenStruct.new(valid?: false)
        pusher.should_receive(:webhook) do |request|
          expect(request.path_info).to eq '/pusher/existence'
          webhook
        end

        response = post '/pusher/existence'
        response.status.should == 401
      end
    end
  end
end
