require "rails_helper"

RSpec.describe FormsController, type: :request do
  let(:form) { create(:form, name: "Form name", creator_id: 123) }
  let(:user) { standard_user }
  let(:group) { create(:group, organisation: user.organisation, status: :active) }

  before do
    Membership.create!(group_id: group.id, user:, added_by: user, role: :group_admin)
    GroupForm.create!(form:, group_id: group.id)
    create(:organisation_admin_user, organisation: user.organisation)
    login_as user
  end

  describe "#alert_org_admins_if_draft_created" do
    before do
      # Adding a new question loads in the form again from the database during creation. Post to this route to test that
      # this triggers an alert email for the status change even though the Form model loaded in by the controller isn't
      # directly updated.
      create :draft_question_for_new_page, user:, form_id: form.id
      post(create_question_path(form.id), params: {
        submit_type: "save",
        pages_question_input: {
          question_text: "Some question",
          hint_text: "",
          is_optional: false,
          is_repeatable: false,
        },
      })
    end

    context "when submitting to a route creates a draft of an existing form" do
      let(:form) { create(:form, :live) }

      it "sends an email to the organisation admins" do
        expect(response).to have_http_status(:redirect)
        expect(form.reload).to be_live_with_draft
        expect(ActionMailer::Base.deliveries.count).to eq(1)

        template_id = Settings.govuk_notify.admin_alerts.new_live_form_draft_created_template_id
        expect(ActionMailer::Base.deliveries.last.govuk_notify_template).to eq(template_id)
      end
    end

    context "when submitting to a route does not create a draft" do
      let(:form) { create(:form, :live_with_draft) }

      it "does not send an email to the organisation admins" do
        expect(response).to have_http_status(:redirect)
        expect(ActionMailer::Base.deliveries.count).to eq(0)
      end
    end
  end

  describe "#reject_forms_with_too_many_routing_conditions" do
    let(:routing_page) { create(:page, :with_selection_settings, form:) }

    before do
      stub_const("FormsController::MAX_ROUTING_CONDITIONS_PER_PAGE", 2)
      allow(Sentry).to receive(:capture_message)
      create_list(:condition, routing_conditions_count, routing_page:, check_page: routing_page, answer_value: "Option 1")
    end

    context "when no page has more routing conditions than the limit" do
      let(:routing_conditions_count) { 2 }

      it "shows the form" do
        get form_path(form.id)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("forms/draft/show")
      end

      it "shows the list of questions" do
        get form_pages_path(form.id)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("pages/index")
      end

      it "does not report to Sentry" do
        get form_path(form.id)
        expect(Sentry).not_to have_received(:capture_message)
      end
    end

    context "when a page has more routing conditions than the limit" do
      let(:routing_conditions_count) { 3 }

      it "does not show the form" do
        get form_path(form.id)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("errors/form_too_large")
      end

      it "does not show the list of questions" do
        get form_pages_path(form.id)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("errors/form_too_large")
      end

      it "reports to Sentry with the form ID and number of routing conditions" do
        get form_path(form.id)
        expect(Sentry).to have_received(:capture_message)
          .with(a_string_including("too many routing conditions"), extra: { form_id: form.id, max_routing_conditions: 3 })
      end

      context "when the user cannot view the form" do
        before do
          GroupForm.find_by(form_id: form.id).destroy!
        end

        it "returns forbidden rather than revealing the form is too large" do
          get form_path(form.id)
          expect(response).to have_http_status(:forbidden)
          expect(response).not_to render_template("errors/form_too_large")
        end

        it "does not report to Sentry" do
          get form_path(form.id)
          expect(Sentry).not_to have_received(:capture_message)
        end
      end
    end
  end
end
