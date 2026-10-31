# Complete the existing native FOI draft without opening an untested submission route.
form = Form.find(18)
raise "Unexpected form" unless form.draft? && form.name == "Request recorded information from the Cabinet Office"
raise "Unexpected existing questions" unless form.pages.count == 2
raise "Delivery must remain unconfigured" unless form.delivery_configurations.empty?
name = Page.create_and_update_form!(form: form, question_text: "What name should we use for this request?", answer_type: "text", is_optional: false, hint_text: "Use your UH Name if you have one. UH registration, citizenship and linked Roblox or Discord accounts are not required.")
reply = Page.create_and_update_form!(form: form, question_text: "What email address can we use for correspondence?", answer_type: "email", is_optional: false, hint_text: "An electronic address lets us reply. The public service must also provide other accepted secure correspondence arrangements where available.")
2.times { name.move_page(:up) }
2.times { reply.move_page(:up) }
form.reload
raise "Unexpected count" unless form.pages.count == 4
raise "Unexpected state" unless form.draft? && form.delivery_configurations.empty?
puts "FOI_FORM18_DRAFT_COMPLETED pages=#{form.pages.order(:position).pluck(:question_text).inspect} public=#{form.is_live?}"
