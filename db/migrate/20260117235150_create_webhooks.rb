class CreateWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :webhooks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :url
      t.jsonb :headers
      t.datetime :last_used_at

      t.timestamps
    end
  end
end
