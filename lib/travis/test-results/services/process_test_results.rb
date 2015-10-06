#TODO:
#
#  this is skeleton of processing text results
#  currently it is using travis-core models to persist paylod to DB
#  It is wrong approach and has to be rewritten:
#  * separace DB sould be used
#  * without using a travis-core
#  * use Pusher
#  * storing to DB sould be done by PL/pgSQL and possibly store in bulk, see:
#    Common Table Expressions,
#    http://dba.stackexchange.com/a/46477/64412
#    ... a lot of questions about best implementation...
#    I have to study Postgress a bit...
#
#  * needs `finish` message?
#  * needs numbered messages and and filter yunger ones
#

#require 'travis/model'

module Travis
  module TestResults
    module Services
      class ProcessTestResults

        def self.run(payload)
          new(payload).run
        end

        attr_reader :payload

        def initialize(payload, database = nil, pusher_client = nil, existence = nil)
          @payload = payload
        end

        def run
          save_payload
        end

        private

          attr_reader :database, :pusher_client, :existence

          def save_payload
            Travis.logger.debug "Processing payload: #{payload.inspect}"
            Travis.uuid = payload['uuid']
            if payload['final']
              job_id = payload['job_id']
              Travis::TestResults.cache.save_data_json(job_id, true)
              Travis::TestResults.cache.delete(job_id)
              return
            end

            payload['steps'].each do |step|
              begin
                Travis.logger.debug("Storing in cache: #{step}")

                job_id = step['job_id']
                uuid = step['uuid']
                number = step['number']

                cached = Travis::TestResults.cache.get(job_id, uuid)

                # skip step update if is not fresh (e.g. we already recieved newer update)
                if cached and cached['number'].to_i > number.to_i
                  Travis.logger.info "Ignoring old message number=#{number}, already stored number=#{cached['number']}"
                  next
                end

                Travis::TestResults.cache.set(job_id, uuid, step)
              rescue => e
                Travis.logger.warn "[warn] could not save test_result job_id: #{step['job_id']}: #{e.message}"
                Travis.logger.warn e.backtrace
              end
            end
          end

      end
    end
  end
end
