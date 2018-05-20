class CreateRoleFrequencies < ActiveRecord::Migration[5.2]
  def change
    create_table :role_frequencies do |t|
      t.integer :speaker_1
      t.integer :speaker_2
      t.integer :speaker_3
      t.integer :evaluator_1
      t.integer :evaluator_2
      t.integer :evaluator_3
      t.integer :tt_evaluator_1
      t.integer :tt_evaluator_2
      t.integer :toastmaster
      t.integer :chair
      t.integer :ge
      t.integer :topics_master
      t.integer :grammarian
      t.integer :ah_counter
      t.integer :timer
    end
  end
end
