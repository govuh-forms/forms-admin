class RecordFormAgreementEditionAndAuthority < ActiveRecord::Migration[8.1]
  def up
    add_column :mou_signatures, :accepted_document_version, :string
    add_column :mou_signatures, :document_sha256, :string
    add_column :mou_signatures, :signatory_capacity, :string
    add_column :mou_signatures, :authority_confirmed, :boolean, null: false, default: false

    # Preserve existing historical signatures as unsigned-to-current-edition:
    # their original acceptance checkbox, text and edition were not persisted.
    remove_index :mou_signatures, name: "index_mou_signatures_on_user_id_and_organisation_id"
    add_index :mou_signatures,
              [:organisation_id, :agreement_type, :accepted_document_version],
              unique: true,
              where: "accepted_document_version IS NOT NULL",
              name: "unique_current_form_agreement_per_organisation"
  end

  def down
    remove_index :mou_signatures, name: "unique_current_form_agreement_per_organisation"
    add_index :mou_signatures, [:user_id, :organisation_id],
              unique: true,
              name: "index_mou_signatures_on_user_id_and_organisation_id"
    remove_column :mou_signatures, :authority_confirmed
    remove_column :mou_signatures, :signatory_capacity
    remove_column :mou_signatures, :document_sha256
    remove_column :mou_signatures, :accepted_document_version
  end
end
