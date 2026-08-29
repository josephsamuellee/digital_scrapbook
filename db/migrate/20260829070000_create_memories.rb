class CreateMemories < ActiveRecord::Migration[7.2]
  def change
    create_table :memories do |t|
      t.string :source_path, null: false
      t.string :title
      t.string :subtitle
      t.string :key_photo
      t.date :start_date
      t.date :end_date
      t.string :source_fingerprint
      t.datetime :source_modified_at

      t.timestamps
    end

    add_index :memories, :source_path, unique: true
  end
end
