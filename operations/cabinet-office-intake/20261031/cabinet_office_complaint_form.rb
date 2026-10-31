# A service-specific complaint form under the existing Cabinet Office receiving group.
source=Form.find(17)
raise "Unexpected source" unless source.is_live? && source.group&.name=="Cabinet Office correspondence"
title="Complain about a Cabinet Office service"
f=Form.find_by(name:title)
unless f
  f=FormCopyService.new(source,User.find(source.creator_id)).copy(tag:"live")
  raise "Copy failed" unless f && f.draft? && f.pages.count==4
  f.update!(name:title,privacy_policy_url:"https://www.gov.uhrblx.com/help/privacy-notice",what_happens_next_markdown:"The Cabinet Office will record and classify your complaint under its Information Rights, Correspondence and Casework Procedure. The responsible team will review it and explain the outcome and any further review route.",support_url:"https://www.gov.uhrblx.com/government/organisations/cabinet-office",support_url_text:"Cabinet Office")
  items=[
    ["What name should we use?","Give the name you use for this correspondence."],
    ["What email address can we use to reply?","Give a working email address for a response."],
    ["Which Cabinet Office service or action is your complaint about?","Name the office, service or decision if you know it."],
    ["What happened and when?","Describe your concern and include dates or relevant details. Do not include passwords or secret account credentials."]
  ]
  f.pages.order(:position).zip(items).each{|p,(q,h)|p.update!(question_text:q,hint_text:h,is_optional:false)}
  Page.create_and_update_form!(form:f,question_text:"What would you like the Cabinet Office to do?",hint_text:"Explain what you would consider a satisfactory response.",answer_type:"text",is_optional:false)
  Page.create_and_update_form!(form:f,question_text:"Do you have a relevant case or correspondence reference?",hint_text:"If you have a reference, enter it here. Leave blank if you do not.",answer_type:"text",is_optional:true)
  f.update!(submission_email:source.submission_email)
  dc=source.delivery_configurations.first
  raise "Unexpected delivery method" unless dc&.email? && dc.immediate?
  f.delivery_configurations.create!(delivery_method:dc.delivery_method,delivery_schedule:dc.delivery_schedule,formats:dc.formats)
  f.save_question_changes!
end
f.reload
raise "Unexpected complaint form" unless f.draft? && f.pages.count==6 && f.delivery_configurations.count==1
puts "CABINET_OFFICE_COMPLAINT_DRAFT id=#{f.id} valid=#{f.valid?} steps=#{f.draft_form_document.content.fetch("steps",[]).size} published=#{f.is_live?}"
