> Continuation on 18 October 2026: the source now blocks activation and legacy
> admin credentials/bearer sessions over HTTP and leaves undocumented positive
> activation responses unconfirmed. The preserved APKs below predate those
> guards. See [continuation report](docs/integration-audit-20261018/continuation/REPORT.md).

# Latest integration update: 2026-10-17

The owner's clarified contract is now wired end to end: anonymous activation
sends `isNewUser: true` on the first attempt, the entered activation code, and
the current FCM token as `deviceId`. There is **no country field**. Live negative
probes returned HTTP 200 with `data: false`; this now reports rejection. A strict
boolean positive result saves a local installation confirmation, restored before
ads on future launches without online revalidation or dependence on the old token.
Android and iOS expose the same activation form. Positive backend activation
remains unverified with a real code; its client flow is covered by simulations.

Public catalogue API methods remain separate from admin authentication. The
pharmaceutical-form endpoint is now connected after a successful live ID lookup.
Home gains a native placement and pharmacy details gain a bottom banner. Release
AdMob IDs use the original project configuration; debug/profile remain demo-only.
Native SDK failures now use a gated banner fallback after a live emulator run
returned an invalid native-ad response while banner/interstitial inventory loaded.
See [current evidence and limitations](docs/integration-audit-20261017/fcm-installation-activation/README.md).
This update supersedes older statements below about missing FCM/device semantics,
pending-only local restoration, an entirely unknown activation response, disabled
pharmaceutical forms, and demo ad IDs in release builds.

> Latest country delivery:269 tests pass; old-country selection/cache races fixed.
> Jordan/Palestine explicit origin/evidence binding is prepared, current numeric IDs
> remain unset. No admin login is needed. [Current source/runtime evidence](docs/integration-audit-20261014/country-scope-20261015/README.md).

> New read-only follow-up: the only published country read remains GetCountries
> (anonymous401); generic Bearer metadata supplies no app/admin role distinction.
> Two new client-wire tests pass; full250 checkpoint and f260 APK are unchanged.
> [Complete API matrix and backend handoff](docs/integration-audit-20261014/public-contract-followup-20261015/README.md).

> Current 2026-10-15 delivery: the end-user app has NO LOGIN. Admin authentication
> is excluded from its UI, default transport and installation activation.
> Prior sign-in-required runtime results are error-boundary diagnostics, not
> functional acceptance. Public-country access and activation/FCM contracts
> remain backend gaps; no admin session is requested. Current evidence:
> [anonymous delivery](docs/integration-audit-20261014/ad-api-audit-20261015/anonymous-implementation-report.md).

> Latest numeric verification — 2026-10-15: exact c88 APK retained21 after
> both observed-before-submit typing and a focused contiguous2/1/Enter command.
> No client text-loss reproduced, source change, rebuild or unit-test rerun.
> Scoped numeric gap closed; original observation1 retained as historical evidence.
> Preferences restored (invalid UMP file preserved/recovered from prior valid
> same-AVD baseline), guest synced, owned emulator stopped. Existing198 tests and
> live backend/native acceptance limits remain unchanged.
> [Numeric verification](docs/integration-audit-20261014/c88-numeric-input-verification-20261015.md).

> Latest runtime update — 2026-10-15: exact c88 APK passed 13 scoped public
> ADB UI cases, including company next-page offline error/retention/manual Retry
> (20→24), agent paging (20→40), empty/disabled login form, sentry auth boundary
> and Home navigation. No rebuild/test rerun; 198-test checkpoint unchanged.
> Prior window-control inference corrected; actual numeric query was 1, not 21.
> Preferences/guest connectivity restored, owned AVD stopped. No protected login,
> activation/FCM registration or native rendering acceptance.
> [Recovery evidence](docs/integration-audit-20261014/c88-adb-runtime-recovery-20261015.md).

> Latest checkpoint — 2026-10-15: five independent catalog/login client fixes,
> 198 full tests passed, analysis 0 errors/0 warnings (47 infos), one verified APK
> c88b5666. Public Swagger is byte-identical. New APK installation hash verified;
> fresh GUI/runtime acceptance blocked before app launch (CUA emulator binding).
> Preferences restored exactly; no owned emulator/heavy work remains. Native ads,
> protected live data, activation and FCM contract acceptance remain unresolved.
> Details: [acceptance follow-up](docs/integration-audit-20261014/acceptance-resume-20261015.md).

# DigitalPharmacy API integration report

**Current verified search-completion checkpoint — 2026-10-15:** shared-country
cancellation ownership and swallowed current cancellation fixed.11 focused and
186 complete tests passed; analysis0 errors/warnings,48 infos. One ARM64 debug
APK SHA256 `b6f556ad1fc2b903d98cd597fb972372a8d7901b61ca986c20370372fa088d93` passed ZIP/signature/source checks and4 scoped
runtime cases:startup, sentry trade/pharmacy visible sign-in boundary, Back Home.
No protected-data/activation/FCM acceptance inferred. Previous395b failure evidence
and APK retained. [Cause, files, tests, artifact and limits](docs/integration-audit-20261014/search-loading-hang-fix-20261015.md).


**Current runtime checkpoint — exact395b1500… APK (2026-10-15):PARTIAL.**
Startup, company query, public paging20->24, retained-query Back and pharmacy
submission/sign-in boundary passed. Trade medication submission remained loading
in two bounded observations;0 validated Flutter/AndroidRuntime errors. No full
runtime acceptance or live request-count claim. Preferences restored; own AVD
closed; no rebuild. [Evidence and blocker](docs/integration-audit-20261014/list-query-runtime-checkpoint-20261015.md).


**Current packaged checkpoint — 2026-10-15:** latest pagination debounce fix is
included in one verified ARM64 debug APK, SHA256 `395b1500d2650bff6933a5b122ed7eca87b09dba8ff1cfce939abbf2aab23458`,
90,187,479bytes. Existing10-focused/175-complete test evidence matches the
source; ZIP/signature and exact embedded source checks passed. Runtime UI of this
NEW APK has NOT been performed. Prior c7e93cb4… APK/runtime evidence retained.
[Source-to-artifact checkpoint](docs/integration-audit-20261014/pagination-apk-checkpoint-20261015.md).


**Current source-only checkpoint — bounded pagination review (2026-10-15):**
rapid keyboard submit no longer leaves a duplicate debounced query. Two UI files
and10 new regressions; focused10 passed, one complete suite175 passed; analysis
exit0 with0 errors/warnings and49 informational lints. APK was NOT rebuilt and
retains the previous packaged checkpoint; it does not include this latest fix.
[Inventory, changed files, logs and limits](docs/integration-audit-20261014/pagination-bounded-review-20261015.md).


**Previous packaged checkpoint — 2026-10-15:** stale401 cannot invalidate a newer
session, and failed suggestion pages require a permitted manual retry. New cases:
24 passed. One complete suite:165 passed. Analysis:exit0,0 errors/warnings,49 infos.
One updated ARM64 debug APK:90,187,479bytes, SHA256
`c7e93cb4a6eeab12920768596cb0f4ca35e18f1021c7fe9a66320911f93fd27e`.
ZIP/signature verified; exact changed production sources embedded. No emulator,
live activation/FCM interaction, upload or publish for this delta.
[Actual verification and limits](docs/integration-audit-20261014/auth-pagination-verification-20261015.md).

