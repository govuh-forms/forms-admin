# Route the existing FOI draft to the existing Cabinet Office correspondence intake.
source = Form.find(17)
target = Form.find(18)
raise "Unexpected group" unless source.group == target.group && source.group.name == "Cabinet Office correspondence"
raise "FOI must remain a draft" unless target.draft? && target.pages.count == 4
raise "Existing delivery requires review" unless target.delivery_configurations.empty? && target.submission_email.blank?
raise "Missing authorised departmental recipient" unless source.submission_email.to_s.end_with?("@cabinetoffice.gov.uhrblx.com")
raise "Source not live" unless source.is_live? && source.delivery_configurations.count == 1
source_config = source.delivery_configurations.first
raise "Unexpected delivery method" unless source_config.email? && source_config.immediate?
ActiveRecord::Base.transaction do
  target.update!(submission_email: source.submission_email)
  target.delivery_configurations.create!(delivery_method: source_config.delivery_method, delivery_schedule: source_config.delivery_schedule, formats: source_config.formats)
  target.save_question_changes!
end
target.reload
raise "FOI form accidentally published" unless target.draft?
puts "FOI_DRAFT_INTAKE_CONFIGURED form=#{target.id} existing_office=#{target.group.name} immediate_email=#{target.delivery_configurations.one?} recipient_domain=#{target.submission_email.to_s.split('@').last}"
