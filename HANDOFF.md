# PredatorLab — Project Handoff (v2)

This supersedes the earlier `HANDOFF.md` in this same zip's history — a great deal has
happened since that version, including an unrelated session directly integrating a huge
amount of external "hardening" work into this same tree without git coordination (see
"How this codebase evolved" below). This version reflects verified, current reality.

## What this is
PredatorLab is a SwiftUI iOS app (deployment target iOS 16.0, Swift 6 language mode) for
Shelby GT500 (5.2L Predator V8 / TVS R2650 supercharger / TR-9070 DCT) owners doing
serious performance tuning and diagnostics. Five tabs: **Garage** (at-the-car quick
actions), **Tune** (readiness gates + a 6-space "Forensic Workstation": Pull Lab,
Evidence, Calibration, Topology, Execution, Replay), **Analyze** (CSV log import/review),
**Reference** (technical library — components, signals, maintenance, search, graph,
verification dashboard), **Settings**.

Core differentiator: an evidence-based diagnostic reasoning layer (`R04InvestigationEngine`
+ `DomainDiagnosticExecution` + a large evidence/validation engine cluster) that scores
competing hypotheses against real HP Tuners CSV log data, with an explicit, consistently
enforced "evidence boundary" philosophy — the app never claims more certainty than its
data supports (see `Views/SettingsView.swift`'s "Safety & Evidence Boundary" section for
the house style/voice; match it in anything new).

## Where it lives
- Project root: `/Users/serendipity/Library/Mobile Documents/com~apple~CloudDocs/PREDATORMVP/`
  (inside iCloud Drive — already cloud-synced, confirm with `brctl status com~apple~CloudDocs`)
- App source: `PredatorLab/` subdirectory
- Xcode project: **generated via `xcodegen` from `project.yml`** — always edit `project.yml`
  and run `xcodegen generate`, never hand-edit `PredatorLab.xcodeproj`
- Three test targets: `PredatorLabTests` (unit), `PredatorLabUITests` (2 files —
  `PredatorLabFlowTests.swift` original smoke test + `PredatorLabUITests.swift` +
  `PredatorLabFullJourneyTests.swift`, a single deterministic journey across every primary
  surface including all 6 workstation spaces)

## Current verified status
- **Builds clean under Swift 6** (`SWIFT_VERSION: "6.0"` in `project.yml`), zero errors,
  zero warnings.
- **545 unit tests + several UI tests, all passing**, verified independently and repeatedly
  (not just self-reported by agents — always re-verify, see "Working method" below).
- **App icon done** — custom cobra-coiled-around-supercharged-V8 illustration in
  `Assets.xcassets/AppIcon.appiconset`.
- **Custom dark "garage/mechanic" design system** (`DesignSystem/PLTheme.swift`) applied
  consistently across every screen — `PLCard`, `PLSectionHeader`, `PLStatTile`,
  `PLGaugeRing`, `PLBadge`, `.plPrimary` button style, `.plHardBottomEdge()`,
  `PLStackedChannelChart` (multi-channel strip chart), `PLForensicDesignSystemRev97`
  (instrument-panel chrome: `PLInstrumentChrome`, `PLStatusChip`, `PLMetricReadout`).
- **Git repository exists**, tagged `v0.1-pre`. This was the single biggest outstanding
  risk for a long time — resolved. `.gitignore` excludes `build/`, generated `.xcodeproj`,
  and `LocalRawTelemetry/` (real HP Tuners uploads — never committed, local-only, see
  "Real user telemetry data" below).
- **Local + GitHub Actions CI**: `Scripts/ci.sh` runs the full generate→build→test pipeline
  on a disposable simulator; `.github/workflows/ci.yml` calls it on push/PR (inert until a
  remote is added, since none exists yet).
- **Physical-device install was blocked** on an Xcode Accounts sign-in issue (stale/broken
  keychain credential) — `DEVELOPMENT_TEAM` (87GNNFH3P6) is set correctly in `project.yml`;
  status of whether the user resolved the Xcode sign-in since is unknown to this handoff.

## How this codebase evolved (important context)
1. Started as three incompatible hand-written Swift drafts merged into one working tree,
   zero prior compilation.
