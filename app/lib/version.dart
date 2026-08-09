// The ONE user-facing version string (settings About footer).
// Hand-sourced from pubspec.yaml — test/version_sync_test.dart fails the
// suite on drift, so the mirror can't rot silently. The 0.x scheme itself is
// PROPOSED, pending Arnar's versioning session (see pubspec.yaml). At
// production this moves to package_info_plus so the binary reports its real
// version; no new dependency for the alpha.

const kAppVersion = '0.5.0';

/// The ONE footer string (6a, turn 6): '· you own this copy' is appended only
/// when a purchase receipt makes it true — the mock annotation "drops 'you
/// own this copy' until the receipt makes it true". No billing exists yet, so
/// every caller passes owned: false today.
String versionFooter({required bool owned}) =>
    'MyReciBook $kAppVersion${owned ? ' · you own this copy' : ''}';
