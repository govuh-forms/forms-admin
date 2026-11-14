class CreateMouDelegations < ActiveRecord::Migration[8.1]
  def change
    create_table :mou_delegations do |t|
      t.references :organisation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.references :revoked_by, null: true, foreign_key: { to_table: :users }
      t.string :agreement_edition, null: false
      t.string :authority_reference, null: false, limit: 500
      t.string :authorising_officer_name, null: false, limit: 180
      t.text :authority_scope, null: false
      t.boolean :authority_confirmed, null: false, default: false
      t.date :expires_on, null: false
      t.datetime :revoked_at
      t.text :revocation_reason
      t.timestamps
    end

    add_index :mou_delegations,
      %i[organisation_id user_id agreement_edition],
      unique: true,
      where: "revoked_at IS NULL",
      name: "index_current_mou_delegations_by_org_and_user"
    add_check_constraint :mou_delegations,
      "expires_on > created_at::date",
      name: "mou_delegations_positive_term"
    add_check_constraint :mou_delegations,
      "(revoked_at IS NULL AND revoked_by_id IS NULL AND revocation_reason IS NULL) OR (revoked_at IS NOT NULL AND revoked_by_id IS NOT NULL AND length(trim(revocation_reason)) > 0)",
      name: "mou_delegations_complete_revocation"

    add_reference :mou_signatures, :mou_delegation,
                  null: true, foreign_key: { on_delete: :restrict }
  end
end
