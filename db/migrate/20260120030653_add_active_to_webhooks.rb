class AddActiveToWebhooks < ActiveRecord::Migration[7.1]
  def change
    add_column :webhooks, :active, :boolean, default: true
  end
end
