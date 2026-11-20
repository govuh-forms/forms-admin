# frozen_string_literal: true
# Use inside original GOV.UH Forms Admin. Authoring only; never publish.
group = Group.find(69)
raise "Wrong organisation" unless group.organisation_id == 259 &&
  group.organisation.name == "House of Lords Appointments Commission" &&
  group.status == "active"
owner = group.memberships.find_by(role: "group_admin")&.user
raise "No authorised group administrator" unless owner&.has_access &&
  owner.can_administer_org?(group.organisation)
title = "Apply for consideration as a non-party-political life peer"
existing = group.forms.detect { |form| form.name_en == title }
if existing
  raise "Existing form was made live" if existing.has_live_version
  puts "HOLAC_EXISTING_DRAFT=#{existing.id} QUESTIONS=#{existing.pages.count}"
  exit 0
end
questions = [
  ["What is your full name?", "name", false, "Enter your forenames and surname."],
  ["What is your date of birth?", "date", false, "Eligibility requirements must be published before applications open."],
  ["Where were you born?", "text", false, "Give your place and country of birth."],
  ["What is your correspondence address?", "address", false, ""],
  ["What is your email address?", "email", false, ""],
  ["What is your daytime telephone number?", "phone_number", true, ""],
  ["Why do you wish to contribute to the House of Lords?", "text", false, "Explain your motivation for non-party-political public service."],
  ["Describe your record of achievement and relevant expertise.", "text", false, "Include professional, community and public service achievements."],
  ["How would you contribute to legislative and scrutiny work in the House of Lords?", "text", false, "Describe the experience and perspective you would bring."],
  ["Describe your current or former political party roles or affiliations.", "text", false, "Include information relevant to your independence from party-political control."],
  ["What financial, professional or other interests might give rise to conflicts?", "text", false, "Describe interests that might need to be declared or managed."],
  ["Describe any matters relevant to conduct, integrity or public standing.", "text", false, "Provide accurate context. Checks are governed by the Commission's approved procedure."],
  ["What other evidence supports your application against published criteria?", "text", true, ""],
  ["Do you need adjustments or assistance with the application process?", "text", true, "Explain any adjustments that would help you participate."]
]
long_questions = questions[6..].map(&:first)
ActiveRecord::Base.transaction do
  form = CreateFormService.new.create!(creator: owner, group: group, name: title)
  questions.each do |q,type,optional,hint|
    attrs = { form: form, question_text: q, answer_type: type, is_optional: optional }
    attrs[:hint_text] = hint if hint.present?
    attrs[:answer_settings] = { "input_type" => "long_text" } if long_questions.include?(q)
    Page.create!(**attrs)
  end
  form.save_question_changes!
  form.reload
  raise "Incomplete form draft" unless form.pages.count == questions.length &&
    form.state == "draft" && !form.has_live_version
  raise "Unauthorised delivery configuration" if form.delivery_configurations.exists?
  puts "HOLAC_NATIVE_FORMS_DRAFT_CREATED=#{form.id} QUESTIONS=#{form.pages.count} STATE=#{form.state}"
end