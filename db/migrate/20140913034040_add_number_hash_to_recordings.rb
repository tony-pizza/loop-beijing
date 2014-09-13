class AddNumberHashToRecordings < ActiveRecord::Migration
  def change
    add_column :recordings, :number_hash, :string
  end
end
