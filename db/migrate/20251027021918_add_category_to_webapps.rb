class AddCategoryToWebapps < ActiveRecord::Migration[7.1]
  def change
    add_column :webapps, :category, :string
  end
end
