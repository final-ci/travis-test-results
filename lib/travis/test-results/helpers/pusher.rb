require 'pusher'

module Travis
  module TestResults
    module Helpers
      # Helper class for Pusher calls
      #
      # This class handles pushing job payloads to Pusher.
      class Pusher
        def initialize(pusher_client = nil)
          @pusher_client = pusher_client || default_client
        end

        def push(payload)
          pusher_channel(payload).trigger('job:test-results', pusher_payload(payload))
        end

        def pusher_channel_name(payload)
          channel = ''
          channel << 'private-' if TestResults.config.pusher.secure
          channel << "job-#{payload['id']}"
          channel
        end

        private

        def pusher_channel(payload)
          @pusher_client[pusher_channel_name(payload)]
        end

        def pusher_payload(payload)
          {
            'id' => payload['id'],
            '_log' => payload['data']
          }
        end

        def default_client
          ::Pusher::Client.new(Travis::TestResults.config.pusher)
        end
      end
    end
  end
end
