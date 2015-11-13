Sequel.migration do
  up do
    create_table(:step_results) do
      primary_key :id
      integer :job_id
      text :data

      timestamp :created_at
      timestamp :updated_at

      index :job_id, name: 'index_step_results_on_job_id'
    end

    run 'ALTER TABLE step_results ALTER COLUMN data TYPE JSON USING data::JSON;'
  end

  down do
    drop_table(:step_results)
  end
end
