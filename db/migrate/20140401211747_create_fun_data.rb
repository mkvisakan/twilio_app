class CreateFunData < ActiveRecord::Migration
  def change
    create_table :fun_data do |t|
      t.string :type
      t.text :story
      t.timestamps
    end
  end
end
