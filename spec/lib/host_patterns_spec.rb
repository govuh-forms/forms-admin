require_relative "../../lib/host_patterns"
require "rails_helper"

RSpec.describe HostPatterns do
  def host_allowed?(host)
    described_class.allowed_host_patterns.any? { |pattern| pattern.match?(host) }
  end

  it "allows only local probing while a public UH hostname is unapproved" do
    allow(ENV).to receive(:fetch).with("APPROVED_UH_FORMS_ADMIN_HOST", "").and_return("")
    expect(host_allowed?("127.0.0.1")).to be true
    expect(host_allowed?("localhost")).to be true
    expect(host_allowed?("admin.forms.service.gov.uk")).to be false
    expect(host_allowed?("forms-admin.publishing.service.gov.uhrblx.com")).to be false
    expect(described_class.mailer_host).to eq("forms-admin-unconfigured.invalid")
  end

  it "only accepts the exact separately approved UH hostname" do
    allow(ENV).to receive(:fetch).with("APPROVED_UH_FORMS_ADMIN_HOST", "").and_return("forms-admin.publishing.service.gov.uhrblx.com")
    expect(host_allowed?("forms-admin.publishing.service.gov.uhrblx.com")).to be true
    expect(described_class.mailer_host).to eq("forms-admin.publishing.service.gov.uhrblx.com")
    %w[admin.forms.service.gov.uk forms-admin.publishing.service.gov.uhrblx.com.attacker.tld
       evilforms-admin.publishing.service.gov.uhrblx.com forms-admin.publishing.service.gov.uhrblx.com.evil].each do |host|
      expect(host_allowed?(host)).to be false
    end
  end

  it "rejects an unapproved or invalid configured hostname" do
    ["admin.forms.service.gov.uk", "https://forms-admin.gov.uhrblx.com", "forms-admin.gov.uhrblx.com:443", "evil.gov.uhrblx.com.evil"].each do |bad|
      allow(ENV).to receive(:fetch).with("APPROVED_UH_FORMS_ADMIN_HOST", "").and_return(bad)
      expect(described_class.approved_uh_host).to be_nil
      expect(host_allowed?(bad)).to be false
    end
  end
end
