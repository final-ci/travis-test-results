require 'travis/test-results'
require 'travis/support'
require 'travis/test-results/helpers/database'

module Travis::TestResults::Helpers
  describe Database do
    let(:database) { described_class.new }
    let(:sequel) { described_class.create_sequel }
    let(:now) { Time.now.utc }

    before(:each) do
      sequel[:step_results].delete
      sequel << "SET TIME ZONE 'UTC'"
      database.connect
    end

    describe '#create_step_result' do
      it 'creates step with the given job ID' do
        database.create_step_result(2, name: 'my step')

        expect(sequel[:step_results].where(job_id: 2).count).to eq(1)
      end
    end

    describe '#step_result_by_job_id' do
      it 'returns all step resutls with given job_id' do
        steps = [
          { job_id: 2, data: { name: 'hello' }.to_json },
          { job_id: 3, data: { name: 'world' }.to_json },
          { job_id: 3, data: { name: 'foobar' }.to_json }
        ]
        sequel[:step_results].multi_insert(steps)

        result = database.step_result_by_job_id(3)
        expect(result.count).to eq 2
        expect(result.first).to include(job_id: 3, data: { 'name' => 'world' })
      end
    end
  end
end
