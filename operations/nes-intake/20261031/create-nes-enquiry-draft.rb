# New NES form using supported native Forms models, not copied from the archived Form 2.
title = "Get help finding work or training in Havenstead"
if (existing = Form.find_by(name: title))
  raise "Unexpected public release" if existing.is_live?
  puts "NES_DRAFT_EXISTS #{existing.id}"
  exit
end
actor = User.find_by!(name: "Eeth")
organisation = Organisation.find_by!(slug: "national-employment-service")
source = Form.find(2)
raise "Reference form changed" unless source.archived?
ActiveRecord::Base.transaction do
  group = Group.find_by(name: "National Employment Service enquiries", organisation: organisation)
  group ||= Group.create!(name: "National Employment Service enquiries", organisation: organisation, creator: actor, status: "trial")
  attrs = source.latest_form_document.content.slice(*FormCopyService::TO_COPY.map(&:to_s))
  f = Form.new(attrs)
  f.assign_attributes(
    name: title,
    creator_id: actor.id,
    privacy_policy_url: "https://www.gov.uhrblx.com/help/privacy-notice",
    support_url: "https://www.gov.uhrblx.com/find-work-skills-and-training",
    support_url_text: "Find work, skills and training",
    what_happens_next_markdown: "The National Employment Service will contact you about work, training or volunteering using the details you provide, once the receiving service opens."
  )
  f.save!
  GroupForm.create!(form_id: f.id, group_id: group.id)
  items = [
    ["What would you like help with?", "For example, finding a job, training, an apprenticeship, volunteering or returning to work.", "text", false],
    ["Which jobs, courses or other opportunities interest you?", "Include an occupation or course if you already know what you are looking for.", "text", false],
    ["Which area of Havenstead are you looking in?", "You can leave this blank if you are open to opportunities in any area.", "text", true],
    ["What experience, qualifications or interests would you like us to know about?", "Only include information that you want an adviser to consider.", "text", true],
    ["Do you need help with accessibility or applying for opportunities?", "Describe practical support you need. Do not include medical records.", "text", true],
    ["What name should we use?", "Use the name you want us to use when contacting you.", "text", false],
    ["What email address can we use to reply?", "Enter an email address you can access.", "email", false]
  ]
  items.each do |question, hint, kind, optional|
    Page.create_and_update_form!(form: f, question_text: question, hint_text: hint, answer_type: kind, is_optional: optional)
  end
  f.save_question_changes!
  raise "New form invalid" unless f.reload.valid? && f.draft? && f.pages.count == 7
  raise "Delivery unexpectedly configured" if f.delivery_configurations.any? || f.submission_email.present?
  puts "NES_FORM_DRAFT_CREATED id=#{f.id} group=#{group.name} group_status=#{group.status} questions=#{f.pages.count} delivery_configurations=#{f.delivery_configurations.count} live=#{f.is_live?}"
end
