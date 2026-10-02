# frozen_string_literal: true

namespace :forms do
  desc "import a form from a form_document JSON file into a group"
  task :import_from_document, %i[file_path group_name] => :environment do |_, args|
    usage_message = "usage: rake forms:import_from_document[<file_path>, <group_name>]"
    abort usage_message if args[:file_path].blank? || args[:group_name].blank?
    abort "File not found: #{args[:file_path]}" unless File.exist?(args[:file_path])

    json = JSON.parse(File.read(args[:file_path]))
    content = json["content"]
    steps = content["steps"]

    group = Group.find_by!(name: args[:group_name])
    Rails.logger.info "forms:import_from_document: importing into group #{group.id} (\"#{group.name}\")"

    dont_copy = %w[created_at updated_at first_made_live_at submission_email
                   s3_bucket_aws_account_id s3_bucket_name s3_bucket_region]
    to_copy = Form::FORM_DOCUMENT_ATTRIBUTES.map(&:to_s) - dont_copy

    ActiveRecord::Base.transaction do
      form = Form.new
      form.assign_attributes(content.slice(*to_copy))
      form.state = "draft"
      form.save!
      Rails.logger.info "forms:import_from_document: created form #{form.id} (\"#{form.name}\")"

      step_page_map = {}
      steps.each do |step|
        data = step["data"]
        page = form.pages.build(
          position:          step["position"],
          question_text:     data["question_text"],
          hint_text:         data["hint_text"],
          answer_type:       data["answer_type"],
          is_optional:       data["is_optional"],
          answer_settings:   data["answer_settings"],
          page_heading:      data["page_heading"],
          guidance_markdown: data["guidance_markdown"],
          is_repeatable:     data["is_repeatable"],
        )
        page.save!
        step_page_map[step["id"]] = page
      end
      Rails.logger.info "forms:import_from_document: created #{step_page_map.size} pages"

      exit_page_map = {}
      steps.each do |step|
        page = step_page_map[step["id"]]
        (step["exit_pages"] || []).each do |ep|
          new_ep = page.exit_pages.build(heading: ep["heading"], markdown: ep["markdown"])
          new_ep.save!
          exit_page_map[ep["id"]] = new_ep
        end
      end
      Rails.logger.info "forms:import_from_document: created #{exit_page_map.size} exit pages"

      condition_count = 0
      steps.each do |step|
        (step["routing_conditions"] || []).each do |cd|
          condition = Condition.new(
            routing_page:       step_page_map[cd["routing_page_id"]],
            check_page:         step_page_map[cd["check_page_id"]],
            goto_page:          step_page_map[cd["goto_page_id"]],
            answer_value:       cd["answer_value"],
            skip_to_end:        cd["skip_to_end"] || false,
            exit_page_heading:  cd["exit_page_heading"],
            exit_page_markdown: cd["exit_page_markdown"],
          )
          condition.exit_page = exit_page_map[cd["exit_page_id"]] if cd["exit_page_id"].present?
          condition.save!
          condition_count += 1
        end
      end
      Rails.logger.info "forms:import_from_document: created #{condition_count} routing conditions"

      form.touch

      GroupForm.create!(form: form, group: group)
      Rails.logger.info "forms:import_from_document: linked form #{form.id} to group #{group.id}"
    end
  end
end