Earlier chronological checkpoints below are retained as history and superseded
by the current checkpoint where build/test figures differ.


**Latest follow-up, superseding earlier build checkpoints:** shared shell content
now reserves the actual banner slot instead of extending underneath it. The real
SDK's EEA test form and privacy-options transition worked; Responsive sizes were
379×59 portrait and833×58 landscape. Additional native slots are inserted between
each10 real company/agent/medication-selection/pharmacy rows. Native demo requests
on API33 returned SDK code0 **Internal error**; failed slots hide safely, but native
visual acceptance is not claimed. Real test interstitials appeared at completed
detail-return thresholds; a reloaded interstitial was blocked at the next eighth
completion at 100.4 seconds after the previous show, inside the 180 second minimum.
The owned final round restored the exact baseline preferences and shut down.

The current ordinary debug APK has SHA256
`3d5a7bc2c5bde4b47edbdcff9b9e0276acf5b1ac13c4b219b1362a9718ccc702`,
109,586,882bytes, build exit0 in30.5seconds, and no UMP testing defines enabled.
One new complete suite passed **113 tests** (13seconds), covering APNs readiness,
refresh errors and confirmed-history preservation across token rotation. Analyzer:
exit0, no errors/warnings,46 informational lints. Counts below are older runs and
are not added. See [current logs](docs/integration-audit-20261014/ad-practical/),
[token/device contract](docs/device-token-activation-contract-20261014.md) and
[full published field inventory](docs/integration-audit-20261014/swagger-field-contracts.json).

The user's existing private Safari window visibly loaded **Swagger UI** at the
exact approved HTTP URL. Its16 reviewed read/auth/activation operations and full
field inventory are unchanged from the earlier specification. GET response DTOs
remain schema-less. Medication/pharmacy write-request fields are recorded as
write contracts, not silently treated as GET response schemas. Confirmed activation,
token binding/reassociation/restore, protected reads and physical-iOS/APNs runtime
remain unresolved as detailed in the current documents. No credential image,
secret, live code/token registration, broadcast, production write or publication
was used. A native emulator process exited twice without an established root cause;
the self-contained final round records its own PID, cleanup and timed result.

**Earlier data/navigation checkpoint (superseded):** One complete final run passed **105 tests**, exit 0 (11 seconds). The final APK built in 23.3 seconds and installed on the isolated API33 AVD. Actual public company browsing reached rows 126–133, company medication paging advanced 20→24, and the saved server medication survived a process restart/APK update and refetched actual detail ID 1. Guest-only offline failure followed by Retry recovered that record. Google Test Ad 320×50 appeared below the free-user favourites screen. Two starts with a synthetic pending-history marker suppressed ads; this is not live activation. FCM acquisition was observed only as availability booleans. Backend token registration/update/unregister and server-confirmed activation/restoration remain contract-blocked. See the [current matrix](docs/api-pagination-delta-20261014.md) and [final evidence](docs/integration-audit-20261014/verification-summary.json).

**Earlier APK:** `build/app/outputs/flutter-apk/app-debug.apk`, debug 1.0.0+11, 109,580,631 bytes, SHA256 `49f2aac6924cd0e53571e2167cc8ceef591842adc52ee3001f80e1d755b19e03`. Target argument was android-arm64; the built debug APK actually contains arm64-v8a, armeabi-v7a and x86_64 libraries. App-open ads are now disabled, UMP permission gates all ad requests, and the real favourites drawer entry is restored with a short-screen layout regression. Earlier logs/APK hashes below are historical checkpoints, superseded by [final APK metadata](docs/integration-audit-20261014/apk-metadata.json). The historical shared-emulator ANR root cause remains unproven; no zero-problems or store-readiness claim is made.

**State:** the app uses the project's fixed API origin (`http://144.91.111.63:5002`). The user can manually submit login and activation through the app after a clear Arabic/English HTTP transport warning. Credentials and codes remain user-operated; no live authenticated request was made by the assistant. Bearer is bound to the exact approved API origin, redirects are disabled, and tokens remain memory-only.

**API-read foundation commit:** `3f8c55852477d7d24fb5e83da70a92ffd3399442` (`feat: align API reads with documented contract`). The worktree contains additional uncommitted integration changes on branch `add_macos`; this resumption preserves them. HEAD remains `cc5afa4b9ede340c0c1ea0c6a02a25ab79cd041d`.

## Authentication contract review

### Exact OpenAPI excerpt

| Operation | Request contract | Documented responses |
|---|---|---|
| `POST /api/auth/login` | JSON `LoginRequest`; required `email: string` (`format: email`, `minLength: 1`) and `password: string` (`minLength: 1`); extra properties forbidden. | `200` JSON `LoginResponse`; `401` `ProblemDetails`. `LoginResponse` properties are `accessToken: string|null`, `userType: string|null`, `name: string|null`, `agentName: string|null`, `phoneNumber: string|null`, and `countryId: integer(int32)|null`. No response property is listed in the schema's `required` array, including `accessToken`. |
| `POST /api/users/verify-device` | JSON `VerifyDeviceRequest`; optional `isNewUser: boolean`, `activationCode: string|null`, and `deviceId: string|null`; no fields are listed as required. | `200 OK` with no documented response body/schema; no other response statuses are declared. |

The `accessToken` property is **present** in the login response schema. The precise gap is that OpenAPI neither requires it nor marks it non-null, so a 200 response is contract-valid with the token omitted or null. A client could fail closed at runtime unless a non-empty token is returned, but the backend contract does not guarantee a successful login yields one. There is also no documented token expiry, refresh, revocation/logout behavior, or required profile fields.

Separately, the document declares global Bearer/JWT security. Neither login nor verify-device overrides it with operation-level `security: []`, so both inherit that requirement as published. This is an internal security annotation conflict for login; it is not evidence that the `accessToken` property is absent. Device verification's purpose, ordering relative to login, and effect on authentication are unspecified.

The app submits the documented `email` and `password` only after the user presses Sign in. It accepts only a non-empty access token, stores it in process memory, and strips caller-provided Authorization headers. AuthSession and API transport permit Bearer only when session, configured API, and request origins match exactly; for this deployment that is the approved HTTP origin, with redirects disabled. Both login and activation UI show localized warnings that HTTP does not encrypt the data in transit. The assistant did not submit real credentials, tokens, or codes.

### Fixed HTTP deployment

The current public Swagger JSON was fetched from `http://144.91.111.63:5002/swagger/v1/swagger.json` and is byte-identical to the cached specification. The canonical API is `http://144.91.111.63:5002`; the separate login UI is `http://144.91.111.63:3001/login`. The user may opt into the app's HTTP login/activation flows after seeing the transport warning. No browser security warning is bypassed.

