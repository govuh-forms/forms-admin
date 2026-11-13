# Read-only aggregate counts from the Forms runner reporting view.
# The database role may read this view but not the submissions table or answers.
class RunnerSubmissionMetricsService
  def self.available?
    ENV["RUNNER_METRICS_DATABASE_URL"].present?
  end

  def initialize(form_id)
    @form_id = Integer(form_id)
  end

  def past_week_metrics_data
    return nil unless self.class.available?

    end_date = Time.zone.today
    start_date = end_date - 7
    sql = <<~SQL
      SELECT COALESCE(SUM(completed_count), 0) AS completed_count
      FROM public.form_submission_daily_summary
      WHERE form_id = $1 AND activity_date >= $2::date AND activity_date < $3::date
    SQL

    count = PG.connect(ENV.fetch("RUNNER_METRICS_DATABASE_URL"), connect_timeout: 3) do |connection|
      connection.exec_params(sql, [@form_id, start_date.iso8601, end_date.iso8601]).first.fetch("completed_count").to_i
    end

    { weekly_submissions: count, weekly_starts: nil }
  rescue PG::Error => e
    Rails.logger.warn("Forms aggregate reporting unavailable: #{e.class.name}")
    nil
  end
end
