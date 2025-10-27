class CreateWebapps < ActiveRecord::Migration[7.1]
  def change
    create_table :webapps do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :icon_url, null: false
      t.timestamps
    end
  end
end

