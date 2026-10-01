class FormsController < WebController
  # Temporary guard: checking the routing conditions on a page with a very large number of them uses enough memory to
  # get the container OOM killed, so we refuse to load those forms until that's fixed
  MAX_ROUTING_CONDITIONS_PER_PAGE = 200

  before_action :load_form
  before_action :reject_forms_with_too_many_routing_conditions
  after_action :verify_authorized
  after_action :alert_org_admins_if_draft_created

  attr_reader :current_form

  def current_live_or_archived_form
    @current_live_or_archived_form ||= FormDocument::Content.from_form_document(current_form.latest_form_document)
  end

  def current_live_or_archived_welsh_form
    @current_live_or_archived_welsh_form ||= FormDocument::Content.from_form_document(current_form.latest_welsh_form_document)
  end

private

  def load_form
    @current_form = Form.find(params[:form_id])
    @current_form.set_task_status_service(TaskStatusService.new(form: @current_form))
    @initial_form_state = @current_form.state
  end

  def reject_forms_with_too_many_routing_conditions
    max_routing_conditions = Condition.joins(:routing_page)
                                      .where(pages: { form_id: current_form.id })
                                      .group(:routing_page_id)
                                      .count
                                      .values.max.to_i
    return if max_routing_conditions <= MAX_ROUTING_CONDITIONS_PER_PAGE

    authorize current_form, :can_view_form?

    Sentry.capture_message("Refusing to load form with too many routing conditions on a page",
                           extra: { form_id: current_form.id, max_routing_conditions: })
    render "errors/form_too_large", status: :unprocessable_content, formats: :html
  end

  def alert_org_admins_if_draft_created
    return if current_form.destroyed?
    return unless @current_form.reload.draft_created?(@initial_form_state)

    OrgAdminAlertsService.new(form: current_form, current_user:).draft_of_existing_form_created
  end
end
