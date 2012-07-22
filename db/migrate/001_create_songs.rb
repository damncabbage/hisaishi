class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :title
      t.string :artist
      t.string :album
      t.string :origin_title
      t.string :origin_type
      t.string :origin_medium
      t.string :genre
      t.string :language # ja, en

      t.integer :karaoke # Was a DataMapper ENUM; see Songs::EnumCompatibility
      # TODO: t.integer :lyrics

      t.string :source_dir
      t.string :audio_file
      t.string :lyrics_file
      t.string :image_file
      t.integer :length # seconds

      # Relics from the "audit" branch
      t.integer :yes, :default => 0
      t.integer :no, :default => 0
      t.integer :unknown, :default => 0

      t.timestamps
    end
  end
end
