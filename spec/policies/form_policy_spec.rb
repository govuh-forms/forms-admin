require "rails_helper"

describe FormPolicy do
  subject(:policy) { described_class.new(user, form) }

  let(:organisation) { build :organisation, :with_signed_mou, id: 1 }
  let(:form) { create :form, creator_id: 123 }
  let(:group) { create(:group, name: "Group 1", organisation:, status: group_status) }
  let(:group_status) { :trial }
  let(:user) { build :user, organisation: }

  before do
    if group.present?
      GroupForm.create!(form_id: form.id, group_id: group.id)
    end
  end

  describe "#can_view_form?" do
    context "when user is in the group" do
      before do
        Membership.create!(user:, group:, added_by: user)
      end

      it { is_expected.to permit_actions(%i[can_view_form]) }
    end

    context "when user is not in the group" do
      it { is_expected.to forbid_actions(%i[can_view_form]) }

      context "but user is a super_admin" do
        let(:user) { build :super_admin_user, organisation: }

        it { is_expected.to permit_actions(%i[can_view_form]) }
      end

      context "but user is an organisation_admin" do
        context "and the user is in the same organisation as the group" do
          let(:user) { build :organisation_admin_user, organisation: }

          it { is_expected.to permit_actions(%i[can_view_form]) }
        end

        context "and the user is not in the same organisation as the group" do
          let(:other_organisation) { build :organisation, id: 2, slug: "other" }

          let(:user) { build :organisation_admin_user, organisation: other_organisation }

          it { is_expected.to forbid_actions(%i[can_view_form]) }
        end
      end
    end

    context "with a super_admin role" do
      let(:user) { build :super_admin_user, organisation: }

      it { is_expected.to permit_actions(%i[can_view_form]) }

      context "and a form from another organisation" do
        let(:organisation) { build :organisation, id: 2, slug: "non-gds" }

        it { is_expected.to permit_actions(%i[can_view_form]) }
      end
    end
  end

  describe "#can_edit_form?" do
    context "when a technical super administrator has no institution membership" do
      let(:user) { build :super_admin_user, organisation: }

      it { is_expected.to forbid_actions(%i[can_edit_form copy delete]) }
      it { is_expected.to permit_action(:can_view_form) }
    end

    context "when an editor belongs to another organisation" do
      let(:other_organisation) { build :organisation, id: 2, slug: "other" }
      let(:user) { build :organisation_admin_user, organisation: other_organisation }

      it { is_expected.to forbid_actions(%i[can_edit_form copy delete]) }
    end

    context "when a group editor belongs to the owning group" do
      before { Membership.create!(user:, group:, added_by: user, role: :editor) }

      it { is_expected.to permit_action(:can_edit_form) }
    end
  end

  describe "#can_make_form_live?" do
    context "with the groups feature enabled" do
      let(:group_role) { :editor }

      before do
        Membership.create!(user:, group:, added_by: user, role: group_role)
      end

      context "and the group status is not active" do
        let(:group_status) { :trial }

        it { is_expected.to forbid_action(:can_make_form_live) }
      end

      context "and the group status is active" do
        let(:group_status) { :active }

        context "and a technical super administrator has only editor membership" do
          let(:user) { build :super_admin_user, organisation: }

          it { is_expected.to forbid_action(:can_make_form_live) }
        end

        context "and a technical administrator has been appointed group administrator" do
          let(:user) { build :super_admin_user, organisation: }
          let(:group_role) { :group_admin }

          it { is_expected.to permit_action(:can_make_form_live) }
        end

        context "and the user is organisation admin for the group" do
          let(:user) { build :organisation_admin_user, organisation: }

          it { is_expected.to permit_action(:can_make_form_live) }
        end

        context "and the user's role within the group is group admin" do
          let(:group_role) { :group_admin }

          it { is_expected.to permit_action(:can_make_form_live) }
        end

        context "and the user's role within the group is editor" do
          it { is_expected.to forbid_action(:can_make_form_live) }
        end
      end
    end
  end

  describe "#can_make_language_live?" do
    context "with the groups feature enabled" do
      let(:group_role) { :editor }

      before do
        Membership.create!(user:, group:, added_by: user, role: group_role)
      end

      context "and the group status is not active" do
        let(:group_status) { :trial }

        it { is_expected.to forbid_action(:can_make_language_live) }
      end

      context "and the group status is active" do
        let(:group_status) { :active }

        context "and a technical super administrator has only editor membership" do
          let(:user) { build :super_admin_user, organisation: }

          it { is_expected.to forbid_action(:can_make_language_live) }
        end

        context "and the user is organisation admin for the group" do
          let(:user) { build :organisation_admin_user, organisation: }

          it { is_expected.to permit_action(:can_make_language_live) }
        end

        context "and the user's role within the group is group admin" do
          let(:group_role) { :group_admin }

          it { is_expected.to permit_action(:can_make_language_live) }
        end

        context "and the user's role within the group is editor" do
          it { is_expected.to forbid_action(:can_make_language_live) }
        end
      end
    end
  end

  describe "#can_add_page_routing_conditions?" do
    let(:form) { create :form }

    context "and the form has one page" do
      before do
        create(:page, form:)
      end

      it { is_expected.to forbid_actions(%i[can_add_page_routing_conditions]) }
    end

    context "and the form has two or more pages" do
      let(:form) { create :form }

      context "and the form does not have any qualifying pages" do
        let(:form) { create :form, :with_pages }

        it { is_expected.to forbid_actions(%i[can_add_page_routing_conditions]) }
      end

      context "and the form has a qualifying pages" do
        let(:form) { create :form, :ready_for_routing }

        it { is_expected.to permit_actions(%i[can_add_page_routing_conditions]) }
      end
    end
  end

  describe "#can_administer_group?" do
    let(:group) { create(:group, name: "Group 1", organisation:) }
    let(:group_role) { :editor }

    before do
      Membership.create!(user:, group:, added_by: user, role: group_role)
    end

    context "when the user is a technical super admin but only an editor" do
      let(:user) { build :super_admin_user, organisation: }

      it { is_expected.to forbid_action(:can_administer_group) }
    end

    context "when the user is an organisation admin" do
      let(:user) { build :organisation_admin_user, organisation: }

      it { is_expected.to permit_action(:can_administer_group) }
    end

    context "when the user is a group admin" do
      let(:group_role) { :group_admin }

      it { is_expected.to permit_action(:can_administer_group) }
    end

    context "when the user is an editor" do
      it { is_expected.to forbid_action(:can_administer_group) }
    end
  end
end