2. Early sessions: Xcode project via xcodegen, ~6 compile errors fixed, XCUITest suite
   added, Reference Library grew 8→15 components, Maintenance UI built from scratch, full
   visual redesign (the `PLTheme.swift` design system).
3. **A separate, external AI development lineage** ("PredatorLab-Expanded-Hardening",
   Rev2 through Rev86+) was periodically supplied as zip uploads across many sessions,
   each claiming further iteration. **Critically: every revision through Rev57 was ONLY
   ever validated with `swiftc -parse` on Linux — never compiled against the real iOS
   SDK.** Each zip was audited before porting (never blindly merged) — Rev9 was mostly
   ported (evidence/validation engines), Rev21 was mostly scope creep (only a small
   multi-domain-diagnostics slice was cherry-picked), Rev57 was almost entirely skipped
   (an 80+ file "Technical Truth Ledger" bureaucracy with no real content behind it).
4. **Then, in a separate untracked development thread this session only discovered
   after the fact**, someone (likely the user working with another AI/tool, given the
   file evidence) integrated a huge amount of this external lineage DIRECTLY into the
   live project tree — jumping it from ~180 to 311+ Swift files — without git, without
   telling this session. A "Rev86 AI Takeover Handoff" zip made this explicit: it claimed
   a real Xcode build + 492 passing tests had actually been achieved at some checkpoint.
   **This session independently verified that claim for real** (not just trusted it) —
   real Xcode build succeeded, 493 tests genuinely executed and passed.
5. Since then, this session has: migrated to Swift 6 language mode (clean, no warnings),
   reconciled the 492-vs-510 static test-count discrepancy (traced to 3 deliberately
   excluded revision-test files via `nm`-verified binary inspection), added a full
   deterministic XCUI journey test across every primary surface (with real screenshot
   capture wired in via `XCTAttachment`), done a full UI review against real screenshots
   and fixed 6 concrete issues (see below), and processed real user-supplied HP Tuners
   telemetry data (see below).

## Working method established this session (follow this)
Given how much drift and cross-session interference has happened, this session settled
into a disciplined pattern worth continuing:
- **Never trust a subagent's self-report at face value.** Agents sometimes return a
  placeholder "waiting for test results" message as their `result` before actually
  finishing — always independently verify with your own `xcodebuild`/`grep`/`nm` checks
  before reporting anything as done. Real verification happened dozens of times this
  session and caught real discrepancies agents' own reports missed.
- **Use a fresh `xcrun simctl create` simulator for every test run**, delete it
  afterward. Reusing simulators across runs causes stale-state false negatives/positives
  (e.g. onboarding-already-completed states bleeding between runs).
- **For visual verification**, the interactive simulator panel tool was broken all
  session (crash loop, no real GUI in this sandbox). Two reliable alternatives were
  established: (a) `xcrun simctl launch` + `xcrun simctl io <device> screenshot` for
  direct headless screenshots (a `-DiagnosticSkipOnboarding` launch-argument bypass
  exists in `PredatorLabApp.swift` for reaching Garage without tapping through
  onboarding), (b) adding `XCTAttachment(screenshot:)` calls inside XCUITests and
  extracting them afterward via `xcrun xcresulttool export attachments --path
  <result>.xcresult --output-path <dir>` — this is how the real "every screen" screenshot
  set was produced.
- **When something looks broken across every attempted fix, question the diagnosis, not
  just the fix.** The tab bar "bleed-through" bug (see below) took 7 failed attempts
  before realizing the fix needed Apple's actual iOS 26 `scrollEdgeEffectStyle` API
  (found via web search of the real Apple docs), not more layout padding tweaks.

## UI review findings — all fixed and verified this session
A full screenshot-based review of every primary surface found and fixed 6 real issues:
1. **Production Gates dev-language leak** (`Services/ProductionExecutionRev83.swift` +
   `Views/Components/ProductionExecutionRev83View.swift`) — was showing raw internal
   build-process checklist text verbatim to users ("Run the project under macOS/Xcode...").
   Rewritten into genuine GT500/PredatorLab domain content in the app's own voice.
