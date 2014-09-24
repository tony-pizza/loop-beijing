class RenameUrlToOriginalUrlAndAddWebUrlToRecordings < ActiveRecord::Migration
  def change
    rename_column :recordings, :url, :original_url
    add_column :recordings, :web_url, :string
  end
end
