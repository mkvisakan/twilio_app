class CreateBusStopNamesMadisons < ActiveRecord::Migration
  def change
    create_table :bus_stop_names_madison do |t|
      t.string :stop_id
      t.string :stop_name
      t.timestamps
    end
  end
end
