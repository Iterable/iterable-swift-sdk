# BCIT Migration to the Mobile SDK Testing Project

## TL;DR

The Business-Critical Integration Testing (BCIT) suite for the iOS SDK currently runs against an Iterable project (ID `28411`) that lives in **Sumeru's Iterable account**. Nobody else on the team has access. We need to move all of BCIT's backend state into the existing **"Mobile SDK Testing" project** in the **NJ (engineering) organization**, where the whole SDK team already has access.

Inside that project we'll create a **dedicated folder for BCIT Mobile** to hold all the templates and campaigns, generate fresh API keys, and update the BCIT iOS code to point at the new project.

---

## Why we're doing this

- The current project sits in Sumeru's Iterable account. Nobody else can manage campaigns, rotate keys, or fix things when they break.
- The "Mobile SDK Testing" project in the NJ engineering org is already shared with the SDK team, so everyone has the access they need.
- We want one canonical home for SDK integration test data, owned by the team — not by an individual.

---

## What BCIT is

BCIT stands for **Business-Critical Integration Testing**. It's an iOS app (`IterableSDK-Integration-Tester`) plus a UI test target that runs end-to-end smoke tests against a real Iterable project before we ship the SDK. It registers a real test user, sends real pushes, triggers real in-app messages, and verifies the SDK behaves correctly.

Because BCIT exercises a real backend, **changing projects means recreating that backend state somewhere new and pointing the app at it**.

Code lives in `tests/business-critical-integration/`.

---

## What needs to move

This is the packing list. If we don't move every line item, BCIT breaks.

### 1. The project home
- **Old:** project `28411` in Sumeru's Iterable account
- **New:** existing **Mobile SDK Testing** project in the **NJ (engineering) organization**
- **Login:** Sumeru already has access via `Sumeru.chatterjee+flutter@iterable.com` — that's the account to use for all the steps below.
- Inside that project we'll create a new folder — e.g. **BCIT Mobile** — to keep these templates and campaigns separate from anything Android or other teams have already put in there.

### 2. Three API keys
The BCIT app talks to Iterable using three different keys. Each does a different job; we need all three.

| Key | What it's for | Old value (in `test-config.json`) |
|---|---|---|
| **Server-side** | Used for setup and the in-app "send push / send in-app" buttons. Has full read/write access. | `9098112776ac4b96b16e3d4d204b9496` |
| **Mobile** | Used by the SDK itself when running. JWT auth is **disabled** on this one. | `210cbfd06c7840488216ffe169961dc8` |
| **Mobile + JWT** | A second mobile key with JWT auth **enabled**. Used only by the JWT Auth Retry screen to test retry logic. | `7e534405a2424498b3ab1a48941e1879` |

### 3. The JWT signing secret
- The HMAC secret tied to the JWT-enabled mobile key.
- Old value (truncated): `d570…8866`.
- Iterable shows this **once** on creation. Copy it immediately when you generate the new one.

### 4. The mobile push integration
- Bundle ID: `com.iterable.IterableSDK-Integration-Tester`
- A new APNS auth key needs to be generated and uploaded to the Mobile SDK Testing project.

### 5. One image asset
- Push campaign 14695444 references `https://library.iterable.com/24/28411/24c51520ef0f439da54622b5f8771791-square_cat.jpg`.
- That URL is hardcoded in `IntegrationTestBase.swift`.
- We need to upload the same image to the Mobile SDK Testing project's image library and update the URL.

### 6. The test user
- Email format: `YYYY-MM-DD-integration-test-user@test.com` (a fresh one per day).
- Needs to be created in the Mobile SDK Testing project.

### 7. Nine campaigns
The BCIT code has nine real campaign IDs hardcoded into Swift source. Each must be recreated in the new folder, the new IDs captured, and the source code updated.