2. **Tab bar translucency bleed-through** — iOS 26's floating "Liquid Glass" tab bar
   was showing a distorted/ghosted double-image of content directly behind it (Garage's
   colorful buttons, Reference's list text, Settings' toggles). Root cause: NOT a layout
   problem (4 padding/safe-area attempts all had zero effect, verified via identical
   screenshot hashes) — it needed Apple's iOS 26 `scrollEdgeEffectStyle(.hard, for:
   .bottom)` API, applied via a new `View.plHardBottomEdge()` helper in `PLTheme.swift`,
   now applied to every scrollable screen (Garage, Tune, Analyze, Reference, Settings,
   Forensic Workstation). Verified visually fixed via real screenshots.
3. **Evidence workspace had no empty state** — fixed to match Pull Lab's
   icon+title+message pattern (`Views/PredatorLabWorkstationRev85.swift`).
4. **Topology graph sparse-data confusion** — 50 nodes but only 2 real links (most seed
   content genuinely isn't cross-linked yet); added an honest explanatory caption rather
   than pretending it's a complete relationship map.
5. **Reference tab's 6-segment picker truncated labels** ("Comp...", "Mainte...") —
   replaced `.pickerStyle(.segmented)` with a horizontally-scrollable pill-button row
   reusing the existing `FilterChip` pattern.
6. **Settings vehicle form fields had no visible input styling** — added
   `PLSurfaceRaised` background + `PLStroke` border chrome so they read as editable.

## Real user telemetry data processed this session
The user supplied real HP Tuners exports from their actual GT500:
- A real `.hpl` binary log — ran the project's existing (never-before-tested)
  `HPLNativeWaveformDecoderRev85.probe()` against it. Result: correctly extracted 68 real
  channel names, but found **zero reliable float-encoded value matches** — confirms the
  native binary decoder is not yet functional, exactly as the project's own docs predicted
  ("experimental until admitted by evidence"). The 68 real channel names WERE used to
  extend `CanonicalChannel`/`ChannelResolver`/`MeasurementAtlas` with 7 new real-world
  channels (`timingAdvance`, `ambientAirTemp`, `barometricPressure`,
  `fuelTrimShortTerm1`/`fuelTrimLongTerm1`, `inferredOctane`, `borderlineKnock`) plus 10
  new aliases on existing channels — all honestly labeled as "channel name confirmed in a
  real export, units/scaling still unverified."
- **`sep1.csv` / `sep2.csv`** — real CSV exports that turned out to be the actual source
  data behind the hardcoded "flagship forensics" narrative already in
  `Services/GT500FlagshipForensicsRev77.swift` (a real "Insufficient Fuel Flow" R04
  protection event at t=5.838s, RPM 6969, matching the code's hardcoded provenance points
  exactly). Ran the REAL `R04InvestigationEngine.scoreHypotheses` against genuinely
  extracted real values (not synthetic) and got an honest, informative result: **2 of the
  engine's 5 hypotheses couldn't even be scored** because this real export lacks injector
  pulse-width, max-PW, and fuel-pressure-commanded channels entirely (confirmed absent
  from all 60 real columns) — only `h4DCTTransient` (60, via a label-text proxy, not a
  real gear-state channel) and the `h5PIDIdentity` baseline (10) scored. This is now a
  permanent regression test: `PredatorLabTests/RealR04EventFixtureTests.swift`, backed by
  a real 234-row trimmed fixture at `PredatorLabTests/Fixtures/sep2_real_r04_event.csv`.

### ✅ The `StreamingCSVIngestor` "Offset" timestamp bug — FIXED
The bug this section used to describe (timestamp-column detection required the substring
`"time"`, so real HP Tuners exports using the column name `"Offset"` failed to parse) is
fixed: `Services/StreamingCSVIngestor.swift:38` and `CSVLogParser.swift`'s
`ChannelResolver.aliases[.time]` both now match `"offset"`. Verified against TWO
independent real exports: the trimmed `sep2_real_r04_event.csv` fixture (header restored
to its real unmodified `"Offset"` — no more fixture-only workaround) and a second, newer
450-row real fixture trimmed from `sep1.csv` (`RealSep1CSVParserTests.swift`), both parse
correctly today.

**RevNN header convention:** every `*RevNN.swift` file across `Services/`,
`Views/Components/`, `PredatorLabTests/`, etc. carries a standard 3-5 line comment block
right after its `import` line(s), stating (a) that the revision number refers to a step in
the external "PredatorLab-Expanded-Hardening" lineage this project ported from — NOT this
app's own version history — and (b) a status of "Current", "Superseded by <file>", or
"Independent/standalone". When adding a new `RevNN`-named file, apply the same header.

## Known open items / recommended next steps, in priority order

1. **`DomainDiagnosticExecution` DOES have a UI entry point** (correction of a previous
   claim in this doc) — `MultiDomainDiagnosticsView.swift`, triggered from
   `AnalysisModeView.swift:263`. Not fully dead-code as once thought.
2. **HPL numeric value decoding — real progress, still incomplete.** CDG chunk payloads
   are confirmed raw DEFLATE (see "HPL CDG chunk payload value-decoding investigation"
   below) and decompress to real strings, but the binary record framing for *numeric*
   channel values inside the decompressed stream has not been cracked. Next step: parse
   the decompressed stream as a sequential variable-length record structure (not a
   fixed-offset array — that was tried against the *compressed* bytes before the
   compression discovery and correctly failed), using
   `HPLCDGPayloadDeflateDecoderRev94.decompressRawDeflate` as the entry point.
3. **Product-facing surfaces confirmed real, not stubs** (traced the actual code paths,
   not just assumed): CSV import (`AnalysisModeView.swift` `.fileImporter` →
   `CSVLogParser.parseHPTunerCSV` → `LogEventDetector.detectAllEvents` → saved
   `ImportedLog`) and the R04/multi-domain diagnostics flow are both real, wired,
   reachable UI paths — not service-layer-only. `.hpt` files are already implicitly
   rejected by the import picker's `allowedContentTypes: [.commaSeparatedText,
   .plainText]` (OS-level filtering), so no explicit refusal UI is needed there.
4. **Confirmed real gap**: `GT500Vehicle`'s `pcmController`/`pcmStrategy`/`pcmOS` fields,
   entered during onboarding, are stored but never read by any Service or View outside
   `Models/Core/GT500Models.swift` itself — genuinely inert data today. Either wire them
   into something (e.g. gating which `MeasurementAtlas`/`HPTunerLoggingProfile` entries
   are considered applicable) or stop asking for them at onboarding.
5. **`HPTunerLoggingProfile.swift` (real ParameterID→name table) and `ChannelResolver`
   (name-based alias matching) are two separate systems that don't talk to each other.**
   Worth a real design pass: could `ChannelResolver` consult the verified profile table as
   a stronger-confidence match path for logs from this same vehicle/profile?
6. **If more "hardening" zips arrive, triage fast before auditing deeply.** Pattern that's
   worked across several zips this session: check the bundle's own `MERGE_NOTES.md`/
   `*-VALIDATION.md` first — if its own "validation" is just static source-file counting
   (`swiftc -parse` or similar, never a real Xcode build), treat every claim in it as
   unverified. Small, self-contained files with no undefined dependencies (checked via
   `grep` against the current tree) are cheap to verify and port; large "convergence"/
   "hardening" bundles that mostly re-supply files already in the tree are mostly noise —
   spot-check a few for genuine differences before doing a full read-through of everything.
   One recent zip (Rev96) was ~95% noise/duplication with one genuinely useful file; the
   next (Rev101) was almost entirely good, coherent, real work. There's no shortcut around
   actually checking — bundle size and naming don't predict quality.
7. **Physical-device install** — needs the user's Xcode Accounts sign-in (Settings →
   Accounts, remove/re-add if stale), then `xcodebuild ... -destination
   'id=<device-udid>' -allowProvisioningUpdates build` + `xcrun devicectl device install
   app`. Status since the original sign-in issue is unknown to this handoff.
8. **Real-world diagnostic validation is currently 1-for-1.** The R04 engine has been
   validated against exactly one real ground-truth event (`sep2.csv`'s "Insufficient Fuel
   Flow"). That's a good start, not broad confidence — if more real telemetry becomes
   available, extending this to a second, different real scenario would meaningfully
   de-risk the diagnostic engine's credibility claims.
9. **No real end-user has driven this UI.** A lot of design/UX work has happened without
   real user feedback in the loop — worth getting an actual GT500 owner (ideally the one
   who supplied the real telemetry) to use the app hands-on when there's something worth
   showing.

## Quick reference: build & test commands
```bash
cd "/Users/serendipity/Library/Mobile Documents/com~apple~CloudDocs/PREDATORMVP"
xcodegen generate
xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -destination 'generic/platform=iOS Simulator' -configuration Debug build

