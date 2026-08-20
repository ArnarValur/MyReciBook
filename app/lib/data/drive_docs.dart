// Recipe → a real Google Doc, for users who already connected Drive
// (export track, step 2). Not a second sync path: this writes ONE document
// the user asked for, into the same MyReciBook folder their recipes mirror
// into, and hands back a link.
//
// How the conversion works: Drive converts an uploaded file when the
// metadata asks for a Google mimeType. We upload HTML — it survives the
// conversion with headings, lists and bold intact, where plain text arrives
// as one grey slab.
//
// Scope stays drive.file. A document this app created is a file this app
// created, so no new consent screen and no Google verification round.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'recipe_pdf.dart';
import 'remote_store.dart';

/// Thrown when Drive answers but not with a document — the caller turns this
/// into a snackbar, never a crash.
class DriveDocsException implements Exception {
  final String message;
  const DriveDocsException(this.message);
  @override
  String toString() => 'DriveDocsException: $message';
}

const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
const _api = 'https://www.googleapis.com/drive/v3';
const _docMime = 'application/vnd.google-apps.document';
const _folderMime = 'application/vnd.google-apps.folder';

/// Uploads [r] as a Google Doc and returns its webViewLink.
///
/// [folderName] mirrors DriveRemote's root so a user's exports land beside
/// their recipes instead of loose in My Drive.
Future<String> exportRecipeToGoogleDocs(
  AuthedClient client,
  RecipePdfData r, {
  String folderName = 'MyReciBook',
  String exportsFolder = 'exports',
}) async {
  final parentId = await _ensureFolder(
      client, exportsFolder, await _ensureFolder(client, folderName, null));

  final boundary = 'recibook-${r.title.hashCode.toRadixString(16)}';
  final metadata = jsonEncode({
    'name': r.title.isEmpty ? 'Recipe' : r.title,
    'mimeType': _docMime,
    'parents': [parentId],
  });

  final body = StringBuffer()
    ..writeln('--$boundary')
    ..writeln('Content-Type: application/json; charset=UTF-8')
    ..writeln()
    ..writeln(metadata)
    ..writeln('--$boundary')
    ..writeln('Content-Type: text/html; charset=UTF-8')
    ..writeln()
    ..writeln(recipeHtml(r))
    ..writeln('--$boundary--');

  final uri = Uri.parse('$_uploadApi/files')
      .replace(queryParameters: {'uploadType': 'multipart', 'fields': 'id'});

  final resp = await client.send(() => http.Request('POST', uri)
    ..headers['Content-Type'] = 'multipart/related; boundary=$boundary'
    ..bodyBytes = utf8.encode(body.toString()));

  if (resp.statusCode >= 300) {
    throw DriveDocsException('Drive refused the upload (${resp.statusCode})');
  }
  final id = (jsonDecode(utf8.decode(resp.bodyBytes)) as Map)['id'] as String?;
  if (id == null) throw const DriveDocsException('Drive returned no file id');

  final linkResp = await client.send(() => http.Request(
      'GET',
      Uri.parse('$_api/files/$id')
          .replace(queryParameters: {'fields': 'webViewLink'})));
  if (linkResp.statusCode >= 300) {
    // The document exists; only the link lookup failed. Send them to the
    // document by id rather than reporting a failure that did not happen.
    return 'https://docs.google.com/document/d/$id/edit';
  }
  final link = (jsonDecode(utf8.decode(linkResp.bodyBytes)) as Map)['webViewLink']
      as String?;
  return link ?? 'https://docs.google.com/document/d/$id/edit';
}

/// Finds or creates one folder, returning its id. [parentId] null = My Drive
/// root. Same shape DriveRemote uses, kept separate so an export can never
/// disturb the sync mirror's cached ids.
Future<String> _ensureFolder(
    AuthedClient client, String name, String? parentId) async {
  final parentClause =
      parentId == null ? "'root' in parents" : "'$parentId' in parents";
  final q = "name = '${name.replaceAll("'", r"\'")}' and "
      "mimeType = '$_folderMime' and $parentClause and trashed = false";
  final uri = Uri.parse('$_api/files')
      .replace(queryParameters: {'q': q, 'fields': 'files(id)'});
  final found = await client.send(() => http.Request('GET', uri));
  if (found.statusCode < 300) {
    final files = (jsonDecode(utf8.decode(found.bodyBytes)) as Map)['files']
        as List?;
    if (files != null && files.isNotEmpty) {
      return ((files.first as Map)['id'] as String);
    }
  }
  final created = await client.send(() =>
      http.Request('POST', Uri.parse('$_api/files'))
        ..headers['Content-Type'] = 'application/json; charset=utf-8'
        ..body = jsonEncode({
          'name': name,
          'mimeType': _folderMime,
          if (parentId != null) 'parents': [parentId],
        }));
  if (created.statusCode >= 300) {
    throw DriveDocsException('Could not create the $name folder');
  }
  return (jsonDecode(utf8.decode(created.bodyBytes)) as Map)['id'] as String;
}

/// The same content the PDF prints, as the HTML Drive converts into a Doc.
/// Shares [RecipePdfData] on purpose — one export model, so a field added for
/// the page cannot go missing from the document.
String recipeHtml(RecipePdfData r) {
  final b = StringBuffer()
    ..writeln('<!DOCTYPE html><html><head><meta charset="utf-8">')
    ..writeln('<title>${_esc(r.title)}</title></head><body>')
    ..writeln('<h1>${_esc(r.title)}</h1>');

  final meta = [
    if (r.servings != null && r.servings!.isNotEmpty) r.servings!,
    if (r.time != null && r.time!.isNotEmpty) r.time!,
  ].join(' &middot; ');
  if (meta.isNotEmpty) b.writeln('<p><i>$meta</i></p>');

  if (r.ingredients.isNotEmpty) {
    b.writeln('<h2>Ingredients</h2>');
    var open = false;
    for (var i = 0; i < r.ingredients.length; i++) {
      final group = r.groupBefore[i];
      if (group != null) {
        if (open) b.writeln('</ul>');
        b.writeln('<h3>${_esc(group)}</h3>');
        open = false;
      }
      if (!open) {
        b.writeln('<ul>');
        open = true;
      }
      b.writeln('<li>${_esc(r.ingredients[i])}</li>');
    }
    if (open) b.writeln('</ul>');
  }

  if (r.steps.isNotEmpty) {
    b.writeln('<h2>Method</h2><ol>');
    for (final s in r.steps) {
      b.writeln('<li>${_esc(s)}</li>');
    }
    b.writeln('</ol>');
  }

  final notes = r.notes?.trim();
  if (notes != null && notes.isNotEmpty) {
    b.writeln('<h2>Notes</h2><p>${_esc(notes)}</p>');
  }

  final n = r.nutrition;
  if (n != null) {
    b.writeln('<h2>Nutrition</h2>');
    b.writeln('<p><b>${_esc(n.headline)}</b>');
    if (n.macros.isNotEmpty) b.writeln('<br>${_esc(n.macros)}');
    b.writeln('<br><small>${_esc(n.note)}</small></p>');
  }

  final source = r.sourceLine;
  if (source != null && source.isNotEmpty) {
    b.writeln('<p><small>${_esc(source)}</small></p>');
  }

  b.writeln('<p><small>Made with MyReciBook</small></p>');
  return (b..writeln('</body></html>')).toString();
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
