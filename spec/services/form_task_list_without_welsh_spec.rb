require "rails_helper"

RSpec.describe FormTaskListService do
  describe "forms overview when Welsh translations are disabled" do
    let(:form) { create(:form, :new_form) }
    let(:group) { create(:group, name: "Form owner") }
    let(:editor) { create(:user, role: :super_admin) }

    before do
      GroupForm.create!(form_id: form.id, group_id: group.id)
      allow(Settings.features.welsh_translation).to receive(:enabled).and_return(false)
    end

    it "builds the overview without invoking a route which is not registered" do
      service = described_class.call(form: form, current_user: editor)
      sections = nil
      expect { sections = service.all_sections }.not_to raise_error

      names = sections.map { |section| section[:title] }
      expect(names).not_to include(I18n.t("forms.task_list_create.translations_section.title"))
      expect(names).to include(I18n.t("forms.task_list_create.make_form_live_section.title"))
    end

    it "excludes disabled Welsh tasks from the progress total" do
      service = described_class.call(form: form, current_user: editor)
      expect(service.task_counts[:total]).to be >= 1
      expect(service.send(:statuses_by_user)).not_to have_key(:welsh_language_status)
    end
  end
end
