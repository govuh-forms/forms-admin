# GOV.UH Forms — ministerial expression of interest, native editor record

Date: 15 October 2026
Product: GOV.UH Forms Admin (upstream GOV.UK Forms)
Form ID: 1
Editor route: https://admin.forms.service.gov.uhrblx.com/forms/1
Service owner: Chief Minister’s Office
Status: **DRAFT — NOT OPEN FOR SUBMISSIONS**

## Actual state in the Forms Admin database

Created through the running, authorised GOV.UH Forms Admin Rails application using its original `CreateFormService`, `Group`, `Page.create_and_update_form!` and `Form` models. This is a real native form held in GOV.UH PostgreSQL, not an HTML imitation, a GitHub mock-up, or a Google Sheet. The existing NES form (ID 2) was preserved.

- One organisation-owned editor group: **Ministerial expressions of interest**, attached to the existing Chief Minister’s Office organisation in the Forms catalogue.
- One draft form: **Express an interest in ministerial service**, ID **1**, slug `express-an-interest-in-ministerial-service`.
- Nine native question pages in approved order. Five required questions: preferred name (text), contact email (email), policy interests (long text), reason for interest (long text), availability (long text). Four optional questions: portfolio interest, relevant experience, currently held public/political/operational office and communication adjustments.
- The native draft FormDocument has exactly nine steps. `question_section_completed=true` and `declaration_section_completed=true`. The declaration makes clear an EOI does not constitute employment application, offer or appointment.
- `state=draft`, `live=false`, zero delivery configurations, no recipient email and no privacy-policy URL. No public acceptance is asserted; `https://submit.forms.service.gov.uhrblx.com/form/1` was HTTP 404, correctly remaining unavailable.
- The actual GOV.UK Forms task checklist reports precisely four remaining items: privacy policy; support/contact details; shared preview/review; authorised submission email. A form is not made live merely by inserting data into its draft tables.

**Office access boundary:** the native group belongs to the Chief Minister’s Office. Initial technical authoring used the existing GOV.UH Forms super-administrator account; no new official, role grant, office-holder or fabricated user account was created. No person has been appointed, and the technical action does not confer authority to open the process. Organisation member/editor provisioning and revocation must be verified through the native identity and group-management workflow before operational use.

## Database integrity

- Before: one live NES form with six question pages, no group.
- After: two forms; nine pages attached to ministerial EOI ID 1, with an owner group, and the original six NES question pages retained.
- A PostgreSQL custom-format backup **before** was saved on the VPS at `/srv/uhde/backups/govuh-forms-admin/20261015/pre-ministerial-draft.dump`.
- A PostgreSQL custom-format backup **after** was saved at `/srv/uhde/backups/govuh-forms-admin/20261015/with-ministerial-draft.dump`.
- Both backups were stored in a directory with permission 0700 and files with permission 0600. The pre-change dump restored to a separate DB (1 form, 6 pages, 0 groups); the post-change dump restored to a separate DB (2 forms, 9 pages on form 1, one group-to-form association). Temporary restore databases must be removed after verification.

## Submissions and casework

**Do not publish yet.** The operative Coth ministry formation decision explicitly requires a suitable recipient, lawful service-specific privacy information, accessible preview, institutional records and a competent opening decision. The Chief Minister’s Office, not Forms Admin or a temporary Google Sheet, must own the subsequent pre-appointment casework and correspondence.

The restricted temporary Google EOI register was checked read-only on 15 October; the EOI, briefing and audit tabs contained **zero populated case rows**, so no existing case records are waiting to migrate. Future submissions must be received and retained in a **GOV.UH-owned institutional casework/records application** with identity, access, audit and retention controls. The UK Home Office HOCS source candidate already exists on the VPS, but it has not passed the runtime/authentication/data-component acceptance necessary to receive live sensitive ministerial casework. No shadow email inbox, HR database or universal `/staff` directory may be substituted as the authoritative EOI case record.

### Completion checks before opening

1. Provision an authorised Chief Minister’s Office editor and recipient, with independent reviewer, through native Forms Admin access mechanisms.
2. Set a verified GOV.UH-owned receiving address / supported delivery route and prove real successful and failed submission handling into the institution's accepted casework application.
3. Approve and publish the service privacy notice with proper lawful basis and retention rules, and enter verified support contacts.
4. Preview/review all nine questions, validation, optionality, accessible navigation and confirmation.
5. Publish the separate GOV.UH start page through native Whitehall Publisher using the actual live Runner URL (not a guessed form number).
6. Obtain the competent opening authorisation, then make the form live using native editor publication and test the public journey.

No subscription or paid browser operation was required for the actual native draft authoring.
