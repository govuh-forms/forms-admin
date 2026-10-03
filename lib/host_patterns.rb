module HostPatterns
  LOCAL_HOST_PATTERNS = [/\Alocalhost\z/, /\A127\.0\.0\.1\z/].freeze

  # The production Admin host must be an explicitly configured GOV.UH hostname.
  # Never inherit UK upstream hosts or accept arbitrary regular expressions.
  def self.approved_uh_host
    hostname = ENV.fetch("APPROVED_UH_FORMS_ADMIN_HOST", "").strip.downcase
    return nil if hostname.empty?

    return nil unless hostname.match?(/\A[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*\.gov\.uhrblx\.com\z/)

    hostname
  end

  def self.allowed_host_patterns
    host = approved_uh_host
    [*LOCAL_HOST_PATTERNS, *(host ? [/\A#{Regexp.escape(host)}\z/] : [])]
  end

  def self.mailer_host
    approved_uh_host || "forms-admin-unconfigured.invalid"
  end
end
