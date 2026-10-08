require "set"

# GOV.UK is the canonical source for organisations, so we need to keep our
# organisations up-to-date in order to provide accurate information on user
# membership of organisations.
#
# Based on similar code in Signon app:
# https://github.com/alphagov/signon/blob/b7a53e282c55d8ef3ab6369a7cb358b6ae100d27/lib/organisations_fetcher.rb
class OrganisationsFetcher
  def call(dry_run: false)
    organisations.each do |organisation_data|
      if dry_run
        show_pending_organisation_update_or_creation(organisation_data)
      else
        update_or_create_organisation(organisation_data)
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    raise "Couldn't save organisation #{e.record.slug} because: #{e.record.errors.full_messages.join(',')}"
  end

private

  # The Forms Admin organisation list is owned by the GOV.UH publishing
  # directory, not the equivalent UK government directory.
  # The GOV.UH content endpoint returns grouped organisation summaries.
  GOVUH_ORGANISATIONS_URI = URI("https://www.gov.uhrblx.com/api/content/government/organisations")

  def organisations
    @organisations ||= Enumerator.new do |yielder|
      response = get_json(GOVUH_ORGANISATIONS_URI)
      groups = response.fetch(:details)
      raise "GOV.UH directory response has no organisation collections" unless groups.is_a?(Hash)

      seen = Set.new
      groups.each do |key, entries|
        next unless key.to_s.start_with?("ordered_")
        raise "Invalid GOV.UH organisation collection: #{key}" unless entries.is_a?(Array)

        entries.each do |entry|
          slug = entry[:slug].to_s.strip
          content_id = entry[:content_id].to_s.strip
          name = entry[:title].to_s.strip
          next if slug.empty? || content_id.empty? || name.empty?
          next unless seen.add?(content_id)

          yielder << {
            title: name,
            details: {
              content_id:,
              slug:,
              abbreviation: entry[:acronym].presence,
              govuk_status: entry[:closed_at].present? || entry[:govuk_status] == "closed" ? "closed" : "live",
            },
          }
        end
      end

      raise "GOV.UH organisation directory returned no usable organisations" if seen.empty?
    end
  end

  def update_or_create_organisation(organisation_data)
    govuk_content_id = organisation_data[:details][:content_id]
    slug = organisation_data[:details][:slug]

    organisation = Organisation.find_by(govuk_content_id:) ||
      Organisation.find_by(slug:) ||
      Organisation.new(govuk_content_id:)

    organisation.update!(allocate_update_data(organisation_data))
  end

  def show_pending_organisation_update_or_creation(organisation_data)
    update_data = allocate_update_data(organisation_data)

    unless (organisation = Organisation.find_by(govuk_content_id: update_data[:govuk_content_id]) || Organisation.find_by(slug: update_data[:slug]))
      Rails.logger.info "Organisation Fetcher: Creating #{organisation_data[:title]} #{update_data}"
      return
    end

    organisation_attributes = organisation.attributes.symbolize_keys.slice(*update_data.keys)

    if organisation_attributes != update_data
      organisation.assign_attributes(**update_data)

      Rails.logger.info "Organisation Fetcher: Updating #{organisation_data[:title]} #{organisation.changes_to_save}"
    end
  end

  def get_json_with_subsequent_pages(uri)
    next_page_uri = uri
    Enumerator.new do |yielder|
      while next_page_uri
        page = get_json(next_page_uri)
        page[:results].each { |i| yielder << i }
        next_page_uri = page.key?(:next_page_url) ? URI(page[:next_page_url]) : nil
      end
    end
  end

  def get_json(uri)
    response = Net::HTTP.get_response(uri)
    if response.is_a? Net::HTTPSuccess
      JSON.parse(response.body, symbolize_names: true)
    else
      raise "error fetching organisations: #{response.code}: #{response.body}"
    end
  end

  def allocate_update_data(organisation_data)
    {
      govuk_content_id: organisation_data[:details][:content_id],
      slug: organisation_data[:details][:slug],
      name: organisation_data[:title],
      abbreviation: organisation_data[:details][:abbreviation],
      closed: organisation_data[:details][:govuk_status] == "closed",
    }
  end
end
