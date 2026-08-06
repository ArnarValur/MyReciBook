// TokenStore: per-provider round-trip, tmp+rename hygiene, corrupt → clean.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/oauth.dart';
import 'package:myrecibook/data/token_store.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_token_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  File file() => File('${tmp.path}/nested/tokens.json');

  test('missing file → no tokens for any provider', () async {
    final store = await TokenStore.load(file());
    expect(store.tokens('drive'), isNull);
    expect(store.tokens('dropbox'), isNull);
  });

  test('round-trip both providers, survives reload, leaves no .tmp', () async {
    final store = await TokenStore.load(file());
    final expiry = DateTime.now().add(const Duration(hours: 1));
    await store.setTokens('drive',
        TokenSet(accessToken: 'at-d', refreshToken: 'rt-d', expiresAt: expiry));
    await store.setTokens('dropbox', const TokenSet(accessToken: 'at-x'));

    final reloaded = await TokenStore.load(file());
    final drive = reloaded.tokens('drive')!;
    expect(drive.accessToken, 'at-d');
    expect(drive.refreshToken, 'rt-d');
    expect(drive.expiresAt, expiry);
    final dropbox = reloaded.tokens('dropbox')!;
    expect(dropbox.accessToken, 'at-x');
    expect(dropbox.refreshToken, isNull);
    expect(dropbox.expiresAt, isNull);
    expect(File('${file().path}.tmp').existsSync(), isFalse);
  });

  test('setTokens null clears (disconnect)', () async {
    final store = await TokenStore.load(file());
    await store.setTokens('drive', const TokenSet(accessToken: 'at'));
    await store.setTokens('drive', null);
    expect(store.tokens('drive'), isNull);
    expect((await TokenStore.load(file())).tokens('drive'), isNull);
  });

  test('corrupt file → starts clean and stays writable', () async {
    await file().create(recursive: true);
    await file().writeAsString('{not json');
    final store = await TokenStore.load(file());
    expect(store.tokens('drive'), isNull);
    await store.setTokens('drive', const TokenSet(accessToken: 'at'));
    expect((await TokenStore.load(file())).tokens('drive')!.accessToken, 'at');
  });

  test('malformed entry (wrong shape) reads as disconnected', () async {
    await file().create(recursive: true);
    await file().writeAsString(jsonEncode({
      'drive': 'not-a-map',
      'dropbox': {'refresh_token': 'rt-only'}, // missing access_token
    }));
    final store = await TokenStore.load(file());
    expect(store.tokens('drive'), isNull);
    expect(store.tokens('dropbox'), isNull);
  });
}
