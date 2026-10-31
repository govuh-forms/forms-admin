src=Form.find(17)
raise "Wrong source" unless src.live? && src.group&.name=="Cabinet Office correspondence"
title="Request an internal review of a Cabinet Office FOI response"
f=Form.find_by(name:title)
unless f
  f=FormCopyService.new(src,User.find(src.creator_id)).copy(tag:"live")
  raise "Copy failed" unless f && f.draft? && f.pages.count==4
  f.update!(name:title,what_happens_next_markdown:"The Cabinet Office will consider the review under the section 47 Code of Practice. Reviews should normally be completed within 20 working days. You will receive the outcome and Information Commissioner complaint details.",privacy_policy_url:"https://www.gov.uhrblx.com/help/privacy-notice")
  q=["What name should we use for this review?","What email address can we use to reply?","What was the reference number of your FOI request?","Why are you asking for an internal review?"]
  f.pages.order(:position).zip(q).each{|p,question|p.update!(question_text:question,is_optional:false)}
  f.update!(submission_email:src.submission_email)
  dc=src.delivery_configurations.first
  f.delivery_configurations.create!(delivery_method:dc.delivery_method,delivery_schedule:dc.delivery_schedule,formats:dc.formats)
  f.save_question_changes!
end
raise "Unexpected state" unless f.draft? && f.pages.count==4 && f.delivery_configurations.count==1
puts "FOI_REVIEW_DRAFT id=#{f.id} valid=#{f.valid?} published=#{f.is_live?}"
