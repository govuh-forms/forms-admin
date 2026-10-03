require "uri"
class PaymentLinkValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return true if payment_url?(value)

    record.errors.add attribute, :url
  end

private

  def payment_url?(value)
    uri = URI(value)
    approved = URI(Settings.uh_payments.approved_origin.to_s)
    return false unless approved.scheme == "https" && approved.host.present? &&
      approved.host.end_with?(".gov.uhrblx.com") && approved.port == 443 &&
      approved.userinfo.nil? && approved.query.nil? && approved.fragment.nil? &&
      ["", "/"].include?(approved.path)

    uri.scheme == "https" && uri.host == approved.host && uri.port == 443 &&
      uri.userinfo.nil? && uri.query.nil? && uri.fragment.nil? &&
      uri.path.start_with?("/payments/") && uri.path.length > "/payments/".length
  rescue URI::InvalidURIError
    false
  end
end
