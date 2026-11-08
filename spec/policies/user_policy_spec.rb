require "rails_helper"

describe UserPolicy do
  subject(:policy) { described_class.new(user, records) }

  let(:user) { build :super_admin_user }
  let!(:records) { create_list :user, 5 }

  context "with super admin role" do
    it { is_expected.to permit_actions(%i[can_manage_user]) }

    it "forbids changing the administrator's own role or organisation" do
      expect(described_class.new(user, user)).to forbid_action(:can_change_user)
    end

    it "allows support editing of another account only" do
      expect(described_class.new(user, records.first)).to permit_action(:can_change_user)
    end

    it "forbids changing any account identity, institutional role or entitlement" do
      expect(described_class.new(user, records.first)).to forbid_action(:can_change_identity)
    end
  end

  context "with standard role" do
    let(:user) { build :user }

    it { is_expected.to forbid_actions(%i[can_manage_user]) }
  end

  describe UserPolicy::Scope do
    subject(:policy_scope) { described_class.new(user, User) }

    context "with super admin role" do
      it "returns a list of users" do
        expect(policy_scope.resolve).to match_array(records)
      end
    end

    context "with standard role" do
      let(:user) { build :user }

      it "returns nil" do
        expect(policy_scope.resolve).to be_nil
      end
    end
  end
end
