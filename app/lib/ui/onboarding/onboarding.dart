// The first-run flow: welcome → setup → slides → app.
//
// Shell only, 2026-08-27. Arnar is designing the welcome art and will supply
// the slide screenshots; every screen here is deliberately empty where his
// content goes, and says so on screen rather than faking a design.

/// Onboarding revision this build ships. Compared against
/// AppSettings.onboardingSeen: lower means the flow runs.
///
/// Bump it after a release worth introducing and the slides replay for
/// everyone as a short "what shipped" intro — Arnar's call 2026-08-27, and
/// the reason the seen-marker is a number rather than a bool. Leave it alone
/// for fixes and polish; a flow that replays for nothing trains people to hit
/// Skip before they read it.
///
/// The marker lives in device.json (excluded from backup), so a fresh install
/// always replays regardless of this number.
const int kOnboardingVersion = 1;
