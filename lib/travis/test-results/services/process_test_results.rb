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

require 'travis/model'

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
            Travis.logger.info "[info] storing payload: #{payload.inspect}"
            TestStepResult.write_result(
              job_id: payload['id'],
              name: payload['name'],
              classname: payload['classname'],
              result: payload['result'],
              duration: payload['duration'],
              test_data: payload[:test_data]
            )
          rescue => e
            Travis.logger.warn "[warn] could not save test_result job_id: #{payload['id']}: #{e.message}"
            Travis.logger.warn e.backtrace
          end

      end
    end
  end
end
