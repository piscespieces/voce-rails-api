class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :clerk_id
      t.string :email

      t.timestamps
    end
    add_index :users, :clerk_id, unique: true
    add_index :users, :email
  end
end
