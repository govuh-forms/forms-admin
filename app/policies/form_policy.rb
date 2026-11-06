class FormPolicy
  attr_reader :user, :form

  def initialize(user, form)
    @user = user
    @form = form
  end

  # A technical administrator may inspect a form for platform support, but
  # technical access alone is not authority to change an institution's form.
  def can_view_form?
    user.super_admin? || can_edit_form?
  end

  def can_edit_form?
    user.groups.include?(form.group) || user.is_organisations_admin?(form.group&.organisation)
  end

  alias_method :copy?, :can_edit_form?
  alias_method :delete?, :can_edit_form?
  alias_method :destroy?, :delete?

  def can_add_page_routing_conditions?
    form_has_two_or_more_pages = form.pages.length >= 2
    form_has_qualifying_pages = form.qualifying_route_pages.any?

    form_has_two_or_more_pages && form_has_qualifying_pages
  end

  def can_make_form_live?
    form.group&.active? && can_edit_form? && can_administer_group?
  end

  def can_make_language_live?
    can_make_form_live?
  end

  # Issue and withdrawal need the service-owning organisation's authority.
  # Platform super administration alone must not grant it.
  def can_administer_group?
    user.is_organisations_admin?(form.group&.organisation) || user.is_group_admin?(form.group)
  end
end