| Old ID | What it does | Where it shows up |
|---|---|---|
| **14679102** | Generic push template used as filler `templateId` in simulated push payloads | `PushNotificationSender`, `IterableAPIClient`, `PushNotificationIntegrationTests`, `InAppMessageIntegrationTests` |
| **14695444** | "Send Deep Link Push" — opens a `tester://` URL when tapped, includes the cat image | `BackendStatusViewController`, `IntegrationTestBase`, `InAppMessageIntegrationTests` |
| **14750476** | "Send Silent Push" — content-available push with no UI | `AppDelegate`, `BackendStatusViewController`, `InAppMessageTestView` |
| **14751067** | "Send In-App Message" — the standard centered modal | `InAppMessageTestView`, `InAppMessageIntegrationTests` |
| **15231325** | "Send DeepLink In-App Message" — in-app whose CTA opens a deep link | `InAppMessageTestView`, `InAppMessageIntegrationTests` |
| **15418588** | Silent push that triggers an `UpdateEmbedded` sync | `EmbeddedMessageTestViewModel`, `IntegrationTestBase` |
| **16505358** | "Send Full Screen In-App" (SDK-31 test) | `InAppMessageTestView` |
| **17407752** | "Send Bottom Position In-App" (SDK-92 test) | `InAppMessageTestView` |
| **17408654** | "Send Top Position In-App" (SDK-92 test) | `InAppMessageTestView` |

> The number `999999` in `IterableSDKStatusView.swift` is **not** a real campaign — it's a dummy attribution-test value. Leave it alone.

### 8. CI secrets
GitHub Actions / Buildkite secrets like `ITERABLE_MOBILE_API_KEY`, `ITERABLE_SERVER_API_KEY`, etc., need to be updated to the new keys after migration.

---

## Step-by-step plan

### Step 1 — Create the BCIT Mobile folder in the Mobile SDK Testing project ✅

Log into Iterable as `Sumeru.chatterjee+flutter@iterable.com`, switch to the Mobile SDK Testing project in the NJ org, and create a new folder named **`BCIT Mobile`**. All templates and campaigns we create below go inside this folder.

Note down the project ID for the Mobile SDK Testing project — we'll need it later as `NEW_PROJECT_ID`.

### Step 2 — Create the three API keys

In the Mobile SDK Testing project, go to Integrations → API Keys → Create New API Key, and create three keys:

1. **Server-side**, named `BCIT iOS – Server`.
2. **Mobile**, named `BCIT iOS – Mobile`. **Do not** check "JWT Authentication".
3. **Mobile**, named `BCIT iOS – Mobile JWT`. **Do** check "JWT Authentication".

Copy each key into a password manager as soon as it's generated.

### Step 3 — Generate the JWT signing secret

Generate the JWT HMAC secret for the JWT-enabled key. Copy it immediately — Iterable will never show it again.

### Step 4 — Configure the mobile push integration

Generate a new APNS auth key in the Apple Developer portal, then in the Mobile SDK Testing project configure the mobile push integration for bundle ID `com.iterable.IterableSDK-Integration-Tester` and upload the new key.

### Step 5 — Upload the cat image

Upload `square_cat.jpg` to the Mobile SDK Testing project's image library. Note the new URL — it will look like `https://library.iterable.com/24/<NEW_PROJECT_ID>/<some-hash>-square_cat.jpg`. We'll need this URL in Step 9.

By the end of Step 5 you should have these six values written down somewhere safe:

- `NEW_PROJECT_ID`
- `NEW_SERVER_KEY`
- `NEW_MOBILE_KEY`
- `NEW_JWT_KEY`
- `NEW_JWT_SECRET`
- `NEW_IMAGE_URL`

### Step 6 — Update `test-config.json`

Open `integration-test-app/config/test-config.json` and replace the old credentials with the new ones:

- `projectId` → `NEW_PROJECT_ID`
- `mobileApiKey` → `NEW_MOBILE_KEY`
- `serverApiKey` → `NEW_SERVER_KEY`
- `jwtApiKey` → `NEW_JWT_KEY`
- `jwtSecret` → `NEW_JWT_SECRET`

### Step 7 — Create the test user

In the Mobile SDK Testing project, create today's test user with the email format `YYYY-MM-DD-integration-test-user@test.com`. Confirm the user is visible in the project's user list before moving on.

### Step 8 — Rebuild the 9 templates inside the BCIT Mobile folder

In the Mobile SDK Testing project, inside the `BCIT Mobile` folder, recreate each of the 9 templates. Open each old template in project 28411 in a separate browser window and copy the content over.

Keep template names recognisable, e.g. "BCIT — Deep Link Push", "BCIT — Full Screen In-App (SDK-31)".

Things to double-check while rebuilding:

- Push template for old ID **14695444**: attach the `NEW_IMAGE_URL` from Step 5.
- In-app for old IDs **17407752** and **17408654**: position rules (bottom/top) must match exactly — these tests assert position.
- Deep-link campaigns for old IDs **14695444** and **15231325**: click action is `tester://...`, not `iterable://`. The integration tester app only handles `tester://`.

