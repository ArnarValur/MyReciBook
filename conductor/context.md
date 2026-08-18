# Context — MyReciBook
*Project truth. Changes only by Arnar's agreement. Point at this file, don't retell it.*

## The bet — do not re-litigate without new evidence
- Screenshot-first import + user-owned files + pay-once.
- Pitch: "Collect the recipes buried in your camera roll."
- A grocery list that merges duplicates, syncs with the meal plan,
  and remembers category corrections.
- Android-first is the moat — "no Android" is a top complaint against Crouton,
  Mela and Pestle, and none can follow quickly.

## Hard constraints — say it loudly when a plan breaks one
1. Linux + Flutter/Dart + Galaxy S21. No Mac, so no Swift or Xcode path exists.
   On-device OCR free (ML Kit) + a cheap cloud vision model for structuring.
   Play Store one-time purchase. Local files + Drive + Dropbox, no iCloud.
2. Pay-once, hard paywall, stated fair-use AI cap in the listing from day one.
   Never "unlimited forever" — it cannot be clawed back.
3. No backend beyond a thin extraction proxy. One JSON file (exportable in other formats) per recipe in the user's own storage. The proxy is stateless except the per-install cap counter,
   and never stores recipe content.
4. Build order: extract → save → list → open. Paywall, sync and polish come after
   the alpha ships.