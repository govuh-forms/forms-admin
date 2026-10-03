# The GOV.UK govuk-components 6.5.0 FooterComponent, with its view copied
# intact except for the original UK Crown SVG replaced by the approved UH
# Site Identity asset. The same slots, licensing and navigation are retained.
class UhFooterComponent < GovukComponent::FooterComponent
  UH_CROWN_COPYRIGHT_URL =
    "https://www.gov.uhrblx.com/government/organisations/the-national-archives/crown-copyright/".freeze
  UH_OGL_URL = "https://nationalarchives.gov.uhrblx.com/doc/open-government-licence/version/3/".freeze

private

  def copyright
    link_to(copyright_text, UH_CROWN_COPYRIGHT_URL, class: "#{brand}-footer__link")
  end

  def default_licence
    link = link_to("Open Government Licence v3.0", UH_OGL_URL,
                   class: "#{brand}-footer__link")
    raw(%(All content is available under the #{link}, except where otherwise stated))
  end
end
