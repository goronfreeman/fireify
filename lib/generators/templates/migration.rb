class FireifyCreateUsers < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table(:users) do |t|
<%= migration_data %>
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :firebase_id, unique: true
  end
end