Both reads and user-operated auth are restricted to the exact approved origin. Tokens are never forwarded to another host or port, redirects are disabled, and caller-supplied Authorization headers are stripped. Android's network security configuration permits cleartext only for host `144.91.111.63` (the platform host policy cannot narrow the exception by port); no app-wide allow-all setting was added. iOS and macOS already set `NSAllowsArbitraryLoads=true` in checked-in plist settings; this change leaves those broader pre-existing settings untouched. The UI warns that HTTP cannot protect credentials or codes in transit.

### Backend clarification needed before auth work

1. Mark login as anonymous in OpenAPI (for example, operation-level `security: []`) and document token type/expiry/refresh. The app retains the existing explicit HTTP warning and exact-origin user action for the fixed approved deployment.
2. Make `accessToken` required and non-null in `LoginResponse` (and define token type/expiry); document refresh/revocation/logout behavior and which APIs require each role.
3. Define device-verification purpose, ordering, required fields, response body, failure codes, and whether it changes authentication state.
4. Document country identifier/name mapping and whether catalog reads require authentication; retain the approved HTTP deployment.

## Endpoint matrix

| Swagger endpoint | State in app | Notes |
|---|---|---|
| `GET /api/GetMedicationSelect` | Paged search and positive-ID navigation implemented | Trade/scientific/all entry modes, page 20, retry/deduplication/filter/session resets. CountryId comes only from GetCountries. Nonempty authenticated selection DTO/ID semantics remain live-unverified. |
| `GET /api/GetCountries` | Resolver implemented; auth-required on observed server | Country IDs are matched against exact app country names; no numeric fallback or assumed mapping is present. Successful response shape and country names remain unvalidated. Anonymous request returned 401. |
| `GET /api/GetPharmacies` | Paged adapter implemented; protected live verification pending | Strict public-admin fields, verified country resolver, page 20, retry/deduplication/filter reset. Anonymous probe returned empty 200; authenticated nonempty DTO and all four filters remain unverified. |
| `GET /api/GetMedicationDetails` | Paged adapter and navigation implemented | Positive actual IDs only. Public actual medication ID 1/type 1 returned one complete record and worked through a persisted favourite; nonempty authenticated selection chain/type 2 remain live-unverified. |
| `GET /api/GetCompanySeletc` | Implemented from observed selection contract | Actual business IDs; complete local search and browsing beyond 50. Anonymous CountryId omitted; bound sessions resolve it through GetCountries. The scope warning remains until live country mapping is accepted. |
| `GET /api/GetMedicationDetailsByCompany` | Implemented for company selections | Actual selected business ID and paging; deduplication, retained rows and same-page retry. Anonymous CountryId omitted; authorized sessions resolve it. Final native public acceptance loaded 20→24 records. |
| `GET /api/GetAgentSeletc` | Implemented from observed selection contract | Actual `{id, value}`, full filtering/browsing, optional CountryId resolved only for bound authorized sessions; anonymous reads omit it. |
| `GET /api/GetMedicationDetailsByAgent` | Implemented for agent selections | Actual selected ID with paging, deduplication and retained-row retry. Anonymous CountryId omitted; authorized sessions resolve it. Native public one-record acceptance is from the earlier checkpoint; multi-page failure/retry uses fakes. |
| `GET /api/GetPharmaceuticalForm` | Blocked | The request path and `id` are documented, but response fields needed by the UI (form and price) are not. |
| Medication alternatives | Not in inspected contract | The old `/api/MedicationDetails/Alternatives` route is absent from the inspected OpenAPI document. |
| `POST /api/auth/login` | User-operated in-app login on the fixed origin | The user sees the Arabic/English HTTP risk warning; no live login was attempted. Bearer remains memory-only and exact-origin scoped. |
| `POST /api/users/verify-device` | Local activation entry/status UI; verification remains unconfirmed | The UI submits only after an authenticated user action. Request schema permits optional `isNewUser`, `activationCode`, and `deviceId`; response is only `200 OK` with no body schema or invalid/expired/revoked outcomes. The service returns `unconfirmed` for every 200 response, ignores undocumented fields, and does not store the code or activate ad removal. No real activation code was sent or persisted. |
| `POST /api/notifications/data-updated` | Not called | Has no request body or parameters. It is not a documented FCM-token registration operation. Calling it as a substitute could trigger a broadcast side effect; no call is made. |
| Other write/admin endpoints | Not called | No country/medication/pharmacy/user writes, imports, user listings, or production records were requested or used. |

## Observed access and response evidence

Historical foundation observations below describe the earlier API-read checkpoint. Current read probes, pharmacy/detail adapters and final acceptance supersede earlier unavailable statements; consult the [dated current matrix](docs/api-pagination-delta-20261014.md). Old build and test checkpoints are retained for traceability rather than combined with the final run.

- Anonymous `GET /api/GetCountries` returned HTTP 401 with a response stating that a valid access token is required. No token was sent.
- Anonymous `GET /api/GetMedicationSelect` returned HTTP 200 with an empty page envelope. The bounded probes had no medication items, so they did **not** validate a medication-item DTO.
- Query-free `GET /api/GetCompanySeletc` returned HTTP 200 with 2,479 paged rows and fields `id`, `company`, `agent`, and `agentsPhoneNumber`. Page sizes 100, 1,000, and 3,000 were honored; the last returned the catalog in one page. The app DTO retains only IDs and company/agent labels; selection phone values are not printed, stored, or rendered.
- The observed selection row `id=1` (`company=21,St Century`) returned HTTP 200 from `GET /api/GetMedicationDetailsByCompany?id=1&PageNumber=1&PageSize=10`, with 10 of 24 medication records and `hasNextPage=true`. The item envelope included `id`, `tradeName`, `scientificName`, `usage`, `company`, `agent`, `pharmaceuticalForm`, and `price` (plus an agent phone field not emitted in probe output). This validates passing the selection ID to the related route for that row; broader ID semantics remain for backend confirmation.
- `GET /api/GetPharmaceuticalForm` without its required medication identifier returned HTTP 404. No identifier was guessed.
- `GET /api/GetMedicationSelect?SearchType=1` and a bounded scientific-name search (`SearchType=2`, `StringSerch=paracetamol`, page 1, size 10) returned HTTP 200 with empty page envelopes. `CountryId` was omitted because its valid identifier could not be resolved without the authenticated country endpoint.
- `GET /api/GetAgentSeletc?PageNumber=1&PageSize=10` returned paginated `id` and `value` fields; page size 1,000 returned all 583 records in one page. Selected `id=5493` returned a three-item page from `/api/GetMedicationDetailsByAgent`. The app maps this selection ID to the corresponding paginated detail call. No `GetPharmacies` probe was sent.
- One bounded search probe used `CountryId=0` only to observe the response envelope. This was not treated as a country mapping and is not a fallback in the app.
- Company/agent catalog and detail probes omitted optional `CountryId` rather than reuse that envelope-only zero or invent an ID. The app displays a country-scope notice on company/agent search results until an authenticated country mapping is available.
- No `GetPharmacies`, user, or other sensitive-record GET or POST was sent to the live server. No credential, Bearer token, activation code, FCM token, or patient data was sent live.
- The API remains configured to the user-specified HTTP origin. Auth is initiated only by explicit user action, risk warnings remain visible, and exact-origin scoping prevents cross-origin Bearer leakage. The assistant sent no live credentials, tokens, or activation codes.

