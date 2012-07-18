class CreateQueueItems < ActiveRecord::Migration
  def change
    create_table :queue_items do |t|
      t.references :song
      t.integer :time
      t.string :requester
      t.integer :position

      # Was a DataMapper ENUM; we don't care about compatibility
      # for the queue table, though, as it's temporary (and
      # doesn't even have the same name as the old one).
      t.string :play_state

      t.timestamps
    end
  end
end