# Full test run needs a concrete simulator, not "generic":
xcrun simctl create "PredatorLab-Test" "iPhone 16 Pro"
xcodebuild -project PredatorLab.xcodeproj -scheme PredatorLab -destination 'id=<udid-from-above>' test
xcrun simctl delete <udid-from-above>

# Headless screenshot without XCUITest (bypasses onboarding via launch arg):
xcrun simctl install <udid> <path-to-.app>
xcrun simctl launch <udid> com.predatorlab.PredatorLab -DiagnosticSkipOnboarding -UITestReset YES
xcrun simctl io <udid> screenshot output.png

# Extract screenshots taken inside an XCUITest run (via XCTAttachment):
xcodebuild ... -resultBundlePath run.xcresult test
xcrun xcresulttool export attachments --path run.xcresult --output-path ./screenshots
```

## HPL "CDG" chunk payload value-decoding investigation (2026-09-15) — mixed result: real compression + string evidence found, numeric channel framing NOT cracked

Attempted to go beyond `HPLStructuralDecoderRev94.swift`'s structural-only scan (SYNC
marker + counter + tag) and actually decode real channel *values* out of the ~12–13KB of
payload bytes between one "CDG" chunk's 22-byte header and the next chunk's header, using
`log-000002-20260911-235344-redacted.hpl` (124 CDG chunks) cross-checked against
`sep1.csv` (the real, same-vehicle CSV export independently verified in an earlier session
to be from the same logging session). Full methodology and numbers below so the next
person doesn't have to redo this from scratch.

**Update partway through this investigation:** an initial brute-force numeric
value-correlation search (documented below, unchanged from when it was written) came up
completely empty and looked like a clean negative result — until a byte-entropy check on
the payload (7.97 bits/byte, i.e. indistinguishable from random) prompted trying
decompression. **The CDG chunk payload is raw DEFLATE-compressed** (RFC 1951, no
zlib/gzip header — `zlib.decompressobj(wbits=-15)` in Python, `COMPRESSION_ZLIB` via
Apple's Compression framework in Swift, which despite the name decodes headerless raw
DEFLATE). This was verified, not assumed:
- All 124 CDG chunk payloads in `log-000002...hpl` decompress successfully.
- The decompressed byte count matches the chunk header's 4-byte "declared length" field
  (`HPLObservedChunkRev94.declaredDecodedLength`) **exactly, for all 124 chunks**. That
  field was previously only "informally observed, plausible-looking" per
  `HPLStructuralDecoderRev94.swift`'s own comments — this promotes it to independently
  verified: it is the real decompressed-length field of a real DEFLATE stream.
- The decompressed bytes contain real, length-prefixed, human-readable ASCII strings that
  exactly match this vehicle's real HP Tuners enum values from `sep1.csv` — e.g. "Neutral
  Limit", "No Limit Active", "Idle Control", "Torque Control", "Alt Full Load", "Idle
  Speed Limit", "CL - Normal" — found hundreds of times combined across the 124 chunks
  (not a one-off coincidence).

This is now implemented in `PredatorLab/Services/HPLCDGPayloadDeflateDecoderRev94.swift`
(decompression + permissive printable-string extraction, both used only as evidence — see
that file's header comment for exactly what is and isn't claimed) and wired into
`TelemetryArtifactDecoder.swift`'s `HPLStructuralArtifactDecoder.decode()`, which now
decompresses every CDG chunk in the real artifact being decoded and reports real,
freshly-computed decompression/length-match counts in its evidence notes. It still
returns **zero** `DecodedTelemetryChannel`s — see below for why the numeric side isn't
done — verified with a real fixture
(`PredatorLab/PredatorLabTests/Fixtures/log000002_cdg_chunk10_deflate_payload.bin`, the
real, unmodified, 12,313-byte compressed payload for CDG chunk index 10 of the real file)
in `HPLCDGPayloadDeflateDecoderRev94Tests.swift`.

**What is still NOT established (do not skip this — it's the reason no numeric channels
are decoded):** the decompressed stream's binary record framing around the strings and
presumed numeric fields was explored by hand (short ~9-byte-ish records: a 1-byte
tag/index, a near-constant 3-byte run, a 1-byte "type", 4 bytes of payload) but a
hypothesis mapping the small integer "type"/index bytes to `HPTunerLoggingProfile.channels`
array positions did NOT hold up: decoded float32 values for what should have been
Scheduled Torque / ETC Torque Request / Desired Brake Torque / IPC Wheel Torque Error came
out as 0.86 / 124.48 / 30.16 / 2.68, nowhere near this vehicle's real idle-range values for
those channels (~92 / ~22 / ~2 / ~0 respectively, per `sep1.csv`) — though it's also
unverified whether this file's 12.3-second window temporally overlaps the specific CSV
rows being compared (see below), so this mismatch is suggestive, not conclusive, evidence
against the hypothesis. The original brute-force int16/float32 offset-correlation search
below was run against the *compressed* bytes (before the DEFLATE discovery) and is
therefore not informative about the real (decompressed) record layout — it has not been
re-run against decompressed data with a correct streaming record parser. That re-run,
plus properly reverse-engineering the record framing (likely by decompressing many chunks
and diffing consecutive frames to see which bytes move in small, physically-plausible
increments), is real, valuable, scoped future work — do not re-attempt a naive
fixed-offset scan; decompress first, then parse the record stream sequentially since
fields are variable-length (strings) and a fixed-width assumption misaligns after the
first one.

What was re-verified (matches prior session's claims):
- Python re-implementation of the SYNC scan found the same 126 total chunks (124 "CDG", 1
  "SC", 1 "SS") as the Swift decoder / prior session.
- CDG counter deltas are consistent: min 100000, max 100123 between consecutive chunks —
  genuinely near-constant ~100000-unit ticks.
- Total elapsed time spanned by this .hpl's 124 CDG chunks, if the counter is interpreted
  as microseconds (`counter / 1e6`), is **12.3 seconds**. Byte-gaps between consecutive
  chunk offsets are ~12,300–13,650 bytes, i.e. one CDG chunk's full payload corresponds to
  ~100ms of real time — consistent with the fastest-polled channel (Engine RPM, 100ms
  interval) updating once per chunk. This is a real, self-consistent finding.

The key new finding that undermines any hope of cross-correlating this file against
`sep1.csv`: **`sep1.csv` spans 1247.8 seconds** (30,022 rows at a resampled ~40ms output
interval, per its own `Offset` column: -3353.892s to -2106.078s). The `.hpl` file's 124
CDG chunks span only 12.3 seconds. So even if this `.hpl` and `sep1.csv` come from the
same overall session (as HANDOFF previously inferred from the ~2-second-apart creation
timestamps), this particular `.hpl` is at best a ~1%-duration slice of that CSV's time
range, and we do not know — and could not determine — *which* 12.3-second slice.

Attempted to find that slice (and a value encoding) via brute-force cross-correlation:
- For six real channels (Engine RPM, Engine Coolant Temp, Vehicle Speed, Intake Air Temp,
  Control Module Voltage, Barometric Pressure — all SAE-verified names from
  `HPTunerLoggingProfile.swift`), built every possible int16-LE decode of the chunk
  payload (offsets 0 through ~12,274 within each of the 124 chunks) and Pearson-correlated
  each candidate offset's 124-value sequence against every possible 12.3s-long sliding
  window of the corresponding CSV channel (linearly resampled to 124 points), stepped
  across the CSV's full 30,022-row span.
- This is ~36 million (offset × window) trials per channel. The best correlation found
  for any channel, any offset, any window position, was never higher than **|r| ≈ 0.51**
  (Control Module Voltage, likely spurious — see below), and typically ~0.35–0.45 for the
  others.
- Critically, these "best" correlations were **not reproducible or consistent across
  channels**: each channel's best-fit offset and window position were essentially
  uncorrelated with each other (different offsets, different windows, no shared alignment
  that would indicate "here's where the real 60-channel record starts"). A real decode
  would be expected to line up at the *same* window position for every channel (since
  they're all sampled from the same file/time slice), typically at high correlation
  (|r| > 0.9). Getting ~0.4–0.5 max out of tens of millions of trials on effectively
  random noise is exactly what basic order-of-magnitude statistics predicts by chance
  (SE ≈ 1/√124 ≈ 0.09 per trial; the max of millions of roughly-independent draws lands
  around 4–5 SE ≈ 0.4–0.5) — this is the noise ceiling of the search, not a signal.
- Also tried float32-LE at every byte offset (not just even offsets) across the same
  payload region for Engine RPM: **zero** candidate offsets decoded to a value inside a
  generously plausible RPM range (-1000 to 10000) consistently across all 124 chunks.
  Every offset produced at least one wildly out-of-range or non-finite value somewhere
  in the file.
- Computed Shannon entropy of a representative CDG chunk's inter-header payload: **7.97
  bits/byte** (out of a theoretical max of 8.0). This is effectively indistinguishable
  from random/compressed/encrypted data. Real fixed-point telemetry samples for these
  channels (RPM 655–5065, temperatures in the 60–200°F range, etc.) would be expected to
  show materially lower entropy — small numbers encode with predictable leading
  zero/0xFF bytes, and repeated near-constant readings (idle RPM, steady coolant temp)
  would produce byte-level repetition. Near-8-bits/byte entropy strongly suggests this
  payload region is compressed and/or otherwise encoded in a way that isn't a simple
  fixed-offset scalar array — a linear byte-offset search (what was attempted) is not
  capable of finding a value in genuinely high-entropy/compressed data regardless of how
  thorough the search is.

**This is exactly what happened next:** the "what this does not rule out" guess above
("actual compression... was not tested") turned out to be the answer — see the update at
the top of this section. The `declaredDecodedLength` field is the real post-decompression
length, confirmed exactly across all 124 chunks.

**Outcome:** `HPLCDGPayloadDeflateDecoderRev94.swift` (decompression + string extraction,
evidence-only) and its real-fixture regression test
(`HPLCDGPayloadDeflateDecoderRev94Tests.swift`) were added, and
`TelemetryArtifactDecoder.swift`'s `HPLStructuralArtifactDecoder.decode()` now runs real
decompression over every CDG chunk and reports real counts in its evidence notes. It still
returns **zero** `DecodedTelemetryChannel`s — evidence class stays `.observed`
(structural + decompression/string evidence), not `.experimentallyMapped` or
`.sourceVerified` — because no numeric per-channel value mapping was established (see the
update above for exactly why, and what the honest next step is). Do not attempt a simple
fixed-offset int16/float32 scalar decode of the *compressed* CDG bytes — that's the
already-refuted approach this section originally documented. Any future attempt should
decompress first (now trivial via `HPLCDGPayloadDeflateDecoderRev94.decompressRawDeflate`)
and parse the decompressed stream as a sequential variable-length record stream, not a
fixed-offset array.

## Key files to know
- `project.yml` — xcodegen project definition (edit this, never the `.xcodeproj`)
- `PredatorLab/DesignSystem/PLTheme.swift` — design system + `.plHardBottomEdge()`
- `PredatorLab/State/AppState.swift` — central app state
- `PredatorLab/Services/CSVLogParser.swift` — HP Tuners CSV import, canonical channel
  resolution — **has the known timestamp-detection bug above, needs fixing**
- `PredatorLab/Services/R04InvestigationEngine.swift` +
  `Services/DomainDiagnosticExecution.swift` — the diagnostic reasoning core
- `PredatorLab/PredatorLabTests/RealR04EventFixtureTests.swift` — real-world regression
  test, good reference for what "honest about missing evidence" looks like in practice
- `PredatorLabUITests/PredatorLabFullJourneyTests.swift` — the comprehensive UI test,
  good reference for what user flow must never break
