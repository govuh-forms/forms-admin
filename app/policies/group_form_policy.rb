class GroupFormPolicy < ApplicationPolicy
  def new?
    group = record.group
    user.is_organisations_admin?(group.organisation) || user.groups.include?(group)
  end

  alias_method :create?, :new?

  def edit?
    organisation_admin_or_super_admin?
  end

  def update?
    organisation_admin_or_super_admin?
  end

private

  def organisation_admin_or_super_admin?
    user.is_organisations_admin?(record.group.organisation)
  end
end
