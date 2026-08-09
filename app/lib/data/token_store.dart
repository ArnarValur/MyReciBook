// Persisted TokenSet per storage provider ('drive' / 'dropbox'): the
// injectable-file JSON pattern of AppSettings plus tmp+rename writes, so a
// mid-write kill can never corrupt saved tokens. Corrupt/missing file →
// start clean (a re-connect beats a crash). App-private file storage is the
// alpha bar — production hardening: consider EncryptedSharedPreferences.

import 'dart:convert';
import 'dart:io';

import 'atomic_file.dart';
import 'oauth.dart' show TokenSet;

class TokenStore {
  TokenStore._(this._file, this._data);

  final File _file;
  final Map<String, dynamic> _data;

  static Future<TokenStore> load(File file) async {
    Map<String, dynamic> data = {};
    try {
      if (await file.exists()) {
        data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {} // corrupt store: start clean, connectors just re-auth
    return TokenStore._(file, data);
  }

  /// Stored tokens for 'drive' / 'dropbox'; null = disconnected (absent or
  /// malformed entry — same stance).
  TokenSet? tokens(String provider) {
    final entry = _data[provider];
    if (entry is! Map) return null;
    try {
      return TokenSet.fromJson(entry.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Write-through; null clears (disconnect). Atomic replace keeps the
  /// previous file intact until the new one is fully on disk.
  Future<void> setTokens(String provider, TokenSet? tokens) async {
    if (tokens == null) {
      _data.remove(provider);
    } else {
      _data[provider] = tokens.toJson();
    }
    await writeStringAtomic(_file, jsonEncode(_data));
  }
}
