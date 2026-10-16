class GroupMemberInput < BaseInput
  include ActiveModel::Validations::Callbacks
  include Rails.application.routes.url_helpers

  attr_accessor :member_email_address, :group, :creator, :host, :role
  attr_reader :notification_sent

  EMAIL_REGEX = /.*@.*/

  validates :member_email_address, presence: true
  validates :role, presence: true
  validates :member_email_address, format: { with: EMAIL_REGEX, message: :invalid_email }
  validate :invited_user_has_account, if: -> { member_email_address.present? }

  before_validation :strip_whitespace

  def submit
    if invalid? || new_membership.invalid?
      copy_membership_errors
      return false
    end

    new_membership.save!
    # Membership is the authoritative access change. The notification provider
    # is optional: its absence must not turn a successful grant into HTTP 500.
    @notification_sent = send_notification_email

    true
  end

  def role_options
    Membership.roles.keys.map { |role| [I18n.t("membership.roles.#{role}"), role] }
  end

  def invited_user
    @invited_user ||= User.find_by("LOWER(email)= ?", member_email_address.downcase)
  end

private

  def new_membership
    @new_membership ||= group.memberships.new(user: invited_user, role:, added_by: creator)
  end

  def invited_user_has_account
    return if invited_user.present?

    errors.add(:member_email_address, :not_forms_user)
  end

  def copy_membership_errors
    new_membership.errors.each do |err|
      errors.add(:member_email_address, err.type)
    end
  end

  def strip_whitespace
    member_email_address&.strip!
  end

  def send_notification_email
    return false if Settings.govuk_notify.api_key.to_s.strip.empty?
    return false if Settings.govuk_notify.api_key.to_s.strip == "changeme"

    GroupMemberMailer.added_to_group(new_membership, group_url: group_url(group, host:)).deliver_now
    true
  rescue StandardError => error
    Rails.logger.warn(
      "Forms group membership saved but email notification was not confirmed",
      { group_id: group.id, user_id: invited_user.id, error_type: error.class.name }
    )
    false
  end

public

  def notification_sent?
    !!@notification_sent
  end
end
