require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/hash/deep_merge'
require 'multi_json'

module Travis::TestResults
  # Remembers steps by their jobs so that
  # they can be  provided in route GET steps/:uuid
  # for backward compatibility.
  class Cache
    def initialize(max_job_time = 24.hours, gc_pooling_interval = 1.hour)
      @cache = {}
      @max_job_time = max_job_time
      @mutex = Mutex.new
      initialize_garbage_collector gc_pooling_interval
    end

    def initialize_garbage_collector(pooling_interval)
      @thread = Thread.new do
        last_time_gc = Time.now
        begin
          loop do
            Travis.logger.debug "Next step cache GC in #{pooling_interval} seconds."
            sleep pooling_interval.to_i # fails in jruby without to_i

            start_time = Time.now
            gc(last_time_gc)
            last_time_gc = start_time
          end
        rescue StandardError => e
          Travis.logger.error "Step Cache GC exploded: #{e.class}: #{e.message}"
          raise e
        end
      end
    end

    def set_position_cache(job_id, step_uuid)
      payload = @cache[job_id][step_uuid].dup
      payload.delete 'job_id'
      position = (payload.delete 'position').to_i - 1
      class_position = (payload.delete 'class_position').to_i - 1
      classname = payload.delete 'classname'

      @cache[job_id][:by_positions] ||= []
      position_cache = @cache[job_id][:by_positions]

      position_cache[class_position] ||= {
        'classname' => classname,
        'steps' => []
      }
      position_cache[class_position]['steps'][position] = payload
      # TODO: what to do when position_cache.class_name != class_name ?
      # TODO: what to do when step name != payload['name']?
    end

    def get_position_cache(job_id)
      job_cache = get_job(job_id) || {}
      job_cache[:by_positions] || []
    end

    def set(job_id, step_uuid, result)
      fail ArgumentError, 'Parameter "result" must be a hash' unless
        result.is_a?(Hash)

      @mutex.synchronize do
        @cache[job_id] ||= {}
        @cache[job_id][:last_time_used] = Time.now

        @cache[job_id][step_uuid] ||= {}
        @cache[job_id][step_uuid].deep_merge!(result)

        set_position_cache(job_id, step_uuid)
      end

      @cache[job_id][step_uuid]
    end

    def get(job_id, step_uuid)
      return nil unless @cache[job_id]
      @cache[job_id][:last_time_used] = Time.now
      @cache[job_id][step_uuid]
    end

    def exists?(job_id)
      return !!@cache[job_id]
    end

    def delete(job_id)
      @mutex.synchronize do
        Travis.logger.info "Deleting #{job_id} from cache"
        @cache.delete job_id
      end
    end

    def gc(last_time_gc)
      Travis.logger.debug 'Starting cache garbage collector'
      expired_time = Time.now - @max_job_time
      Travis.logger.debug expired_time.to_s
      @cache.keys.each do |job_id|
        save_data_json(job_id) if @cache[job_id][:last_time_used] > last_time_gc
        delete(job_id) if @cache[job_id][:last_time_used] < expired_time
      end
      Travis.logger.debug 'Garbage collector finished'
    end

    def get_job(job_id)
      @cache[job_id]
    end

    # Use only if you will never ever use this class again
    #
    def finalize
      @mutex.synchronize do
        Thread.kill(@thread) if @thread
        @cache = {}
      end
    end

    def save_data_json(job_id, final = false)
      @mutex.synchronize do
        Travis.logger.info "Storing test results, job_id=#{job_id}, final=#{final}"
        begin
          File.open(job_file_path(job_id), 'w+') do |f|
            result = get_position_cache(job_id)
            f.puts MultiJson.dump(result, pretty: Travis.config.test_results.pretty_json || false)
          end
        rescue => e
          Travisl.logger.error "Cannot save result for job=#{job_id}: #{e}"
        end
      end
    end

    def job_file_path(job_id)
      "#{Travis.config.test_results.results_path}/#{job_id}.json"
    end

    private :initialize_garbage_collector, :gc, :set_position_cache
  end
end
