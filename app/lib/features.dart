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
