class MembershipPolicy < ApplicationPolicy
  # Platform super administrators cannot grant themselves issuing authority
  # by promoting group memberships or removing an institution's publisher.
  def destroy?
    organisation_admin? || (group_admin? && record.editor?)
  end

  def update?
    organisation_admin?
  end

private

  def group_admin?
    user.is_group_admin?(record.group)
  end

  def organisation_admin?
    user.is_organisations_admin?(organisation)
  end

  def organisation
    record.group.organisation
  end
end
