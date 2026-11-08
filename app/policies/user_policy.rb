class UserPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        scope
          .all
      end
    end
  end

  def can_manage_user?
    user.super_admin?
  end

  alias_method :can_download_users?, :can_manage_user?

  # Staff account administration must not be a route for an administrator to
  # grant themselves a different institution or its issuing role.
  def can_change_user?
    can_manage_user? && record != user
  end

  # P0 owns identity, entitlement and issuer provisioning. Until delegated
  # institutional grants are verified, technical support may not change these
  # attributes through Forms Admin, even when editing another account.
  def can_change_identity?
    false
  end
end
