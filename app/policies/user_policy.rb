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
end
