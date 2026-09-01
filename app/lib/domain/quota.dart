// The fair-use numbers, as the app sees them (docs/ai-cap-mechanics.md §1–§2).
// The proxy attaches a `quota` object to every answer it owns — the successful
// extraction and the 429 denial alike — so the counter is current with zero
// extra network calls. This is the typed read of that object, plus the two
// derivations the counter card asks for.
//
// Forgiving on purpose: a field the proxy adds later, or drops, must never
// cost a user their extraction. Anything unreadable reads as "no quota here".

class QuotaSnapshot {
  const QuotaSnapshot({
    required this.used,
    required this.cap,
    this.graceUsed = 0,
    this.topupBalance = 0,
    this.graceUntil,
  });

  /// Rescues charged to the included grant. Free-fortnight spending is NOT
  /// in here — it lands in [graceUsed] (§1).
  final int used;

  /// The included grant the proxy is currently applying (1200 in the offer).
  /// It never refills — nothing resets, ever (Decision 1, 2026-09-01).
  final int cap;

  /// Rescues the free fortnight paid for. Recorded, never charged to [used].
  final int graceUsed;

  /// Never-expiring paid top-ups still in hand (§5). Kept because the proxy
  /// sends it; no UI shows it until top-ups are actually sellable.
  final int topupBalance;

  /// When the free fortnight closes. UTC.
  final DateTime? graceUntil;

  /// Null in, null out: a body carrying no `quota` — direct Gemini, an
  /// upstream error passed through — leaves the last known numbers standing.
  static QuotaSnapshot? fromJson(Object? json) {
    if (json is! Map) return null;
    // used+cap are the two the proxy always sends; without them this is some
    // other object that happens to sit under the same key.
    final used = json['used'];
    final cap = json['cap'];
    if (used is! num || cap is! num) return null;
    return QuotaSnapshot(
      used: used.toInt(),
      cap: cap.toInt(),
      graceUsed: _int(json['grace_used']),
      topupBalance: _int(json['topup_balance']),
      // A cached pre-Decision-1 copy may still carry `resets_at`; it is
      // ignored — nothing resets.
      graceUntil: _time(json['grace_until']),
    );
  }

  /// The proxy's own wire shape, so the cached copy is byte-for-byte what
  /// came back and re-reading it needs no second parser.
  Map<String, Object?> toJson() => {
        'used': used,
        'cap': cap,
        'grace_used': graceUsed,
        'topup_balance': topupBalance,
        if (graceUntil != null) 'grace_until': graceUntil!.toIso8601String(),
      };

  /// The free fortnight as §2 means it: the window is still open AND the
  /// included grant is untouched, so the card can honestly say "nothing
  /// counts yet". Past the grace ceiling the ladder starts charging [used],
  /// and that same sentence would be a lie.
  bool inGraceAt(DateTime now) =>
      used == 0 && graceUntil != null && now.toUtc().isBefore(graceUntil!);

  bool get inGrace => inGraceAt(DateTime.now());

  static int _int(Object? v) => v is num ? v.toInt() : 0;

  static DateTime? _time(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toUtc() : null;
}