### Step 9 — Create the 9 campaigns

For each of the 9 templates, create a campaign in the BCIT Mobile folder pointing at that template. As you create each one, fill in the new ID in the mapping table at the bottom of this document.

### Step 10 — Update the campaign IDs in the source code

For each of the 9 old IDs, do a project-wide find-and-replace inside `integration-test-app/` and substitute the new ID. The old IDs to replace:

- 14679102
- 14695444
- 14750476
- 14751067
- 15231325
- 15418588
- 16505358
- 17407752
- 17408654

Also update the image URL in `IntegrationTestBase.swift` — replace the old `https://library.iterable.com/24/28411/...square_cat.jpg` URL with `NEW_IMAGE_URL`.

After the replacements, the only 6+ digit number starting with `1` left in the Swift source should be `999999` (the dummy attribution value).

### Step 11 — Run the smoke tests

Build the SDK and the BCIT app, then run each suite (push, in-app, embedded, deeplink) and confirm all four pass.

Then manually open the BCIT app in the simulator and exercise the **JWT Auth Retry** screen — `Normal` and `401` modes both need to talk to the new project successfully. This is the only way to verify the JWT key + secret pair.

### Step 12 — Update CI secrets

Update `ITERABLE_MOBILE_API_KEY`, `ITERABLE_SERVER_API_KEY`, `ITERABLE_JWT_API_KEY`, `ITERABLE_JWT_SECRET`, and `ITERABLE_PROJECT_ID` in GitHub Actions / Buildkite to the new values.

### Step 13 — Confirm BCIT passes on CI

This is the acceptance gate for the migration. Trigger the BCIT workflow on CI and confirm **every** suite passes against the new project:

- [ ] Push notification tests — green
- [ ] In-app message tests — green
- [ ] Embedded message tests — green
- [ ] Deep linking tests — green
- [ ] JWT Auth Retry flow — green

If any suite fails, do not move on to Step 14. Diagnose, fix, and re-run CI until everything is green. The migration is **not done** until BCIT is fully passing on CI against the Mobile SDK Testing project.

### Step 14 — Wind down the old project

Don't delete project 28411 immediately — keep it alive for a buffer period in case any CI references leak. Plan:

1. Mark it as deprecated (rename to "DEPRECATED — DO NOT USE").
2. Schedule deletion explicitly (calendar entry or Jira ticket).
3. Rotate / revoke the old API keys once CI has been stable on the new project.
4. Update any Confluence / Jira / runbook references that mention the old project ID or keys.
5. Append the final old-→-new ID mapping to this document for future reference.

---

## Risks and what to watch for

- **APNS not active:** if silent pushes pass but visible pushes fail, the APNS auth key isn't fully configured on the Mobile SDK Testing project.
- **JWT secret mismatch:** if the JWT Auth Retry screen returns `401 InvalidJwtPayload` on `Normal` mode, the JWT key and secret in `test-config.json` are out of sync.
- **In-app positioning:** if the bottom-position or top-position in-app shows up centered, the template was rebuilt without its position rule.
- **Wrong deep-link scheme:** must be `tester://`, not `iterable://`.
- **CI lag:** CI takes longer to deliver freshly-triggered campaigns than local. Don't panic if delivery isn't instant.

---

## Open questions before we start

1. Is it OK to create a new test user per day in the Mobile SDK Testing project?
2. When do we cut CI over?

---

## Appendix — Final ID mapping

| Old Campaign ID | New Campaign ID | Type |
|---|---|---|
| 14679102 | **17929288** | Push (simple) |
| 14695444 | **17929289** | Push (deep link) |
| 14750476 | **17929290** | Silent push |
| 14751067 | **17929293** | In-app |
| 15231325 | **17929295** | In-app (deep link) |
| 15418588 | **17929292** | Silent push (embedded) |
| 16505358 | **17929296** | In-app (full screen) |
| 17407752 | **17929298** | In-app (bottom) |
| 17408654 | **17929299** | In-app (top) |

Old project: `28411` (Sumeru's Iterable account) → New project: Mobile SDK Testing (NJ org), folder `BCIT Mobile`, ID `_TBD_`

New image URL: `https://library.iterable.com/1733/1226/57740fdbf0be4cc79672eb07d9969f30-square_cat.png`
