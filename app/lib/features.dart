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

/// User-invented recipe tags: Settings → Tags to make them, a tag row on the
/// recipe page to apply them, chips in the cookbook filter row to filter by
/// them. Turned ON 2026-08-27 — the tagging design that 2026-08-06 was waiting
/// for is conductor/tracks/tags/plan.md, and it is built.
///
/// The flag also gates Quick, which is computed from the recipe's own times.
/// Sweet is gone: it guessed from a word list and nothing could ever earn it.
const bool kRecipeTagsEnabled = true;

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

/// Pantry POC (`ui/pantry/`) — scan a barcode, OFF fills the product, one
/// JSON per product in the user's pantry folder (docs/pantry, beside
/// recipes). ON borrows nav slot 2 from the Unlock tab for on-device testing
/// (Arnar's call, 2026-08-17); flipping this false restores Unlock untouched.
/// Not sync'd yet: the sync layout confines to root *.json + images/, so the
/// pantry folder needs its own sync case before it travels.
const bool kPantryEnabled = true;

/// Meal diary (`ui/diary/`) — day files, servings, snapshot entries. Shares
/// nav slot 3 with the pantry behind a Diary/Pantry segmented control
/// (Arnar's call, 2026-08-19). Off restores the pantry tab untouched.
const bool kDiaryEnabled = true;

/// "Spread the word" rows on the Unlock tab (rate on Google Play · share
/// with a friend). Both need a live destination — the Play listing for
/// rating, at least the landing page (live 2 Sep) for the share link — so
/// they stay hidden until one exists (dead-end rule). Flip = one line here
/// plus real handlers in unlock_tab.dart.
const bool kSpreadWordEnabled = false;


/// Quick add — a diary line that is calories and nothing else, for the meal
/// out nobody is going to itemise. The engine is real and tested
/// (quickAddEntry, DiaryModel.logQuickAdd); only its door is hidden.
///
/// Parked 2026-08-27: design 2a drops the sheet's Scan / Create food / Quick
/// add row, and Arnar did not recognise what Quick add was — a feature nobody
/// can name from its label is not earning its place in the one sheet you use
/// to log food. The code stays because the need is real and the next design
/// pass may give it a better name and a better home. Flip this to bring the
/// chip back; nothing else has to change.
const bool kQuickAddEnabled = false;
