class Create < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :name
      t.date :birthdate
      t.references :organisation
      t.timestamps
    end

    create_table :organisations do |t|
      t.string :name
      t.boolean :active
      t.timestamps
    end

    create_table :addresses do |t|
      t.string :street
      t.integer :number
      t.references :person
      t.references :organisation
      t.timestamps
    end
  end
end
