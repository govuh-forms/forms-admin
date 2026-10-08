if Settings.auth_provider == "gds_sso"
  GDS::SSO.config do |config|
    config.user_model = "User"
    config.oauth_id = ENV.fetch("GDS_SSO_OAUTH_ID")
    config.oauth_secret = ENV.fetch("GDS_SSO_OAUTH_SECRET")
    config.oauth_root_url = ENV.fetch("GDS_SSO_OAUTH_ROOT_URL", "https://signon.publishing.service.gov.uhrblx.com")
    config.auth_valid_for = Settings.auth_valid_for
  end
end
