class CreateSupportEnquiries < ActiveRecord::Migration[8.0]
  def change
    create_table :support_enquiries do |t|
      t.string :reference, null: false, limit: 40
      t.string :category, null: false, limit: 45
      t.string :contact_name, null: false, limit: 150
      t.string :contact_email, null: false, limit: 254
      t.text :message, null: false
      t.string :status, null: false, default: "open", limit: 30
      t.text :staff_reply
      t.datetime :replied_at
      t.string :access_token_digest, null: false, limit: 64
      t.string :handled_by, limit: 150
      t.timestamps
    end
    add_index :support_enquiries, :reference, unique: true
    add_index :support_enquiries, :access_token_digest, unique: true
    add_index :support_enquiries, [:status, :created_at]
  end
end
