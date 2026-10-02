# frozen_string_literal: true

namespace :data_migrations do
  desc "backfill version for existing live and archived form documents"
  task set_version_on_form_documents: :environment do
    FormDocument.where(tag: %i[live archived]).find_each do |form_document|
      form_document.update!(version: 1) if form_document.version.nil?
      form_document.form.update!(latest_form_document: form_document) if form_document.language == "en"
    end
  end

  desc "Replace conditions with same goto_page into unconditional route for selection questions with more than 10 options with routes"
  task :rebuild_selection_question_with_more_than_10_options_routes, %i[form_id] => :environment do |_, args|
    dry_run = ENV["DRY_RUN"]

    ActiveRecord::Base.transaction do
      pages = Page
      pages = pages.where(form_id: args[:form_id]) if args[:form_id]
      pages = pages.where("answer_type = 'selection' AND answer_settings->>'only_one_option' = 'true' AND jsonb_array_length(answer_settings->'selection_options') > 10")
      pages.find_each do |page|
        next if page.routing_conditions.size < 10

        conditions_by_goto = page
          .routing_conditions
          .pluck(:id, :goto_page_id, :skip_to_end, :exit_page_id) # use pluck to avoid instantiating too many records
          .group_by { %i[goto_page_id skip_to_end exit_page_id].zip(it.drop(1)).to_h }
          .transform_values { it.map(&:first) }

        conditions_by_goto_counts = conditions_by_goto.transform_values(&:size)
        Rails.logger.info(form_id: page.form_id, page_id: page.id, selection_options_count: page.answer_settings.selection_options.size, conditions_by_goto_counts:)

        if conditions_by_goto.keys.size > 1 || page.routing_conditions.size < page.answer_settings.selection_options.size
          Rails.logger.info("skipping page #{page.id} with routes to more than one goto")
          next
        end

        unconditional_goto, conditions_to_replace = conditions_by_goto
          .each_pair.max_by { |_goto, conditions| conditions.size }

        if unconditional_goto[:exit_page_id] || (!unconditional_goto[:goto_page_id] && !unconditional_goto[:skip_to_end])
          Rails.logger.info("skipping page #{page.id} with routes to exit page")
          next
        end

        Condition.delete(conditions_to_replace)
        unconditional_condition = Condition.create!(routing_page: page, check_page: page, answer_value: nil, **unconditional_goto)

        Rails.logger.info("#{dry_run ? 'dry run: ' : ''}replaced #{conditions_to_replace.size} conditions with condition #{unconditional_condition.id}")
      end

      if dry_run
        Rails.logger.info("dry run: rolling back changes")
        raise ActiveRecord::Rollback
      end
    end
  end

  namespace :rebuild_selection_question_with_more_than_10_options_routes do
    desc "Replace conditions with same goto_page into unconditional route for selection questions with more than 10 options with routes - dry run"
    task :dry_run, [] => :environment do |_, args|
      ENV["DRY_RUN"] = "true"

      Rake::Task["data_migrations:rebuild_selection_question_with_more_than_10_options_routes"].invoke(*args)
    end
  end
end
