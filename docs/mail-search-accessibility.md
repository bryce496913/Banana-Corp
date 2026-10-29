# Mail search Dynamic Type repair

Date: 2026-10-29. Scope: implementation-only UI correction, no story/progression changes.

The fresh full-story QA app installed successfully on the authorized physical iPhone. The unchanged public Home/all-app accessibility audit passed its initial Home step, then failed Email with `Text clipped` in22.766seconds, exactly1test/0pass/1fail/0skip. The failure target is `mail.search`; the element attachment is the search field with its Search mail placeholder. The diagnostic states that text may clip at larger Dynamic Type sizes. This is a new recorded target, not proof that every earlier covered-Home issue is resolved.

Evidence remains local under `validation/complete-story-native-20261029/fresh-qa/`: result bundle, exact counts, exported complete issue description, app screenshot and element screenshot. The known audited target PID was absent in the scoped post-run CoreDevice check; no further phone queries followed release. Remaining application routes were not audited after Email failed. No whole-audit or complete-story native pass is claimed.

## Candidate

`AppSearchField` now passes vertical axis to the existing `AppTextInput`, whose one-to-four-line layout can grow for large text/long queries. No smaller font, Dynamic Type cap, hidden label, audit suppression or changed filter/read action is introduced. The existing search predicate already trims surrounding whitespace/newlines. Browser address navigation and story rules are unchanged.

The audit test additionally terminates its exact target app in async XCTest teardown and checks stopped state. The failed native run entered Tear Down without an observed test-body termination assertion, so Swift defer alone is not treated as sufficient release evidence. The default all-types audit API remains unchanged; teardown cannot suppress findings.

Actual generic iPhone Debug/Release builds and both XCTest compilation configurations pass. A signed Debug candidate using the same isolated QA identity passes live four-bundle signature/profile/entitlement, exact source/resources, iOS18 deployment and test-mapping checks. These establish compile/install preparation, not an accessibility pass. Candidate products/inputs are retained under `validation/mail-search-accessibility-20261029/`.

## Required native follow-up

In a separately authorized roughly ten-minute phone window, read the existing QA save, install only the candidate QA update, confirm exact saved-state preservation, then rerun the unchanged public Home/all-app audit. Require1pass/0fail/0skip and explicit teardown release evidence for full audit acceptance. Also exercise Mail search/unread/Inbox through the normal opening journey. Preserve any next finding, and do not repeat unchanged failures or suppress audit categories. The original game and its save remain separate.
