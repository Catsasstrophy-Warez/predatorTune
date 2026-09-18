# Project
Native iOS game architecture and telemetry rendering. Built entirely on Apple native frameworks: Swift 6, RealityKit, and Metal.

# Non-Negotiables
- Concurrency: Strict Swift 6 concurrency only. All UI and RealityKit state mutations must be isolated to `@MainActor`.
- Memory: Avoid unmanaged memory structures (e.g., `UnsafeMutablePointer`) unless interfacing directly with raw C buffers for telemetry or Metal shaders.
- Ecosystem: Rely strictly on Swift Package Manager. Do NOT suggest cross-platform tools, Unity patterns, or C# logic.

# Commands
This is an XcodeGen-managed iOS app project (not an SPM package), so it's built via `xcodebuild`, not `swift build`/`swift test`.

- Generate project: `xcodegen generate --spec project.yml`
- Build (simulator): `xcodebuild -scheme PredatorLab -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet build`
- Test: `xcodebuild -scheme PredatorLab -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -quiet test`
- Lint: `swiftlint lint --quiet`
- Full local CI gate: `./Scripts/ci.sh` (dynamically selects an available simulator)
*(Note: Always run commands with quiet flags to prevent console output from flooding the token context window).*

# Rendering Architecture
`PredatorLab/Rendering/` holds the RealityKit/Metal telemetry rendering stack, entered via `TelemetryRenderingView` (linked from RaceTrackHomeView's Pit Lane section):
- `Metal/` — `TelemetryWaveform.metal` + `TelemetryWaveformRenderer` (MTKView delegate) render a single channel as a GPU line strip. Use this path for high-frequency raw signal traces.
- `RealityKit/` — `GaugeClusterScene`/`GaugeClusterView` (3D dial cluster) and `TrackPathScene`/`TrackPathView` (3D magnitude-colored run path) both use `ARView` in `.nonAR` camera mode so no camera permission is requested.
- `TelemetryChannelSeries` / `TelemetryChannelSeriesAdapter` bridge `ParsedLogData` (from `AppState.currentLogData`) into the dense `[Double]` series these renderers consume, falling back to a deterministic demo series when no log is imported.

# Language & Style
- Omit explicit `return` in single-expression functions.
- Prefer `guard` over nested `if let` to prevent pyramid of doom.
- Use `os_log` for critical performance telemetry instead of standard print statements.
