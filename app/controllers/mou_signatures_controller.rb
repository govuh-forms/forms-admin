class MouSignaturesController < WebController
  before_action :set_agreement_type
  before_action :set_organisation
  before_action :require_authorised_signatory, only: :create

  def show
    return redirect_to new_non_crown_agreement_signature_path if @agreement_type == :non_crown

    @mou_signature = current_organisation_agreement
    return redirect_to new_path if @mou_signature.nil?

    redirect_to show_path unless request.path == show_path
  end

  def new
    return render :non_crown_pending if @agreement_type == :non_crown
    return redirect_to show_path if already_signed?

    @delegation_targets = MouDelegation.currently_valid
      .where(user: current_user)
      .joins(:organisation)
      .includes(:organisation)
      .order("organisations.name") if current_user.has_access?

    # Keep the existing route. Delegated signatories choose the participating
    # organisation before a request is associated with it; no group switching
    # or impersonation is involved.
    if params[:organisation_id].blank? && !directly_authorised? &&
        @delegation_targets.present?
      render :select_organisation
      return
    end

    @mou_signature = MouSignature.new(organisation: @organisation)
    render :review unless authorised_signatory?
  end

  def create
    return head :forbidden if @agreement_type == :non_crown
    return redirect_to show_path if already_signed?

    @mou_signature = MouSignature.new(mou_signature_params)
    @mou_signature.user = current_user
    @mou_signature.organisation = @organisation
    @mou_signature.mou_delegation = @delegation
    @mou_signature.agreement_type = :crown
    @mou_signature.accepted_document_version = MouSignature::CURRENT_CROWN_EDITION
    @mou_signature.document_sha256 = MouSignature.current_crown_document_sha256

    recorded = MouSignature.transaction do
      @delegation&.lock!
      @mou_signature.save
    end

    if recorded
      redirect_to confirmation_path
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @mou_signature.errors.add(:base, "This edition has already been accepted for the organisation")
    render :new, status: :unprocessable_content
  end

  def confirmation
    return redirect_to new_non_crown_agreement_signature_path if @agreement_type == :non_crown

    record = current_organisation_agreement
    return redirect_to new_path if record.nil?

    redirect_to show_path unless record.user_id == current_user.id
  end

  private

  def mou_signature_params
    params.require(:mou_signature).permit(:agreed, :authority_confirmed, :signatory_capacity)
  end

  def already_signed?
    current_organisation_agreement.present?
  end

  def current_organisation_agreement
    MouSignature.find_by(
      organisation: @organisation,
      agreement_type: :crown,
      accepted_document_version: MouSignature::CURRENT_CROWN_EDITION,
    )
  end

  def set_agreement_type
    @agreement_type = params.require(:agreement_type).to_sym
    raise ActionController::RoutingError, "Invalid agreement type" unless %i[crown non_crown].include?(@agreement_type)
  end

  def set_organisation
    @organisation = if params[:organisation_id].present?
                      Organisation.find(params[:organisation_id])
                    else
                      current_user.organisation
                    end
    @delegation = MouDelegation.current_for(user: current_user, organisation: @organisation)
    @create_path = create_path
  end

  def directly_authorised?
    current_user.organisation_admin? &&
      current_user.has_access? && !current_user.disabled? &&
      current_user.organisation_id == @organisation&.id &&
      @organisation.slug != "government-digital-service"
  end

  def authorised_signatory?
    !acting_as? && (directly_authorised? || @delegation&.active?)
  end

  def require_authorised_signatory
    head :forbidden unless authorised_signatory?
  end

  def organisation_query
    return {} unless params[:organisation_id].present?

    { organisation_id: @organisation.id }
  end

  def new_path
    @agreement_type == :crown ? new_mou_signature_path(**organisation_query) : new_non_crown_agreement_signature_path
  end

  def show_path
    @agreement_type == :crown ? mou_signature_path(**organisation_query) : non_crown_agreement_signature_path
  end

  def create_path
    @agreement_type == :crown ? mou_signature_path(**organisation_query) : non_crown_agreement_signature_path
  end

  def confirmation_path
    @agreement_type == :crown ? confirmation_mou_signature_path(**organisation_query) : confirmation_non_crown_agreement_signature_path
  end
end
