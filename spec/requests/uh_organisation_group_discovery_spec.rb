require "rails_helper"

RSpec.describe "Department-owned form groups", type: :request do
  let!(:interior) { create(:organisation, name: "Interior Office") }
  let!(:citizenship_group) { create(:group, name: "Citizenship and status applications", organisation: interior, status: :active) }

  describe "super administrator navigation and creation" do
    before { login_as_super_admin_user }

    it "offers an organisation with a form group even when it has no Forms users" do
      expect(interior.users.count).to eq(0)
      get groups_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Interior Office")
      get groups_path, params: { search: { organisation_id: interior.id } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Citizenship and status applications")
    end

    it "shows the selected organisation in the native group creation page" do
      get new_group_path, params: { organisation_id: interior.id }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Interior Office")
    end

    it "creates a group in a selected organisation without giving outsiders membership" do
      post groups_path, params: { group: { name: "Immigration applications", organisation_id: interior.id } }
      created = Group.find_by!(name: "Immigration applications")
      expect(created.organisation).to eq(interior)
      expect(created.memberships.count).to eq(0)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "ordinary member boundaries" do
    before { login_as_standard_user }

    it "cannot create a group in a different organisation by submitting a forged organisation ID" do
      current = User.order(:id).last
      # Use the authenticated test account's real organisation for the invariant.
      post groups_path, params: { group: { name: "My permitted group", organisation_id: interior.id } }
      created = Group.find_by!(name: "My permitted group")
      expect(created.organisation).not_to eq(interior)
    end
  end
end
