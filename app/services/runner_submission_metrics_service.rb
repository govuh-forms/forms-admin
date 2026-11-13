# Native Forms runner usage statistics. The reporting role can read aggregates
# but cannot access submitted answers, addresses or other casework records.
class RunnerSubmissionMetricsService
  def self.available?
    ENV["RUNNER_METRICS_DATABASE_URL"].present?
  end

  def self.collection_start_date
    return nil unless available?

    connect do |db|
      started = db.exec("SELECT collection_started_at FROM form_metrics_configuration LIMIT 1").first&.fetch("collection_started_at")
      started && Time.zone.parse(started).to_date
    end
  rescue PG::Error => e
    Rails.logger.warn("Forms usage collection start unavailable: #{e.class.name}")
    nil
  end

  def self.full_report_available?
    # The collection day was incomplete; the first complete day is the next day.
    start = collection_start_date
    start.present? && start < (Time.zone.today - 7)
  end

  def self.connect(&block)
    PG.connect(ENV.fetch("RUNNER_METRICS_DATABASE_URL"), connect_timeout: 3, &block)
  end

  def initialize(form_id)
    @form_id = Integer(form_id)
  end

  def past_week_metrics_data
    return nil unless self.class.available?

    end_date = Time.zone.today
    start_date = end_date - 7
    totals = self.class.connect do |db|
      db.exec_params(<<~SQL, [@form_id, start_date.iso8601, end_date.iso8601]).first
        SELECT COALESCE(SUM(completed_count), 0)::bigint AS completed_count,
               COALESCE(SUM(started_count), 0)::bigint AS started_count
        FROM form_submission_daily_summary
        WHERE form_id = $1 AND activity_date >= $2::date AND activity_date < $3::date
      SQL
    end
    { weekly_submissions: totals.fetch("completed_count").to_i,
      weekly_starts: self.class.full_report_available? ? totals.fetch("started_count").to_i : nil }
  rescue PG::Error => e
    Rails.logger.warn("Forms usage reporting unavailable: #{e.class.name}")
    nil
  end

  def daily_metrics_data(start_time)
    raise "Complete usage data not yet available" unless self.class.full_report_available?
    start_date = [start_time.to_date, self.class.collection_start_date + 1.day].max
    data = self.class.connect do |db|
      db.exec_params(<<~SQL, [@form_id, start_date.iso8601, Time.zone.today.iso8601]).to_a
        SELECT activity_date::text, completed_count::bigint, started_count::bigint
        FROM form_submission_daily_summary
        WHERE form_id = $1 AND activity_date >= $2::date AND activity_date < $3::date
      SQL
    end
    { submissions: data.to_h { |r| [r.fetch("activity_date"), r.fetch("completed_count").to_i] },
      starts: data.to_h { |r| [r.fetch("activity_date"), r.fetch("started_count").to_i] } }
  end
end
