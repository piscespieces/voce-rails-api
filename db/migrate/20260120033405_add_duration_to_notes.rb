class AddDurationToNotes < ActiveRecord::Migration[7.1]
  def change
    add_column :notes, :duration, :integer
  end
end