## Synthetic response examples

These examples are **synthetic illustrations**, not invented DTOs and not claims about unobserved fields. The first illustrates only the envelope/pagination shape observed on the empty medication response; item fields remain unverified.

```json
{
  "status": 200,
  "message": "<synthetic status message>",
  "data": {
    "data": [],
    "meta": {
      "pageNumber": 1,
      "totalPages": 0,
      "totalCount": 0,
      "hasPreviousPage": false,
      "hasNextPage": false
    }
  }
}
```

The country object below reflects only the OpenAPI component field names. The sample ID and name are placeholders; they must not be used as a mapping.

```json
[
  { "id": 123456, "name": "<server country name>" }
]
```

## UI and error behavior

- 401 errors display a localized sign-in-again explanation, clear the in-memory session, and do not offer a futile retry.
- Settings contains a login/logout section; at the fixed HTTP configuration it shows the transport warning and requires the user to press Sign in before sending anything.
- Contract gaps display a localized unavailable explanation and disable retry where the missing contract cannot be fixed by another request.
- Medication suggestions are visibly non-interactive until a usable medication ID is supplied by the backend.
- Medication suggestions now request server pages using Swagger's `PageNumber`/`PageSize`, continue when `meta.hasNextPage` is true, deduplicate appended entries by the verified display fields, and retain loaded entries if a later page fails.
- Pharmacy results are not fetched until the response contract is documented.
- Unrecognized envelopes or item fields fail explicitly instead of becoming empty/default records.

## Remaining current Swagger inventory

The current document also exposes operations not invoked by this mobile integration:

- `POST/PUT/DELETE /api/Country`, `POST/PUT/DELETE /api/MedicationDetails`, `POST /api/MedicationDetails/import`, `POST/PUT/DELETE /api/Pharmacies`, and `POST /api/Pharmacies/import`.
- `GET /api/GetAllUsers`, `/Agent`, and `/Admin`; `POST/PUT/DELETE /api/Users`.
- `GET /WeatherForecast`.

The documented request DTOs include `Country { id:int32, name:string|null }`; `MedicationDetailsRequest { tradeName, scientificName, usage, company, agent, agentsPhoneNumber, pharmaceuticalForm:string|null; price:double; countryId:int32 }`; `PharmaciesRequest { name, address, managerName, phoneNumber:string|null; countryId:int32 }`; and `CreateUserRequest { name, phoneNumber, role:UserRole, activationCode, email, password, agentName:string|null; countryId:int32|null }`. These write/admin DTOs have no required properties and responses are only `200 OK` without response schemas. They are not implemented or called by the consumer app. `VerifyDeviceRequest` fields and limitations are listed above.

## Notifications and token contract boundary

Settings reads the operating-system notification permission status without prompting. A user can explicitly press “Enable notifications” to invoke the OS request. On denial, the app shows device-settings guidance; an unknown permission-read failure does not trigger a prompt. Initialization does not call `requestPermission`; iOS local-notification initialization also disables implicit alert/badge/sound prompts. Android may acquire an FCM token without alert permission; iOS fetch is skipped unless permission was already granted. The current token and rotations remain in memory, and token values are not logged or persisted.

`PushTokenLifecycle` forwards the current FCM token and rotations to an in-memory pending-registration queue. A future documented adapter can call `PushNotificationService.retryPendingRegistration`; failure remains retryable, and a late success for an older token does not clear a newer token. Because Swagger/Postman disclose no registration contract, no network request is guessed or sent and the queue stays pending.

## Ad entitlement interface and current status

`lib/core/entitlements/ad_entitlement.dart` defines `EntitlementStatus { unknown, inactive, active }`, `AdEntitlementSnapshot.isAdFree`, and the read-only `AdEntitlementReader` contract implemented by the ads controller. The ads controller starts in the normal `free` state; `restorationPending` is a separate explicit state that suppresses ad loads while a known prior activation awaits a server result. App startup preserves that pending state and sign-in does not clear it; sign-out resolves to ads-on. No current backend endpoint can resolve restoration, so this state is an integration seam rather than a live restore flow. No activation code or local-only active entitlement is persisted. The new `ActivationEntitlementRestorer` can persist a non-secret confirmation scope only after an injected server lookup returns active; bootstrap treats it as restoration pending. The current backend provides no such lookup or stable account/device binding contract, so production cannot create this history from verify-device. `AppProvider.init` restores existing confirmation history before requesting any ads. Sign-out clears it and invalidates in-flight results. No code publishes active from the activation UI or undocumented response payload.

The local activation screen provides code entry, a sign-in requirement, loading/error states, and an unconfirmed result state; it clears the code after submission and does not claim success. The exact service API is `ActivationService.verifyDevice({required String activationCode, bool? isNewUser, String? deviceId})`, which submits to `POST /api/users/verify-device` with the in-memory Bearer for the configured API origin. It trims but does not retain the submitted code, disables redirects, clears the session on 401, and throws for non-200 responses. OpenAPI declares only bodyless `200 OK`, so every 200 returns `ActivationVerification.unconfirmed` regardless of any undocumented response payload. No other user/device-status operation can independently resolve this: the only user GETs are `/api/GetAllUsers`, `/api/GetAllUsers/Agent`, and `/api/GetAllUsers/Admin`, each has no documented response schema and no ID/status selector. There is no individual user, device, entitlement, subscription, or activation-status GET in this specification. Their admin/user-list semantics are not safe to treat as an entitlement lookup.

## Earlier focused verification (historical; do not add counts)

- Focused Flutter suite for auth service/settings/session, activation service/page, ad entitlement/auth, API service, and company/agent catalog mapping: **55 tests passed**. Synthetic tests cover user-operated HTTP requests, exact-origin scoping, unconfirmed activation responses, restoration-pending behavior, ad suppression after entitlement changes, and ID-based company/agent page requests.
- Focused `dart analyze` over the changed auth, activation, catalog, provider, ad-service, and corresponding test files: **no issues found**.
- `dart format` on changed Dart files, ARB JSON parsing, and `git diff --check`: passed.
- `git diff --check`: passed.

There is **no live-auth, activation, entitlement, or push-token delivery validation evidence**. Public catalog GETs were unauthenticated and read-only. No credential, Bearer, activation code, FCM token, or patient data was sent. Local tests establish only client behavior against synthetic responses. No full Gradle/Android build was run in that earlier follow-up. Current build evidence is recorded below. The previous offline Gradle attempt could not resolve the uncached Flutter Gradle plugin `org.gradle.kotlin.kotlin-dsl:4.5.0`; no retry was made.

## Backend follow-up requested

