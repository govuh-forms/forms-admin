# New native draft forms for existing organisations.
# No public publication, invented staff permissions, mailboxes or delivery configurations.
actor = User.find_by!(name: "Eeth")
source = Form.find(2)
raise "Unexpected source" unless source.archived?
privacy = "https://www.gov.uhrblx.com/help/privacy-notice"
specs = [
  {
    organisation: "health-and-safety-executive",
    group: "Health and Safety Executive — workplace concerns",
    title: "Report a workplace health and safety concern",
    support_url: "https://www.gov.uhrblx.com/government/organisations/health-and-safety-executive",
    next_steps: "The Health and Safety Executive will assess the report and decide whether to seek further information or take action, once its receiving and reporting service is open.",
    questions: [
      ["Where did the concern arise?", "Name the workplace or location. Do not include unnecessary personal information.", "text", false],
      ["Is the workplace in Havenstead or England?", "State the country and area so the report can be sent to the appropriate authority.", "text", false],
      ["What is the health and safety concern?", "Explain the hazard, what happened and who may be at risk.", "text", false],
      ["When did this happen?", "Give a date or approximate period if you know it.", "text", true],
      ["Has the concern been reported to the employer or person responsible?", "Tell us whether you raised the issue and what response you received.", "text", true],
      ["Is there an immediate danger?", "If someone is in immediate danger, contact the relevant emergency service. This form is not an emergency reporting service.", "text", false],
      ["What name should we use?", "You may leave this blank if you do not want to give your name.", "text", true],
      ["What email address can we use to contact you?", "You may leave this blank, but it may prevent an investigator contacting you for more information.", "email", true]
    ]
  },
  {
    organisation: "acas",
    group: "Acas — employment advice and conciliation enquiries",
    title: "Ask Acas for advice about a problem at work",
    support_url: "https://www.gov.uhrblx.com/government/organisations/acas",
    next_steps: "Acas will consider whether the matter concerns employment-relations advice or conciliation and explain the next step, once the enquiry service opens.",
    questions: [
      ["Where do you work?", "State whether the work is in Havenstead or England, and the area if known.", "text", false],
      ["What problem at work would you like help with?", "For example, working hours, pay, a grievance, recruitment, conduct or another employment matter.", "text", false],
      ["What happened?", "Give the relevant facts and dates. Do not include passwords or unnecessary private details.", "text", false],
      ["Have you raised the matter with your employer or appointing organisation?", "Include any response you received.", "text", true],
      ["Are you asking for advice or help with conciliation?", "You can say if you are not sure which route applies.", "text", false],
      ["What name should we use?", "Use the name you would like Acas to use.", "text", false],
      ["What email address can we use to reply?", "Enter an email address that you can access.", "email", false]
    ]
  },
  {
    organisation: "external-alliance-and-cooperation-office",
    group: "EACO — consular and Entry Advice enquiries",
    title: "Ask for Entry Advice or consular assistance",
    support_url: "https://www.gov.uhrblx.com/government/organisations/external-alliance-and-cooperation-office",
    next_steps: "EACO will identify the appropriate external or consular function and reply using the contact details provided, once the enquiry service opens. Entry Advice is not immigration permission.",
    questions: [
      ["Are you asking for Entry Advice or consular assistance?", "Explain the type of assistance or information you need.", "text", false],
      ["Which external community or location is your enquiry about?", "Give a place or community name if known.", "text", true],
      ["What help do you need?", "Describe the issue and any important dates. Do not include account passwords.", "text", false],
      ["Is anyone at immediate risk?", "If there is an immediate danger, contact the relevant emergency service. Do not use this form for emergency assistance.", "text", true],
      ["Have you contacted another organisation about this?", "Tell us which organisation and whether it responded.", "text", true],
      ["What name should we use?", "Use the name you want EACO to use in its reply.", "text", false],
      ["What email address can we use to reply?", "Use an email address you can access.", "email", false]
    ]
  }
]
specs.each do |spec|
  if (existing = Form.find_by(name: spec[:title]))
    raise "Unexpected live service" if existing.is_live?
    puts "EXISTS_DRAFT #{existing.id} #{spec[:title]}"
    next
  end
  ActiveRecord::Base.transaction do
    org = Organisation.find_by!(slug: spec[:organisation])
    group = Group.find_by(name: spec[:group], organisation: org)
    group ||= Group.create!(name: spec[:group], organisation: org, creator: actor, status: "trial")
    attrs = source.latest_form_document.content.slice(*FormCopyService::TO_COPY.map(&:to_s))
    form = Form.new(attrs)
    form.assign_attributes(name: spec[:title], creator_id: actor.id, privacy_policy_url: privacy,
                           support_url: spec[:support_url], support_url_text: org.name,
                           what_happens_next_markdown: spec[:next_steps])
    form.save!
    GroupForm.create!(form_id: form.id, group_id: group.id)
    spec[:questions].each do |question,hint,answer_type,optional|
      Page.create_and_update_form!(form: form, question_text: question, hint_text: hint,
                                   answer_type: answer_type, is_optional: optional)
    end
    form.save_question_changes!
    raise "Invalid draft" unless form.reload.draft? && form.valid? && form.pages.count == spec[:questions].length
    raise "Unexpected delivery" if form.delivery_configurations.any? || form.submission_email.present?
    puts "CREATED_DRAFT id=#{form.id} org=#{org.slug} questions=#{form.pages.count} delivery=0 public=#{form.is_live?}"
  end
end
