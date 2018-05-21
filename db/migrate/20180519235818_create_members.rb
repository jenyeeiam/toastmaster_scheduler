class CreateMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :name
      t.string :email
      t.integer :speaker
      t.integer :evaluator
      t.integer :toastmaster
      t.integer :chair
      t.integer :ge
      t.integer :topics_master
      t.integer :functionary
      t.integer :tt_evaluator
    end
  end
end