1. Clarify why `POST /api/auth/login` inherits global Bearer security in OpenAPI, and document token type/expiry/refresh and which operations require authentication.
2. Make `GetCountries` available to the authenticated app and document its successful response shape, stable country code/name values, and IDs. The app will continue to avoid guessing IDs.
3. Document `GetMedicationSelect` item fields and include a stable medication ID; document `GetMedicationDetails` response fields.
4. Confirm that `GetCompanySeletc.id` and `GetAgentSeletc.id` are stable IDs intended by their respective detail routes, and document both response DTOs. The app mapping is based on bounded public responses; backend documentation should confirm the observed relation.
5. Document `GetPharmaceuticalForm` response fields including the form and price needed by the UI.
6. Document `GetPharmacies` response schema and pagination envelope before enabling pharmacy-record reads.
7. Either add/document the medication alternatives route or confirm that this feature is no longer supported.
8. Add a documented FCM-token registration/update endpoint with exact request fields, account/device association, replacement/revocation behavior, and retry/idempotency rules. `POST /api/notifications/data-updated` has no request schema and is not used for token delivery.
9. Define activation validation response fields and semantics for valid, invalid, expired, revoked, and offline cases; define entitlement state, account/device binding, expiry/revocation, and restoration after login/restart. `POST /api/users/verify-device` currently documents only optional request fields and bodyless 200, which is insufficient to persist a server-confirmed ad-free state.

## Preserved `api_client.dart` work

The prior local `DemoMetricCard` change remains outside the integration commit. Its current worktree delta against the integration commit is saved at [`patches/api-client-worktree.patch`](patches/api-client-worktree.patch). That patch contains the preserved card implementation plus the compatibility/import and `ApiClient` additions made during this task, so it can reproduce the complete current file on top of the commit. Do not apply it to the current worktree; it is already present there.

## Local macOS resumption — 2026-10-13 UTC

