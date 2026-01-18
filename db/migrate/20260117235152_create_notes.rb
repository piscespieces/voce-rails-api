class CreateNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :notes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :webhook, null: true, foreign_key: true
      t.string :title
      t.text :content
      t.string :status, default: "pending"

      t.timestamps
    end
  end
end
