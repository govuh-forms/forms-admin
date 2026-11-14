class MouDelegationsController < WebController
  before_action :require_organisation_grantor, only: %i[new create revoke]

  def index
    own = MouDelegation.where(user: current_user)
    @delegations = if organisation_grantor?
                     MouDelegation.where(organisation: current_user.organisation)
                       .or(own)
                   else
                     own
                   end
    @delegations = @delegations.includes(:organisation, :user, :granted_by).order(created_at: :desc)
  end

  def new
    @delegation = MouDelegation.new
  end

  def create
    permitted = delegation_params
    @delegation = MouDelegation.new(permitted.except(:delegate_email))
    @delegation.delegate_email = permitted[:delegate_email].to_s.strip
    @delegation.user = User.find_by("lower(email) = ?", @delegation.delegate_email.downcase)
    @delegation.organisation = current_user.organisation
    @delegation.granted_by = current_user
    @delegation.agreement_edition = MouSignature::CURRENT_CROWN_EDITION

    if @delegation.save
      redirect_to mou_delegations_path, notice: "Delegated MOU authority recorded for #{@delegation.organisation.name}"
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @delegation.errors.add(:base, "An unrevoked delegation already exists for this person and organisation")
    render :new, status: :unprocessable_content
  end

  def revoke
    @delegation = MouDelegation.where(organisation: current_user.organisation).find(params[:id])
    reason = params[:revocation_reason].to_s.strip
    if reason.blank?
      redirect_to mou_delegations_path, alert: "Enter a reason for revocation"
      return
    end

    @delegation.revoke!(actor: current_user, reason:)
    redirect_to mou_delegations_path, notice: "Delegation revoked"
  rescue ActiveRecord::RecordInvalid
    redirect_to mou_delegations_path, alert: "This delegation could not be revoked"
  end

  private

  def delegation_params
    params.require(:mou_delegation).permit(
      :delegate_email, :authority_reference, :authorising_officer_name,
      :authority_scope, :expires_on, :authority_confirmed,
    )
  end

  def organisation_grantor?
    current_user.organisation_admin? &&
      current_user.has_access? && !current_user.disabled? &&
      current_user.organisation.present? &&
      current_user.organisation.slug != "government-digital-service" &&
      !acting_as?
  end

  def require_organisation_grantor
    head :forbidden unless organisation_grantor?
  end
end