- Project branch/HEAD verified; no active Gradle task was present. Only the already-running named emulator is used. No `AGENTS.md` or `.agents/skills` was present in this checkout or its parent instruction locations; the accessible local Codex memories directory was empty.
- Existing `api_client.dart` and `patches/api-client-worktree.patch` were left unchanged in this resumption. Their SHA256 values are `ba97b43f0a63543821af662b762fbefcb54cb1c1bfdc85c5a25bee6881dda17c` and `f82fece746bc3613b8d607d100ff043903107fe218514aa29ab51fe7b1333f61`, respectively.
- Current public Swagger fetched again from the approved HTTP origin. SHA256: `7474c185e8103ca85bf3ee1fe70dfa295d433fde9a7d8aedbda84f6843cd5f8b`. Verify-device still has only a bodyless 200 response. No token-registration/update/unregister or account/device entitlement lookup appears. Postman contains the older medication/pharmacy reads only. No admin UI login was attempted.
- Six bounded anonymous catalog/country reads verified the public envelopes: company 1 returned pages of 20 then 4 records, with `hasNextPage` true then false; agent 5493 returned 3 records; countries returned 401. A medication ID obtained from the company response returned an empty pharmaceutical-form page (200) and medication details 400 with searchType omitted. Adding the documented `searchType=1` to the same observed ID returned 200 with one expected medication record and the same known fields. This validates that bounded detail read, not the missing `GetMedicationSelect` ID mapping or all response variants. The app does not wire an unsupported search-to-detail relation. No phone fields were printed or saved.
- All ad units and the Android/iOS AdMob application IDs now use Google demo identifiers only. Source: [Google Android test ads](https://developers.google.com/admob/android/test-ads) and [Google iOS test ads](https://developers.google.com/admob/ios/test-ads). No ad click was made.
- Company/agent cards now expose the form and price already returned in the selected record, instead of routing a form button to an unsupported API. Their results retain the country-scope notice. Missing medication country remains null, and numeric values are never interpreted as Jordan/Palestine without a server mapping.
- Removed the obsolete numeric country helper and a hardcoded alternative-medication diagnostic request. Repository cache keys use the selected country's storage name. Banners reload on width/orientation changes; interstitial loads do not overwrite an already loaded/showing ad.
- Confirmation-history restoration has an explicit injected lookup boundary and tests for active/inactive/unknown, offline, restart, logout, and old-account result races. Saved history never grants active status. Wiring the real lookup and stable non-secret scope remains blocked by the backend contract. No real code or confirmation history was created.
- FCM fetch runs without blocking app startup; getToken/onTokenRefresh remain in use. The lifecycle rejects late lookups after disposal; queue revisions prevent stale acknowledgments clearing a token requeued after an account reset. Debug diagnostics emit only availability/pending booleans, never token values. Live backend registration/replacement/unregistration remains unimplemented pending its contract.
- `flutter test --no-pub --concurrency=2 --reporter expanded`: **75 tests passed in the latest complete run after the launch-policy fix (164 seconds)**. Earlier overlapping focused counts are not added. The obsolete Flutter counter test was replaced with an actual app startup/country-picker test.
- `dart analyze lib test`: no errors or warnings; 39 informational lints (existing deprecations/context/style). Final `dart analyze lib test` also passed with only the same 39 informational lints.
- Initial Android build succeeded (exit 0): Flutter 3.47.1, Dart 3.13.1, Gradle 8.14.3, AGP 8.11.1, Kotlin 2.2.20; debug Android arm64, two workers and 2GB Gradle heap. `assembleDebug` took 1330.6 seconds. Package identity is `com.digitalpharmacy.digitalpharmacy`, version `1.0.0+11`, min SDK 24 and target SDK 36. A new 86MB APK was produced; the older March output was not used. Final source validation/rebuild follows the last presentation and country-mapping changes. No clean, SDK removal, Shop modification, Docker restart, host-network change, push, PR, production deployment, or Library upload.

Exact remaining activation requirements: explicit active/inactive/invalid/expired/revoked response semantics, stable non-secret account/device binding, a restoration/status operation, expiry/offline policy, and invalidation rules. Exact remaining FCM requirements: registration/update/unregister operations and methods, body fields, authenticated account/device binding, replacement/revocation semantics, idempotency/retry rules, and permission/logout handling. `/api/notifications/data-updated` is never used as a token adapter.

### Current changed files relative to HEAD (includes preserved prior work)

```text
API-INTEGRATION-REPORT.md
android/app/src/main/AndroidManifest.xml
android/gradle.properties
android/gradle/wrapper/gradle-wrapper.properties
android/settings.gradle.kts
docs/ad-placement-inventory.md
docs/local-verification-20261013/apk-metadata.json
docs/local-verification-20261013/native-activation-signin-required.png
docs/local-verification-20261013/native-anr-after-launch-policy.png
docs/local-verification-20261013/native-compact-setting.png
docs/local-verification-20261013/native-company-catalog.png
docs/local-verification-20261013/native-pending-check.json
docs/local-verification-20261013/native-pending-home.png
docs/local-verification-20261013/public-api-probes.json
docs/local-verification-20261013/verification-summary.json
ios/Runner/Info.plist
lib/core/config/app_config.dart
lib/core/entitlements/ad_entitlement.dart
lib/core/network/activation_service.dart
lib/core/network/api_auth_service.dart
lib/core/network/api_client.dart
lib/core/network/api_service.dart
lib/core/network/auth_session.dart
lib/core/widgets/ad_banner_placement.dart
lib/features/activation/view/activation_page.dart
lib/features/drugs/data/mappers/medication_mapper.dart
lib/features/drugs/data/models/agent_catalog_item.dart
lib/features/drugs/data/models/company_agent_item.dart
lib/features/drugs/data/models/medication_item.dart
lib/features/drugs/data/repository/medication_repository.dart
lib/features/home/view/home_page.dart
lib/features/search/view/agent_drugs_page.dart
lib/features/search/view/company_drugs_page.dart
lib/features/search/view/search_results_page.dart
lib/l10n/app_ar.arb
lib/l10n/app_en.arb
lib/l10n/app_localizations.dart
lib/l10n/app_localizations_ar.dart
lib/l10n/app_localizations_en.dart
lib/main.dart
lib/providers/app_provider.dart
lib/services/ads/activation_entitlement_restorer.dart
lib/services/ads/ad_service.dart
lib/services/ads/ads_entitlement_controller.dart
lib/services/notifications/push_notification_service.dart
lib/services/notifications/push_token_lifecycle.dart
patches/api-client-worktree.patch
test/activation_entitlement_restorer_test.dart
test/activation_page_test.dart
test/activation_service_test.dart
test/ad_entitlement_test.dart
test/ads_auth_entitlement_integration_test.dart
test/api_auth_service_test.dart
test/auth_session_scope_test.dart
test/auth_settings_section_test.dart
test/company_catalog_api_test.dart
test/push_token_lifecycle_test.dart
test/widget_test.dart
```

### Native launch observation and follow-up

The debug APK built successfully and installed on the verified API33 arm64 emulator. Firebase Messaging acquired a real token: only `tokenAvailable=true; registrationPending=true` was read from app diagnostics. The value was never read, printed, copied, or sent to the pharmacy API. This is acquisition evidence only; backend registration/update/unregister remain unverified.

On the first cold native launch, a Google-labelled `Test Ad` app-open overlay arrived over the country chooser and Android reported a MainActivity focus-event ANR (waited 5002ms). Flutter reported no unhandled exceptions. The client now consumes the launch opportunity immediately instead of queueing a late show; main calls it only after country setup has completed and the navigator is on the root screen. Ads still require current entitlement permission and a loaded ad. The 75-test suite passed after this fix; focused analysis found no issues. Native re-verification follows the new sequential build. The observed ANR is not treated as resolved before that re-verification.

### Current native blocker and prepared manifest patch

The launch-policy APK (SHA256 `881db6a6a52a02b0cdfdea61266a4b11b39e534447edf01f423d8f9cf87176e2`) built with exit 0 in 240.6 seconds and installed successfully. It no longer showed app-open over country selection, but MainActivity still showed an ANR on the emulator. The ANR is therefore **not resolved**. The current Google Mobile Ads dependency is Android SDK **23.6.0** (`google_mobile_ads` 5.3.1), not SDK 24.

A minimal source patch enables `com.google.android.gms.ads.flag.OPTIMIZE_INITIALIZATION` and `com.google.android.gms.ads.flag.OPTIMIZE_AD_LOADING` in AndroidManifest.xml. Google's [initialization/ad-loading optimization guide](https://developers.google.com/admob/android/optimize-initialization) says these flags offload expensive tasks, are supported from SDK 21, and default false before SDK 24. The XML parsed successfully. This is a candidate SDK-side mitigation, not proof of the ANR root cause or remediation. The last APK does **not** contain this later manifest patch. Build ownership has been handed back as requested; a new heavy round waits for resource coordination. No ADB-root, emulator restart, SDK deletion, host-network change, or Shop modification was used to inspect protected ANR traces.

### Lightweight native pending-state verification

A clearly synthetic, non-secret confirmation-history scope was inserted only into Digital Pharmacy's Flutter preferences to exercise bootstrap restoration. It does not confirm activation or contain a code/token. With that marker the app rendered, accepted country selection, showed its tips and activation entry, and entered settings without the observed ANR dialog. SDK diagnostics showed **8** test-device ad-request indicators in the prior free process versus **0** in the pending process. This is useful isolation evidence for ad loading; it does not establish the ANR root cause.

The native activation screen required sign-in and kept verification disabled with empty fields; no code or credential was entered or submitted. Android notification status displayed denied while FCM acquisition had already succeeded. Selecting Compact saved `ad_banner_size_v1=compact` in app preferences; the setting and synthetic history survived an app restart. Actual banner dimensions in the ordinary free state remain unaccepted because of ANR. The synthetic marker is temporary and is removed before handoff.

Coordinator explicitly deferred the next Gradle round until after the Shop release. There is no active heavy task in this Digital Pharmacy session; source/manifest review and documentation continue only.

### Final lightweight observations and cleanup

The public company catalog rendered and filtered to two `21,St Century` selections with distinct warehouses. Opening the selection did not complete acceptance: Android exit info recorded `DEPENDENCY DIED` for `com.google.android.gms/.fonts.provider.FontsProvider` in dying `com.google.android.gms.persistent` (02:37:18 device-local time). No Google Play Services restart, data reset, ADB-root, or other service modification was attempted. This environment/dependency event is separate from proving the client API mapping and does not establish that the SDK manifest candidate resolves ANR.

Compact preference was retained through an app restart. The synthetic history checkpoint was then removed, the original responsive default restored, and the chosen country retained. Digital Pharmacy alone was stopped; no fake activation or test checkpoint remains. No live login, verification, token registration/update/unregister, broadcast notification, production ad click, publishing, push, PR, or Library upload occurred.

The last built APK is `build/app/outputs/flutter-apk/app-debug.apk` (90,148,475 bytes; SHA256 `881db6a6a52a02b0cdfdea61266a4b11b39e534447edf01f423d8f9cf87176e2`). It includes the launch-opportunity fix, but not the later manifest optimization flags. See [verification summary](docs/local-verification-20261013/verification-summary.json), [APK metadata](docs/local-verification-20261013/apk-metadata.json), [latest build log](docs/local-verification-20261013/final-android-build.log), [75-test run](docs/local-verification-20261013/flutter-tests.log), and [launch-policy analysis](docs/local-verification-20261013/launch-policy-analysis.log).


## Local resumption verified on 2026-10-14

This section supersedes the older APK/build-ownership and native acceptance statuses above; the 2026-10-13 evidence remains historical. HEAD and branch are unchanged. There were no active builders, testers or emulators at resumption. The coordinator assigned the heavy slot to Pharmacy after Shop completed. The shared AVD retained Shop data and an earlier blocked proxy configuration, so one separate AVD used the existing API33 Google APIs arm64 SDK image. No SDK download, Shop data copy, old AVD mutation, service restart or host-network change was needed. Its name is `DigitalPharmacy_API33_Isolated_20261014`, serial `emulator-5584`, root `/tmp/digitalpharmacy-avd-20261014` (Pixel 6, 1080×2400, density 420, 3GB RAM, 2 cores).

### Implemented and built

The Android SDK optimization flags are present in the compiled APK. The first post-flags native round exposed a separate client layout bug: `AdBannerPlacement`'s Center expanded vertically, placing the banner in the middle of the screen and leaving company results with no visible list area. Setting `heightFactor: 1` keeps the slot at the ad's own height. `SearchPageLayout` now uses Scaffold's real `bottomNavigationBar` reservation rather than overlaying a banner over list rows with a guessed fixed inset. Failed banner loads wait 30 seconds before retrying instead of immediately rebuilding into another request; cleanup cancels the retry timer. These changes affect the shared banner used across shell, settings, catalog and detail pages.

### Tested in this round

- Complete Flutter suite: **75 tests passed**, exit 0 in approximately 14 seconds. These include activation/restoration transitions, auth scoping, ad callback gates, saved size, token fetch/refresh/queue races and API mapping. Earlier overlapping counts are not added.
- `dart analyze lib test`: exit 0; zero errors/warnings, 39 existing informational lints. `git diff --check` passed.
- Final local build: exit 0, `assembleDebug` 37.9 seconds; installed successfully on the isolated AVD. [Build log](docs/local-verification-20261014/android-build.log), [tests](docs/local-verification-20261014/flutter-tests.log), [analysis](docs/local-verification-20261014/analysis.log).
- Native country chooser accepted Jordan; selection remained through app restarts. A Google-labelled test app-open ad appeared only after country selection in the first flags build; load completion did not cover the country dialog. All identifiers remain Google's demo units/application IDs. No ad content or install link was clicked.
- Public company catalog rendered and opened the actual selected business ID. Company medication list showed 20 records, expanded `sentry senior` with returned scientific name, form `tab 60` and price `0.00`, and loaded to 24 records on scroll. Agent catalog rendered; Canada opened with one medication. API country scope remains explicitly unverified.
- Responsive banner remained in the bottom slot. Compact selection produced native bounds `[120,2174][960,2305]`: 840×131px at density 420, corresponding to 320×50dp. The saved `compact` setting and visible compact banner survived process restart.
- Synthetic, non-secret confirmation history restored to pending across two starts. Ads were absent and test-device ad-request indicators were zero in both pending processes; the free process had four at the catalog checkpoint. This proves pending bootstrap suppression in this environment, not a live active entitlement. Anonymous activation stayed disabled and required sign-in; no code was entered.
- Current native processes acquired an FCM token: only `tokenAvailable=true; registrationPending=true` was read. First initialization on the freshly booted image had reported false; acquisition succeeded on the later start. No token value was read/printed/copied or submitted to the API. Refresh handling is covered by the lifecycle tests; actual token rotation was not induced or observed. No notification was sent.
- No ANR or dependency-death event was observed during the isolated verification round. Scoped Android exit metadata showed our deliberate FORCE STOP and an unused WebView sandbox exit. This is bounded observation, not proof that the historical shared-emulator problem has a single fixed root cause. iOS/macOS runtime, a physical Android device and every native/interstitial placement were not accepted in this round.

### Required backend inputs still missing

Swagger was re-read from the approved HTTP origin and its SHA256 remains `7474c185e8103ca85bf3ee1fe70dfa295d433fde9a7d8aedbda84f6843cd5f8b`. [Exact public excerpts](docs/local-verification-20261014/api-contract-boundaries.json) show `verify-device` with optional request fields and only a bodyless/schema-less documented 200; that cannot confirm active entitlement. Required: explicit active/inactive/invalid/expired/revoked semantics, stable account/device binding, a restoration/status operation, expiry/offline rules and invalidation behavior. Local history saves a non-secret confirmation scope only after a future documented adapter resolves active; startup restores it as pending, never as locally confirmed active.

FCM needs documented register/update/unregister routes, methods, body fields, authentication/account/device binding, replacement/revocation/idempotency/retry rules and logout/permission handling. The in-memory pending adapter is ready for that contract; `/api/notifications/data-updated` has no registration body and was never called. Protected search requires an authenticated GetCountries response/name-to-ID mapping and verified nonempty selection item IDs. General medication navigation, pharmacies, alternatives and forms retain their documented unavailable boundaries. A live authenticated test needs a specifically approved secure handoff for a test session; no real credential/code/token was read from logs or entered into HTTP. No live activation or token-registration integration is claimed from mocks.

### Deliverable and cleanup

Final APK: `build/app/outputs/flutter-apk/app-debug.apk`, **90,154,004 bytes**, SHA256 **`ade8ad61a10ae62c2754e130ef0f6cfd7ba4141cf97b4b07539a8eb36f17880f`**, debug `android-arm64`, package `com.digitalpharmacy.digitalpharmacy`, version `1.0.0+11`, min SDK 24, target SDK 36. [APK metadata](docs/local-verification-20261014/apk-metadata.json) and [current summary](docs/local-verification-20261014/verification-summary.json) identify the exact output. It includes the flags, launch-opportunity policy, layout fix and retry cooldown.

The synthetic history and temporary Compact setting were removed only from this isolated app; original Responsive default and other preferences were preserved. Final cleanup stops only Pharmacy and its isolated emulator. Existing Shop/codex AVDs, SDK, services and Docker remain untouched. No publishing, upload, push, PR or production change occurred. [Complete changed-file inventory](docs/local-verification-20261014/changed-files.txt) includes preserved inherited work. The protected `api_client.dart` hash remains `ba97b43f0a63543821af662b762fbefcb54cb1c1bfdc85c5a25bee6881dda17c`; preserved patch hash remains `f82fece746bc3613b8d607d100ff043903107fe218514aa29ab51fe7b1333f61`.

## Native SDK diagnostic follow-up (18:11 UTC)

Native rendering remains unaccepted: one isolated ordinary-consent round returned Google AdMobAdapter error0/Internal error in133ms with ResponseInfo present, before native template creation. Banner/interstitial loaded in the same process; there is no proven provider outage or network cause. Added sanitized debug diagnostics only; no speculative factory/unit/privacy/network changes. Focused24tests passed (overlaps previous113-test checkpoint; not added), three-file analysis clean. New debug APK SHA256 `05b7fc752d6cfcfa8c9e673e7f0bf2eea5d69e78edddcb3d625960887100ec81`; previous APK preserved separately. Own emulator stopped, baseline restored; protected files unchanged. See [diagnosis, evidence and smallest backend input](docs/native-sdk-diagnosis-20261014.md).

### Direct SDK control (18:19 UTC)

A standalone debug entrypoint made one native request after real UMP permission, without catalogs, AdService/gates, FCM/API or other ads. Same demo unit, small template and non-personalized/G request reproduced AdMobAdapter code0/Internal error in14ms, before AdWidget mounting. Application Dart orchestration is not necessary for reproduction; shared native setup/SDK/emulator/network remain unisolated. No provider outage is proven. Ordinary APK05b7… restored, baseline restored, owned emulator stopped. No production Dart changes or repeated tests. See [control comparison/evidence](docs/native-sdk-diagnosis-20261014.md#direct-sdk-isolation-control-1819-utc).

## Client confirmation transaction and final native controls (23:39 UTC)

Implemented explicit typed active acknowledgment, pre-write suppression, binding-only persistence, startup/foreground status-adapter restoration, storage/session/disposal race protection and Arabic/English success UI. Wire verify-device200 remains unconfirmed. Actual SDK callback tests cover late/disposed interstitial loads and obsolete full-screen dismissal. Complete current suite132passed in28s; server acknowledgments/status tests are simulated. Fresh HTTP Swagger200 unchanged, including activationCode in user-write DTOs but no entitlement/status/FCM acknowledgment. See [client flow and exact backend questions](docs/client-activation-ad-gating-20261014.md).

Native controls all failed with SDK0: optimization defaults19ms, fresh API33r17 state36ms, supported SDK24.1/plugin6 control338ms, default optional rating22ms, medium template28ms. SDK/plugin/config changes were reverted; no cause or provider outage established. Corrected the earlier statement to failure before the Flutter loaded callback/AdWidget mount; native construction itself was not instrumented. See [controlled evidence](docs/native-sdk-diagnosis-20261014.md). Current ordinary client APK rebuild is underway.

Final ordinary debug APK built86.8s successfully; SHA256 `8d147e2f5b27875af6db77f3a6513d8f9e5e2ed7a7ac24eec17f7308ba70cf12`, 90190511bytes. Actual kernel contains ordinary DigitalPharmacyApp/current activation success UI and no native-control entrypoint; embedded AdsSDK23.6.0. Final analysis0errors/0warnings/49info, exit0 with informational lints nonfatal. Full current132tests passed28s. No permanent dependency/manifest/network-policy changes from native experiments retained. All controlled AVDs stopped and original preference baseline restored. [Final metadata](docs/integration-audit-20261014/apk-metadata.json).

Final ordinary APK runtime smoke23:46UTC: installed successfully, Arabic home rendered, actual Google-labelled Test Ad banner loaded, sampled Dart errors0, FCM tokenAvailable=true/registrationPending=true (no value collected; no backend registration). No login/code submission or native retry. Own baseline restored exactly and AVD stopped. [Smoke evidence](docs/integration-audit-20261014/ad-practical/client-ordinary-final-smoke.json).

## Actual Swagger/validation response inspection (2026-10-15)

Local Safari confirms Try it out/Execute works even without a response schema. Default generated string/isNewUser=true values are not fixtures and were not executed. Safe actual probes: OPTIONSverify-device405 empty; POST unsupported media/NUL without auth/code/device/FCM produced415 application/problem+json (Unsupported Media Type; traceId redacted). Two focused non-network fixture-replay tests passed; no production source or APK change required. Active/invalid/expired/revoked code cases remain unobserved and need designated QA fixture/input or sanitized actual operator responses, not a generic source-code request. [Evidence and exact input](docs/integration-audit-20261014/swagger-runtime-response-inspection-20261015.md).

Focused follow-up after observed415:9 fixture replay cases (service/coordinator and
English/Arabic UI across free/confirmed/pending states);16 activation tests total
in this focused run passed. Manual retry/no automatic retry, hidden diagnostics,
retained saved history and pending ad suppression verified. Production behavior
was already correct; no source/dependency/APK change. Counts are not added to132.
See docs/integration-audit-20261014/swagger-runtime-response-inspection-20261015.md.

## Prepared auth/pagination fixes — awaiting verification (2026-10-15)

Stale401 side effects are revision-bound across transport, activation and login;
suggestion paging requires an explicit permitted retry after a failed page.
18 race cases and6 pagination cases are prepared, NOT RUN. Existing APK does not
include this delta. No Flutter/Dart test/analyzer/formatter/build was started
while ISKIKIEH AUTO owns heavy work. See
[prepared changes and exact cases](docs/integration-audit-20261014/auth-pagination-regressions-pending-20261015.md).

## Final-APK bounded runtime follow-up — 2026-10-15

Exact c7e93cb4… APK installed without rebuild on dedicated5584:6 UI steps passed
(home, public company suggestions2416, query21 to2, actual medication, expansion,
Back to retained search). Extended home-return/scientific branch incomplete.
Latest round0 Dart errors; earlier splash round4 error lines of unknown cause.
No native-ad requests, live activation or token registration. Own preferences
restored exactly and owned emulator stopped.
[Full limits/screenshots](docs/integration-audit-20261014/final-apk-runtime-smoke-20261015.md).

## Startup diagnosis / Home return — 2026-10-15

App-bar Back from actual medication to search to Home is visually verified.
Three cold app-process starts with fresh XML validation passed,0 preserved
Flutter/AndroidRuntime errors. Prior4 was a raw-logcat stdout line count; the
original body/stack is unavailable, so original splash cause remains unknown.
Stale-XML successes were invalidated before the accepted rerun. No app patch or
new APK build. Own preference baseline restored exactly and dedicated AVD stopped.
[Full diagnosis and limits](docs/integration-audit-20261014/startup-diagnosis-20261015.md).


## User-supplied country IDs and real selection DTO — 2026-10-15

The ordinary app now uses Jordan=0/Palestine=1 from the explicit human instruction,
with provenance and exact-origin checks. This supersedes prior unset-mapping limits;
it is not a GetCountries export.24 anonymous documented GETs observed country0empty,
country1populated, selection `{id,value}`, actual detail IDs/prices, pharmacy filtering
and pagination. The parser/UI mismatch is fixed. Full suite274 passed; analysis
0errors/0warnings/54infos. The final APK109637810bytes, SHA256
`8191a89bd3378aee47d5f2deb8817c3a602fe42edbc7d8d7324ecf858daaea83`.
After runtime exposed a stale missing-ID notice, its condition was fixed;3 updated widget cases passed without repeating the healthy274-test suite. The final targeted analysis has0errors/0warnings/2infos. Live activation/status, FCM registration and price-currency contracts remain gaps.
[Current delivery, exact files, runtime evidence and limits](docs/integration-audit-20261014/user-country-0-1-20261015/README.md).


## Final full-suite local acceptance — 2026-10-15

The final source has280 passing tests and full analysis0errors/0warnings/54infos.
Unknown API currency is now explicitly labelled in Arabic/English across price
views; form adapters retain unknown currency and narrow form rows wrap safely.
One new ordinary arm64 debug APK matches this changed source:109639826bytes,
SHA256 `4bc595279ae3ec8daaf8e5bc31da149e256ca417f7f51bbc1b7427f801b63845`.
Current Swagger is unchanged. One public GetPharmaceuticalForm actual-ID read
succeeded, but its ID association/country/currency contract remains undefined;
additional-form discovery stays contract-limited. No alternatives operation was
found. No activation or FCM registration was performed.
[Final acceptance, changed files, runtime and backend requirements](docs/integration-audit-20261014/final-local-acceptance-20261015/README.md).


## Native/FCM client recovery follow-up — 2026-10-15

Two proved client bugs were fixed: missing bounded token acquisition recovery and
a stale consent initialization reopening the ad gate during a newer privacy flow.
Final290 tests pass, full analysis0errors/0warnings/56infos. Matching ordinary APK
SHA256 `c89eab74c1545629072b3138f419c777e85cffbd8661e7e5cf98221aec0de9ee`.
Actual Android token availability/pending booleans passed at startup and cold process
restart; no real token/code was collected/submitted and no notification sent.
Native0 remains a proved SDK failure boundary with unproved root cause; no exhausted
SDK experiments were repeated. Backend association/status and signed iOS/APNs setup
remain explicit external requirements, not labelled fixed.
[Full cause limits, changes, tests, APK and runtime](docs/integration-audit-20261014/native-push-followup-20261015/README.md).
