require 'travis/test-results/helpers/metrics'
require 'travis/test-results/helpers/pusher'
require 'travis/test-results/existence'
require 'pusher'

# pusher requires this in a method, which sometimes
# causes and uninitialized constant error
require 'net/https'

module Travis
  module TestResults
    module Services
      class ProcessTestResults
        include Helpers::Metrics

        METRIKS_PREFIX = 'test_results.process_results'

        def self.metriks_prefix
          METRIKS_PREFIX
        end

        def self.run(payload)
          new(payload).run
        end

        attr_reader :payload

        def initialize(payload, database = nil, pusher_client = nil, existence = nil)
          @payload = payload
          @database = database || Travis::TestResults.database_connection
          @pusher_client = pusher_client || Travis::TestResults::Helpers::Pusher.new
          @existence = existence || Travis::TestResults::Existence.new
        end

        def run
          measure do
            create_step_results
            notify
          end
        end

        private

        attr_reader :database, :pusher_client, :existence

        def create_step_results
          Travis.logger.debug "Processing payload: #{payload.inspect}"
          Travis.uuid = payload['uuid']
          if payload['final']
            job_id = payload['job_id']
            # TODO: Schedule ArrgregareTestResults
            return
          end

          payload['steps'].each do |step|
            begin
              create_step(step)
            rescue => e
              Travis.logger.warn "[warn] could not save test_result job_id: #{step['job_id']}: #{e.message}"
              Travis.logger.warn e.backtrace
            end
          end
        end

        def create_step(step)
          job_id = step['job_id']
          Travis.logger.debug("Creating step: #{step} for job_id: #{job_id}")
          database.create_step_result(job_id, step)
        rescue Sequel::Error => e
          Travis.logger.warn "[warn] could not save test-step for job_id: #{step.inspect}: #{e.message}"
          Travis.logger.warn e.backtrace
        end

        def notify
          if existence_check_metrics? || existence_check?
            if channel_occupied?(channel_name)
              mark('pusher.send')
            else
              mark('pusher.ignore')

              return if existence_check?
            end
          end

          measure('pusher') do
            pusher_client.push(pusher_payload)
          end
        rescue => e
          Travis.logger.error("Error notifying of test-results update: #{e.message} (from #{e.backtrace.first})")
        end

        def pusher_payload
          job_id = payload['job_id'] || payload['steps'].first['job_id']
          {
            'id' => job_id,
            'data' => payload
          }
        end

        def channel_occupied?(channel_name)
          existence.occupied?(channel_name)
        end

        def channel_name
          pusher_client.pusher_channel_name(pusher_payload)
        end

        def existence_check_metrics?
          TestResults.config.channels_existence_metrics
        end

        def existence_check?
          TestResults.config.channels_existence_check
        end
      end
    end
  end
end
