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

## Forms Admin editor failure, software repair and live rollout — 15 October 2026

The Chief Minister’s Office ministerial editor URL `https://admin.forms.service.gov.uhrblx.com/forms/1` displayed GOV.UH Forms’ standard internal server error to the signed-in browser despite the valid form draft in PostgreSQL.

**Verified root cause:** `FormTaskListService#translations_section_task` unconditionally invoked `welsh_translation_path`. This route is intentionally *not registered* by `config/routes.rb` when `Settings.features.welsh_translation.enabled=false` (the current GOV.UH Forms configuration). Calling the original `FormTaskListService.call(form: Form.find(1), current_user: User.first).all_sections` raised `undefined method 'welsh_translation_path'`. The defect affects the ordinary native Rails editor task list, not the data model or the user's question content.

**Software change:** <https://github.com/govuh-forms/forms-admin/pull/13>, merged source commit `6259d68501b5fbdd43c9575376d4dce41580781d`. The task-list service now omits the disabled Welsh translation section and progress counter entry. It retains the standard upstream editor, publishing permissions, accessibility and other tasks. A new RSpec regression test records the required no-route condition.

**Verification:** With the corrected service loaded into an independent Rails process, the actual Form 1 task list returned six valid sections. A disposable Docker container running the corrected application returned HTTP 200 on its health endpoint. A non-production, in-process authenticated-controller render test of `GET /forms/1` against the actual Form 1 data returned HTTP **200**, included the title and complete native task list, and omitted the Welsh translation link. Authentication was simulated in the disposable/test process only to exercise the authorised view; no public route, production session or real user's login was bypassed or changed.

**Actual runtime deployment:** Former Forms Admin image `sha256:a0152c4572c36a9d1fcbf6d15d5f0a5807163c1fe428118bf1fb3ab0361fb035` was retained as the stopped `govuh-forms-admin-rollback-20261015` container. The source-controlled patch was placed in an additive Docker image based exactly on the former image, preserving all upstream dependencies and compiled frontend assets. New running image: `sha256:7a65ccfdff19d2af9758848e7ef4872cb7a7d799e67d96cd057de027fcd30ad4`. The replacement container retains the original service name `govuh-forms-admin-main-166a71c`, host network port `5971`, existing server configuration and original mounted volumes. The Forms Admin PostgreSQL and NES Runner containers were not redeployed.

**Post-release checks:** `https://admin.forms.service.gov.uhrblx.com/sign-in` responded HTTP **200**; unauthenticated `GET /forms/1` redirected to the native sign-in page with HTTP **302**; a separate in-process test against the *deployed* application renderer again returned HTTP **200** with Form 1 and the task list. The replacement container remained running with zero restarts on inspection. The original image and the pre/post-form backups are retained for rollback.

**Limitations not misrepresented as completion:** The actual logged-in browser cookie was not available to independent inspection, and the live authenticated user should reload and confirm the restored editor. Form 1 remains a **draft**, not publicly accepting submissions: service privacy notice, Chief Minister’s Office official receiving/casework route, access permissions, preview/review and competent service-opening decision remain required. The separately reported UK Royal Arms artwork in the GOV.UK Footer component is a branding defect and not the cause of the editor exception. Public Runner `/form/1` remains unavailable until authorised publication, which is intentional.
