class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :role, null: false
      t.references :company, null: false, foreign_key: true

      t.timestamps
    end

    add_index :contacts, [ :company_id, :role ]
  end
end
