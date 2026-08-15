// Feature flags — surfaces that are BUILT but hidden, never deleted.
//
// Arnar's rule from the 2026-08-06 hands-on pass: "I don't like dead-ends that
// don't do anything" — a surface with no engine behind it must not be reachable
// by a tester. Hiding, not deleting: the code and its tests stay green so the
// switch is one line when the engine lands.

/// Meal plan (`ui/plan_tab.dart`). No engine, no design turn — hidden from the
/// nav bar and drawer since 2026-08-06.
///
/// NOT a scope cut: context.md's week-two retention hook is "a grocery list
/// that merges duplicates, syncs with the MEAL PLAN, and remembers category
/// corrections". Cutting it for real edits the bet and the landing-page copy —
/// that decision is open, and this flag is not it.
const bool kMealPlanEnabled = false;

/// "Your copy" drawer row (design 5b): the account-less ownership surface —
/// receipt, restore, export. No entitlement engine until billing 3g (behind
/// the Play fee), so the row was a label that did nothing. Hidden 2026-08-06
/// (Arnar: "no idea what the purpose of it is"); flips on with 3g.
const bool kYourCopyEnabled = false;

/// Recipe tag chips beyond Favorites (Quick / Sweet in the cookbook filter row).
/// The chips are drawn in turn 1 and hi-fi 3d, but no turn ever drew how a
/// recipe GETS a tag, so they filtered on nothing. Favorites-only until a
/// tagging design exists (Arnar's call, 2026-08-06).
const bool kRecipeTagsEnabled = false;

/// Unlock tab in nav slot 2 — the 3g paywall pitch promoted from the debug
/// gallery to a real tab, replacing the Import queue tab (Arnar's call,
/// 2026-08-15: "the queue page is kinda useless… a better place for users to
/// buy the app"). The queue keeps living as the pushed batch route plus the
/// Cookbook attention strip; only its TAB retires.
///
/// The purchase CTA states its own engine status until billing 3g lands
/// (Play fee → Console app → one-time product) — same honesty pattern as the
/// storage screen's "awaiting keys" caption. Off flips slot 2 back to the
/// queue tab unchanged.
const bool kUnlockTabEnabled = true;

/// "Spread the word" rows on the Unlock tab (rate on Google Play · share
/// with a friend). Both need a live destination — the Play listing for
/// rating, at least the landing page (live 2 Sep) for the share link — so
/// they stay hidden until one exists (dead-end rule). Flip = one line here
/// plus real handlers in unlock_tab.dart.
const bool kSpreadWordEnabled = false;
