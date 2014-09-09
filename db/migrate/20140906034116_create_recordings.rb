class CreateRecordings < ActiveRecord::Migration
  def change
    create_table :recordings do |t|
      t.datetime :created_at
      t.integer :bus, index: true
      t.string :url
      t.boolean :hidden, default: false
    end
  end
end
