RSpec.shared_examples "a payment link validator" do
  before do
    allow(Settings.uh_payments).to receive(:approved_origin).and_return("https://pay.gov.uhrblx.com")
  end

  it "accepts a payment link from the separately approved UH service" do
    model.public_send("#{attribute}=", "https://pay.gov.uhrblx.com/payments/test-service")
    expect(model).to be_valid
  end

  ["https://www.gov.uk/payments/test-service",
   "https://gov.uk/payments/test-service",
   "https://pay.gov.uhrblx.com.evil.invalid/payments/test-service",
   "https://pay.gov.uhrblx.com@evil.invalid/payments/test-service",
   "http://pay.gov.uhrblx.com/payments/test-service",
   "https://pay.gov.uhrblx.com/payments/test-service?redirect=evil",
   "https://pay.gov.uhrblx.com/payments/",
   "https://pay.gov.uhrblx.com/other/test-service",
   "https://gov.uk/payments/ test-org /test-service"].each do |url|
    it "rejects an unapproved payment destination: #{url}" do
      model.public_send("#{attribute}=", url)
      expect(model).to be_invalid
      expect(model.errors.map(&:type)).to include(:url)
    end
  end

  it "rejects payments when no UH service has been approved" do
    allow(Settings.uh_payments).to receive(:approved_origin).and_return(nil)
    model.public_send("#{attribute}=", "https://pay.gov.uhrblx.com/payments/test-service")
    expect(model).to be_invalid
  end
end
