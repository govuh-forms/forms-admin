# A narrowly scoped, institution-issued authority to accept one edition of
# the GOV.UH Forms Crown memorandum. This does not grant access to any forms,
# groups, submissions, publishing, or the wider government estate.
class MouDelegation < ApplicationRecord
  CURRENT_EDITION = MouSignature::CURRENT_CROWN_EDITION
  attr_accessor :delegate_email

  belongs_to :organisation
  belongs_to :user
  belongs_to :granted_by, class_name: "User"
  belongs_to :revoked_by, class_name: "User", optional: true

  has_paper_trail

  attr_readonly :organisation_id, :user_id, :granted_by_id,
                :agreement_edition, :authority_reference,
                :authorising_officer_name, :authority_scope,
                :authority_confirmed, :expires_on

  scope :currently_valid, -> {
    where(revoked_at: nil, agreement_edition: CURRENT_EDITION)
      .where("expires_on >= ?", Date.current)
  }

  validates :agreement_edition, inclusion: { in: [CURRENT_EDITION] }
  validates :authority_reference, presence: true, length: { minimum: 6, maximum: 500 }
  validates :authorising_officer_name, presence: true, length: { maximum: 180 }
  validates :authority_scope, presence: true, length: { minimum: 15, maximum: 600 }
  validates :expires_on, presence: true
  validates :authority_confirmed, inclusion: { in: [true] }, on: :create
  validate :future_expiry, on: :create
  validate :competent_grantor, on: :create
  validate :eligible_delegate, on: :create
  validate :revocation_is_complete, on: :update

  def self.current_for(user:, organisation:)
    return nil if user.blank? || organisation.blank? || (!user.has_access? || user.disabled?)

    currently_valid.find_by(user:, organisation:)
  end

  def active?
    revoked_at.nil? &&
      expires_on.present? && expires_on >= Date.current &&
      agreement_edition == CURRENT_EDITION &&
      user&.has_access? && !user.disabled?
  end

  def revoke!(actor:, reason:)
    raise ActiveRecord::RecordInvalid, self unless
      actor&.organisation_admin? && actor.has_access? &&
      actor.organisation_id == organisation_id &&
      actor.id != user_id &&
      reason.to_s.strip.present?

    with_lock do
      raise ActiveRecord::RecordInvalid, self if revoked_at.present?

      update!(revoked_at: Time.current,
              revoked_by: actor,
              revocation_reason: reason.to_s.strip)
    end
  end

  private

  def future_expiry
    errors.add(:expires_on, "must be in the future") if expires_on && expires_on <= Date.current
  end

  def competent_grantor
    return if granted_by&.organisation_admin? &&
              granted_by.has_access? && !granted_by.disabled? &&
              granted_by.organisation_id == organisation_id &&
              organisation&.slug != "government-digital-service"

    errors.add(:base, "An active organisation administrator must record the delegation for their own organisation")
  end

  def eligible_delegate
    return if user&.has_access? && !user.disabled? && user.id != granted_by_id

    errors.add(:user, "must be an existing, different Forms account with access")
  end

  def revocation_is_complete
    return unless revoked_at_changed?

    if revoked_at.present? && (revoked_by.blank? || revocation_reason.blank?)
      errors.add(:base, "Revocation must identify the administrator and reason")
    end
  end
end
