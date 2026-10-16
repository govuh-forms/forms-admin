# GOV.UH Forms — departmental authoring delivery and acceptance evidence

Date: 16 October 2026
Classification: implementation and acceptance evidence; **not** an official Interior Office or citizenship decision or operational case record.

## Running source and deployment
- Forms Admin application: `https://admin.forms.service.gov.uhrblx.com/`, canonical public Caddy target `127.0.0.1:5929`.
- Source change: [forms-admin PR #15](https://github.com/govuh-forms/forms-admin/pull/15), merged `369f225fb1b5b3f78afe8fc41aab39c7df1d1dfe`.
- Image `govuh/forms-admin:group-discovery-20261016`, immutable local image ID `sha256:bb2327eaaf76723c793d609ec9886826c78dac77484d16c8ca674f349ba97571`.
- Running canonical container `uh-forms-discord-admin-20261014`. Initial public HTTPS sign-in HTTP 200, unauthenticated `/groups` and group form-creation page redirect to Signon as designed; container running with zero restarts. The previous image and stopped runtime container remain available for rollback.
- Design change uses the original GOV.UK Forms application, not a custom universal `/staff` dashboard. The super-administrator's `Your groups` selector now includes departments that own Forms groups even if nobody from that organisation has yet signed in. Super-administrators can explicitly select the owning organisation at group creation, without granting themselves false cross-institutional group membership. Ordinary editors remain restricted to their own organisation.
- Tests: Ruby syntax PASS; three modified ERB files compile; the unchanged Signon page on isolated candidate serves HTTP 200 and application health /up returns HTTP 200; live-data lookup confirms the Chief Minister's Office group is discoverable without any enrolled organisational users. Source request-spec regression tests are included in PR #15, but the isolated **production** Docker image does not contain the development RSpec executable. A user-signed-in browser test of the amended `Your groups` selector remains to be collected.

## Interior Office native groups
- Existing competent Forms catalogue organisation: **Interior Office** (slug `interior-office`).
- Native group **Citizenship and status applications**, external ID `zQGRUNH5`.
- Native group **Immigration and visa applications**, external ID `LfdVUFfn`.
- Both were created through the live, authenticated application database using original Rails models and assigned to the existing Interior Office organisation. Initial status **trial**. No new user or fictional officeholder was created. There are no enrolled Interior Office Forms users yet; an authorised user must sign in through GOV.UH Signon and receive the correct organisation and group membership before ordinary human authoring can operate.
- Public access and group-activation authority remain separate; creating the group grants no citizenship or immigration decision power.

## Interior Office citizenship Forms
Two genuine native drafts were created through the original `CreateFormService` and `Page.create_and_update_form!`, not through Google Sheets:

| Form ID | Draft title | Questions | Required | Owner group |
|---|---|---:|---:|---|
| 3 | Request a correction to a United Hampshire Citizenship record | 10 | 4 | zQGRUNH5 |
| 4 | Request evidence of existing United Hampshire Citizenship | 9 | 3 | zQGRUNH5 |

Form 3 editor: <https://admin.forms.service.gov.uhrblx.com/forms/3> and Runner draft preview: <https://submit.forms.service.gov.uhrblx.com/preview-draft/3/request-a-correction-to-a-united-hampshire-citizenship-record>.

Form 4 editor: <https://admin.forms.service.gov.uhrblx.com/forms/4> and Runner draft preview: <https://submit.forms.service.gov.uhrblx.com/preview-draft/4/request-evidence-of-existing-united-hampshire-citizenship>.

Both draft previews resolved to HTTP **200** through canonical Forms Runner. The forms address *existing citizenship-status record correction and evidence only*, as distinct from statutory acquisition, registration, naturalisation, renunciation, resumption and deprivation. Questions were prepared against the operative **Citizenship Status Recognition, Evidence and Correction — Caseworker Guidance**. No unnecessary age, date of birth, nationality or medical diagnosis questions were included.

Both forms remain **draft**, have no live version, no delivery recipient and no service-specific privacy URL. There is no collection of public responses yet. Preview availability does not mean lawful caseworking or submission delivery exists.

## Database recovery
- Restricted pre-change custom-format PostgreSQL dump: `/srv/uhde/backups/govuh-forms-admin/20261016/pre-interior-groups.dump`, mode 0600, directory mode 0700.
- Restricted subsequent custom-format dump: `/srv/uhde/backups/govuh-forms-admin/20261016/with-citizenship-drafts.dump`.
- Restored the latter successfully into a separate temporary PostgreSQL database and verified **4 forms, 34 pages, 3 groups, 3 group-to-form associations**. The restore test database was deleted after acceptance; ongoing production data was preserved.
- An initial new draft insert collided with an existing ID because the `forms_id_seq` cursor had not yet caught up with imported form IDs. That attempt rolled back; the sequence advanced, and the subsequent native CreateFormService insert succeeded as Form 3. Form 4 then succeeded as the next form ID. Verify ID sequence state before future bulk imports, and never assign manual IDs to new native forms without correctly adjusting PostgreSQL identity sequences.

## What is not accepted or operational
- Interior Office and Chief Minister's Office Forms submission receipt, email service, message delivery recovery, notification and privacy notices.
- Immigration and Citizenship Casework System with actual person/status records, intake and case references, lawful caseworker and supervisor role scoping, evidence, decisions, correction audit, notices, administrative review and retention.
- Correspondence system (the assessed UK Home Office HOCS source candidate has a non-public required schema component and a multi-service runtime currently unsuitable for this VPS resource envelope).
- Automated Forms group invitations (the running Notify key was previously observed to be a placeholder).
- Other Government, ALB, Parliament, Judiciary and devolved systems, which require their own competent system owners and records.

No paid browser service, provider subscription, supplementary VPS or other new paid service was used to create, change, preview or back up these native Forms.

The implementation is complete **for the stated departmental-form navigation and draft form authoring changes only**. It is not complete for casework, official publication or the whole Government operational application estate.


## Human editor membership repair — deployed 16 October 2026

The live Forms Admin had an unconditional GOV.UK Notify invitation after saving a group member. The running Notify API key was the default placeholder `changeme`. Under the old flow, the membership was saved and the attempted email could fail, presenting the administrator with an HTTP 500 while the access record already existed. The native success message nevertheless claimed an email had been sent. This was an operational blocker for human authoring and a source of duplicate attempts.

- [PR #16](https://github.com/govuh-forms/forms-admin/pull/16) merged as `fcebc1537a146f0357c0a7f2380c600fac52e85a`.
- Changed only existing `GroupMemberInput`, `GroupMembersController` and their normal English translations; no new account provider, universal staff portal, email subscription, or unauthorised organisational role.
- The existing membership validation and organisation restriction remain. The group member is saved independently of a notification. If the key is missing or still `changeme`, no email attempt occurs. If delivery fails after a valid key is configured, the record is preserved and the failure is logged without exposing email credentials. The UI now confirms membership with truthful language indicating unconfirmed email, and directs the administrator to share the normal group link directly.
- Test coverage added for successful delivery, missing Notify credentials and delivery error after membership creation. The source RSpec tests are committed; production Rails image does not include development RSpec gems.
- Ruby syntax and YAML parsing passed. A transaction-isolated acceptance test using the *existing* authorised GOV.UH Signon-linked user created a real native group and member through the model, verified `notification_sent? == false` with the placeholder key, then rolled all test records back. This test was repeated successfully against the **deployed runtime image**.
- Canonical Forms Admin (public Caddy target 127.0.0.1:5929) now runs Docker image ID `sha256:101c4f046d9a302c73c7a69adfab0eec5989173c5876026084264a79ff0a45dc` with a matching source-revision label. HTTPS sign-in returned HTTP 200; unauthenticated /groups remained appropriately protected with HTTP 302. The running container reported zero restarts and retained the correct original UH Coat of Arms and UH Crown copyright. Prior image `sha256:bb2327eaaf76723c793d609ec9886826c78dac77484d16c8ca674f349ba97571` and the stopped old container were retained for rollback.
- No Interior Office ordinary human editor has yet signed in or been formally assigned group membership; no user accounts or office-holder roles were invented. A normal authorised editor must first establish an actual Signon account and be enabled by the competent Forms organisation administrator.

**Limit:** This makes the group permission workflow work without requiring a paid email service. It does not establish any external mail/notification delivery for casework submissions, nor convert Forms Admin into an Interior Office casework system.
