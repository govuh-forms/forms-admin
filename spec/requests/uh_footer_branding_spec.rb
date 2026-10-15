require "rails_helper"

RSpec.describe "UH Forms footer branding", type: :request do
  it "renders the approved UH coat of arms above the correct copyright link" do
    get sign_in_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('alt="United Hampshire Coat of Arms"')
    expect(response.body).to include("/images/uh-footer-coat-of-arms.webp")
    expect(response.body).to include("UH Crown copyright")
    expect(response.body).not_to include("govuk-footer__copyright-logo")
  end

  it "preserves the GOV.UH licensing and accessible footer links" do
    get sign_in_path

    expect(response.body).to include("Open Government Licence v3.0")
    expect(response.body).to include("Accessibility statement")
    expect(response.body).to include("Cookies")
    expect(response.body).to include("Privacy")
  end
end
