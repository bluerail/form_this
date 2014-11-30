class Create < ActiveRecord::Migration
  def change
    create_table :artists do |t|
      t.string :name
      t.timestamps
    end

    create_table :albums do |t|
      t.string :name

      t.date :release_date
      t.integer :rating

      t.references :genre
      t.references :artist
      t.timestamps
    end

    create_table :tracks do |t|
      t.string :name
      t.integer :trackno
      t.references :album
      t.timestamps
    end

    create_table :genres do |t|
      t.string :name
      t.timestamps
    end

    ActiveRecord::Base.connection.execute 'insert into genres (name) values ("Blues"), ("Jazz"), ("Metal"), ("Other")'
  end
end
