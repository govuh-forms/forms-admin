class MouSignature < ApplicationRecord
  CURRENT_CROWN_EDITION = "UH-FORMS-CROWN-MOU-2026-10-20".freeze
  attr_accessor :agreed

  belongs_to :user
  belongs_to :organisation, optional: true

  enum :agreement_type, {
    crown: "crown",
    non_crown: "non_crown",
  }

  # A signature is a deliberate institutional acceptance, not an inference
  # from administrative or cross-organisation Forms group access.
  validates :agreed, inclusion: { in: ["1", 1, true], message: "You must accept the memorandum" }, on: :create
  validates :authority_confirmed, acceptance: { accept: true }, on: :create
  validates :signatory_capacity, presence: true, length: { maximum: 180 }, on: :create
  validates :accepted_document_version, inclusion: { in: [CURRENT_CROWN_EDITION] }, on: :create
  validates :document_sha256, format: { with: /\A[a-f0-9]{64}\z/ }, on: :create
  validate :authorised_organisation_signatory, on: :create

  def self.current_crown_document_sha256
    Digest::SHA256.file(Rails.root.join("app/views/mou_signatures/_mou_version_current.html.erb")).hexdigest
  end

  def self.add_mou_signature_organisation(user)
    mous_without_organisations = MouSignature.where(user:, organisation: nil)
    mous_without_organisations.update!(organisation_id: user.organisation.id)
  end

  private

  def authorised_organisation_signatory
    unless crown? && user&.organisation_admin? && user.has_access? &&
           organisation_id.present? && user.organisation_id == organisation_id &&
           organisation&.slug != "government-digital-service"
      errors.add(:base, "Only an authorised organisation representative can accept the memorandum")
    end
  end
end
