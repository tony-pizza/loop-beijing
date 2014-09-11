class AddDurationToRecordings < ActiveRecord::Migration
  def change
    add_column :recordings, :duration, :integer
  end
end
