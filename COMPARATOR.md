# GOV.UH Forms Admin — comparator and institutional boundary

**Original product:** GOV.UK Forms Admin
**Upstream source:** https://github.com/govuk-forms/forms-admin
**Related original products:** https://github.com/govuk-forms/forms-runner , https://github.com/govuk-forms/forms-deploy , https://github.com/govuk-forms/forms-e2e-tests
**Maintained product family:** https://github.com/govuh-forms

## What the original product does
Forms Admin enables authorised form creators to construct, preview, maintain, review and make live structured government forms. Forms Runner hosts the applicant journey; the service's supported delivery processes send a submission with a reference to the nominated competent organisation. A GOV.UH or institution-owned information/start page gives the public a route to the actual form.

The form authoring application is not a Government casework, immigration permission, citizenship register, personnel, police, financial or judicial decision system. Form publication does not create statutory powers, permission, citizenship or appointments.

Original UK authoritative references:
- https://www.forms.service.gov.uk/about/
- https://www.forms.service.gov.uk/about/processing-completed-form-submissions
- https://www.forms.service.gov.uk/about/create-good-forms

## United Hampshire ownership
Government Digital Service/GOV.UH Forms provides the technical platform. The competent service institution owns its form's legal purpose, eligibility wording, privacy, receiving route, operational response, records, and the final substantive action. Example: the Chief Minister's Office owns ministerial expressions of interest, whereas the Immigration and Citizenship Service owns the forms specified by applicable citizenship and immigration law.

GOV.UH Signon publishing grants must not be assumed to confer Forms Admin permissions; public One Login must not be assumed to replace staff Forms authentication. Service-specific access is tested.

## Casework and submissions
Retain the native question IDs and versioning semantics. For a service needing structured records, preserve the original receipt and map validated submissions to its proper case or records system. The nominated recipient is role/organisation authorised; mail or other supported integrations require confidentiality, delivery retry/failure control and retention. Sensitive case decisions require a competent officer and, where applicable, review or appeal.

## Adaptation and release assurance
Apply approved UH service identity, domains, publishing links, accessibility, privacy and contact arrangements while retaining original source/provenance/licences. Preserve existing submitted data and form versions during upgrade and retire old routes only after migration validation.

Acceptance must prove correct editor permission, full native create/edit/preview/review/go-live flow, public Runner response/validation/confirmation, unique submission reference, delivered and reconciled institutional receipt, audit, protected data, restart/recovery, rollback, candidate/canonical parity and service-owner authorisation. Running source or a pre-existing URL is not proof that all forms are ready.

This file documents comparator and controls; it does not claim completion or authorise a public service opening.
