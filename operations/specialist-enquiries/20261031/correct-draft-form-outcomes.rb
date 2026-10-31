updates = {
  19 => "The Cabinet Office will review how it handled your information request. It normally aims to complete an internal review within 20 working days. You will receive an explanation of the outcome and how to complain to the Information Commissioner.",
  20 => "The Cabinet Office will consider your complaint and explain its response. It will also tell you how to seek a further review, if one is available.",
  22 => "The National Employment Service will email you about the help you need with work, training or volunteering. Employers remain responsible for selecting and appointing applicants.",
  23 => "The Health and Safety Executive will review your report and may contact you for more information. It will decide what action, if any, to take within its responsibilities.",
  24 => "Acas will review your enquiry and explain the employment-relations advice or conciliation options available to you.",
  25 => "The External, Alliance and Cooperation Office will review your enquiry and explain what Entry Advice or consular assistance is available. Entry Advice is not immigration permission."
}
updates.each do |id,text|
  f=Form.find(id)
  raise "Live or missing form #{id}" unless f.draft?
  f.update!(what_happens_next_markdown:text)
  f.save_question_changes!
  raise "Invalid form #{id}" unless f.reload.valid? && f.draft?
  puts "COPY_UPDATED_DRAFT #{id}"
end
