class AddDiscordContactToSupportEnquiries < ActiveRecord::Migration[8.0]
  def change
    add_column :support_enquiries, :discord_contact, :string, limit: 100
    change_column_null :support_enquiries, :contact_email, true
  end
end
