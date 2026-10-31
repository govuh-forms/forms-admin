# Native draft submissions for three operating Havenstead councils.
# Creating a Forms organisation is an administrative record, not establishing a council.
actor=User.find_by!(name:"Eeth")
template=Form.find(2)
raise "Source no longer archived" unless template.archived?
councils=[
 ["Alderstead Council","alderstead-council"],
 ["Brightmere Council","brightmere-council"],
 ["Stonehaven Council","stonehaven-council"]
]
councils.each do |council,slug|
 title="Report a local service problem to #{council}"
 if (f=Form.find_by(name:title))
  raise "Unexpected live local form" if f.is_live?
  puts "ALREADY_DRAFT #{f.id} #{council}"
  next
 end
 ActiveRecord::Base.transaction do
  org=Organisation.find_by(slug:slug) || Organisation.create!(name:council,slug:slug,closed:false)
  raise "Organisation name conflict" unless org.name==council
  group=Group.find_by(name:"Local service reports",organisation:org)
  group ||= Group.create!(name:"Local service reports",organisation:org,creator:actor,status:"trial")
  f=Form.new(template.latest_form_document.content.slice(*FormCopyService::TO_COPY.map(&:to_s)))
  f.assign_attributes(name:title,creator_id:actor.id,
   privacy_policy_url:"https://www.gov.uhrblx.com/help/privacy-notice",
   support_url:"https://www.gov.uhrblx.com/find-local-council",
   support_url_text:"Find your local council",
   what_happens_next_markdown:"#{council} will review your report and tell you whether it provides the service. If another organisation is responsible, the council will explain where to report the problem.")
  f.save!
  GroupForm.create!(form_id:f.id,group_id:group.id)
  questions=[
   ["Which local service is the problem about?","For example, libraries, recreation, neighbourhoods, public information or another council service.","text",false],
   ["Where did the problem happen?","Give the town, building or local area. Do not include a private home address unless needed to explain the problem.","text",false],
   ["What is the problem?","Explain what happened and when, and what needs attention.","text",false],
   ["Have you already reported it?","Tell us when and how you reported the problem, if applicable.","text",true],
   ["What would you like the council to do?","For example, repair something, provide information or explain a decision.","text",true],
   ["What name should we use?","Enter your preferred name.","text",false],
   ["What email address can we use to reply?","Enter an email address you can access.","email",false]
  ]
  questions.each{|question,hint,kind,optional|Page.create_and_update_form!(form:f,question_text:question,hint_text:hint,answer_type:kind,is_optional:optional)}
  f.save_question_changes!
  raise "Invalid new form" unless f.reload.valid? && f.draft? && f.pages.count==7 && f.delivery_configurations.empty?
  raise "Authorisation mismatch" unless org.admin_users.empty?
  puts "LOCAL_FORM_DRAFT id=#{f.id} organisation=#{slug} questions=#{f.pages.count} live=#{f.is_live?}"
 end
end
