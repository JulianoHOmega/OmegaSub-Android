import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'video_info.dart';

class SubtitleEntry {
  final String title, release, language, url, provider;
  final int? year, season, episode;
  final int score;
  const SubtitleEntry({required this.title, required this.release, required this.language,
    required this.url, required this.provider, this.year, this.season, this.episode, this.score = 0});
  SubtitleEntry withScore(int s) => SubtitleEntry(title:title, release:release, language:language,
    url:url, provider:provider, year:year, season:season, episode:episode, score:s);
}

class SubtitleService {
  // Catálogo público opcional mantido pelo projeto. Não é uma API de legendas de terceiros.
  static const catalogUrl = String.fromEnvironment('OMEGASUB_CATALOG_URL', defaultValue: '');
  static final _client = http.Client();

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  static int? _number(dynamic v) => v is int ? v : int.tryParse('$v');
  static List<SubtitleEntry> parseCatalog(String body, VideoInfo video) {
    final decoded = jsonDecode(body);
    if (decoded is! Map || decoded['subtitles'] is! List) throw const FormatException('Catálogo inválido');
    final found = <SubtitleEntry>[];
    for (final raw in decoded['subtitles'] as List) {
      if (raw is! Map) continue;
      final title = '${raw['title'] ?? ''}'.trim();
      final url = '${raw['url'] ?? ''}'.trim();
      final language = '${raw['language'] ?? ''}'.toLowerCase();
      final uri = Uri.tryParse(url);
      if (title.isEmpty || uri == null || uri.scheme != 'https' || uri.host.isEmpty) continue;
      if (!{'pt-br', 'pt_br', 'pob', 'brazilian', 'portuguese (brazil)'}.contains(language)) continue;
      final year = _number(raw['year']);
      final season = _number(raw['season']);
      final episode = _number(raw['episode']);
      if (_norm(title) != _norm(video.title)) continue;
      if (video.year != null && year != null && video.year != year) continue;
      if (video.isEpisode) {
        if (season != video.season || episode != video.episode) continue;
      } else if (season != null || episode != null) { continue; }
      final release = '${raw['release'] ?? title}';
      final videoRelease = _norm(video.fileName);
      final subtitleRelease = _norm(release);
      var score = 60;
      if (year != null && year == video.year) score += 15;
      if (video.isEpisode) score += 20;
      for (final tag in ['1080p', '720p', '2160p', 'bluray', 'webrip', 'web dl', 'hdtv']) {
        if (videoRelease.contains(tag) && subtitleRelease.contains(tag)) score += 4;
      }
      found.add(SubtitleEntry(title:title, release:release, language:language, url:url,
        provider:'${raw['provider'] ?? 'Catálogo OmegaSub'}', year:year, season:season,
        episode:episode, score:score));
    }
    found.sort((a,b) => b.score.compareTo(a.score));
    return found;
  }

  // Fonte experimental pública: SubtitleCat, sem conta ou chave.
  static const _origin = 'https://www.subtitlecat.com';
  static const _headers = {'User-Agent': 'OmegaSub-Android/0.2'};

  static String _fold(String input) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to =   'aaaaaeeeeiiiiooooouuuucn';
    var result = input.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  static String _decodeHtml(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');

  static List<Uri> parseSearchPage(String html) {
    final found = <Uri>[];
    final seen = <String>{};
    // Aceita links relativos, absolutos, com ou sem barra inicial e query string.
    final re = RegExp(r'''href\s*=\s*['"]([^'"]*?/subs/\d+/[^'"<>]+?\.html(?:\?[^'"]*)?|subs/\d+/[^'"<>]+?\.html(?:\?[^'"]*)?)['"]''', caseSensitive: false);
    for (final match in re.allMatches(html)) {
      final raw = _decodeHtml(match.group(1)!);
      // Links externos podem conter '%' solto: ignore apenas o link inválido.
      final relative = Uri.tryParse(raw);
      if (relative == null) continue;
      final url = Uri.parse(_origin).resolveUri(relative);
      if (url.scheme == 'https' && url.host == 'www.subtitlecat.com' &&
          seen.add(url.toString())) {
        found.add(url);
        if (found.length >= 25) break;
      }
    }
    return found;
  }

  static List<Uri> parsePortugueseLinks(String html) {
    final found = <Uri>[];
    final seen = <String>{};
    for (final match in RegExp(r'<a\b[^>]*>', caseSensitive: false).allMatches(html)) {
      final tag = match.group(0)!;
      final id = RegExp(r'''id\s*=\s*['"]download_([^'"]+)['"]''', caseSensitive: false)
          .firstMatch(tag)?.group(1)?.toLowerCase();
      if (!{'pb', 'pt', 'pt-br', 'pt_br', 'pob'}.contains(id)) continue;
      final href = RegExp(r'''href\s*=\s*['"]([^'"]+\.srt(?:\?[^'"]*)?)['"]''', caseSensitive: false)
          .firstMatch(tag)?.group(1);
      if (href == null) continue;
      final relative = Uri.tryParse(_decodeHtml(href));
      if (relative == null) continue;
      final url = Uri.parse(_origin).resolveUri(relative);
      if (url.scheme == 'https' && url.host == 'www.subtitlecat.com' && seen.add(url.toString())) {
        found.add(url);
      }
    }
    return found;
  }

  static int _score(VideoInfo video, String release, {String? alternateTitle}) {
    final normalized = _norm(_fold(release));
    final candidate = _norm(_fold(alternateTitle ?? video.title));
    final words = candidate.split(' ').where((w) => w.length > 2).toList();
    if (words.isEmpty || !words.every(normalized.contains)) return -1;
    if (video.year != null && RegExp(r'\b(?:19|20)\d{2}\b').hasMatch(release) &&
        !normalized.contains('${video.year}')) return -1;
    if (video.isEpisode) {
      final episode = RegExp(r's(\d{1,2})[ ._-]*e(\d{1,3})|(?<!\d)(\d{1,2})x(\d{1,3})', caseSensitive: false).firstMatch(release);
      if (episode == null ||
          int.parse((episode.group(1) ?? episode.group(3))!) != video.season ||
          int.parse((episode.group(2) ?? episode.group(4))!) != video.episode) return -1;
    }
    var score = 60;
    if (video.year != null && normalized.contains('${video.year}')) score += 15;
    if (video.isEpisode) score += 20;
    final file = _norm(video.fileName);
    for (final tag in ['1080p', '720p', '2160p', 'bluray', 'webrip', 'web dl', 'hdtv']) {
      if (file.contains(tag) && normalized.contains(tag)) score += 4;
    }
    return score;
  }

  static List<String> buildSearchQueries(VideoInfo video, {String? alternateTitle}) {
    final titles = <String>[
      video.title,
      if (alternateTitle != null && alternateTitle.trim().isNotEmpty) alternateTitle.trim(),
    ];
    final result = <String>[];
    final seen = <String>{};
    for (final title in titles) {
      final variants = [title, _fold(title)];
      for (final variant in variants) {
        for (final q in [
          if (video.year != null) '$variant ${video.year}',
          if (video.isEpisode) '$variant S${video.season.toString().padLeft(2, '0')}E${video.episode.toString().padLeft(2, '0')}',
          variant,
        ]) {
          final clean = q.trim();
          if (clean.isNotEmpty && seen.add(clean.toLowerCase())) result.add(clean);
        }
      }
    }
    return result;
  }

  static Future<List<SubtitleEntry>> _searchPublic(VideoInfo video,
      {String? alternateTitle, void Function(String)? onProgress}) async {
    final queries = buildSearchQueries(video, alternateTitle: alternateTitle);
    final pages = <Uri>[];
    final seenPages = <String>{};
    var succeeded = 0;
    final failures = <String>[];
    for (var i = 0; i < queries.length; i++) {
      final query = queries[i];
      onProgress?.call('Pesquisando: $query (${i + 1}/${queries.length})...');
      try {
        final uri = Uri.parse('$_origin/index.php')
            .replace(queryParameters: {'search': query});
        final response = await _client.get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          failures.add('HTTP ${response.statusCode}');
          continue;
        }
        succeeded++;
        final html = utf8.decode(response.bodyBytes, allowMalformed: true);
        for (final page in parseSearchPage(html)) {
          if (seenPages.add(page.toString())) pages.add(page);
        }
      } catch (e) {
        failures.add('$e');
      }
      if (pages.length >= 20) break;
    }
    if (succeeded == 0) {
      throw StateError('A fonte não respondeu às pesquisas. '
          '${failures.isEmpty ? 'Verifique a conexão.' : failures.first}');
    }
    if (pages.isEmpty) {
      throw StateError('A fonte respondeu, mas não retornou links reconhecíveis. '
          'O formato do site pode ter mudado ou a pesquisa não encontrou títulos.');
    }
    final results = <SubtitleEntry>[];
    var detailsOk = 0;
    for (var i = 0; i < pages.length && i < 20; i++) {
      final page = pages[i];
      // pathSegments já retorna o segmento decodificado. Uma segunda
      // decodificação quebra nomes contendo '%' (Illegal percent encoding).
      final release = page.pathSegments.last
          .replaceFirst(RegExp(r'\.html$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[._]+'), ' ');
      final score = _score(video, release);
      final alternateScore = alternateTitle == null ? -1
          : _score(video, release, alternateTitle: alternateTitle);
      final bestScore = score > alternateScore ? score : alternateScore;
      if (bestScore < 0) continue;
      onProgress?.call('Verificando legendas PT-BR (${i + 1}/${pages.length})...');
      try {
        final detail = await _client.get(page, headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (detail.statusCode != 200) continue;
        detailsOk++;
        for (final link in parsePortugueseLinks(
            utf8.decode(detail.bodyBytes, allowMalformed: true))) {
          results.add(SubtitleEntry(title: video.title, release: release,
              language: 'pt-br', url: link.toString(), provider: 'SubtitleCat',
              year: video.year, season: video.season, episode: video.episode,
              score: bestScore));
        }
      } catch (_) {
        // Falha em uma página não cancela as demais.
      }
    }
    if (results.isEmpty && detailsOk == 0) {
      throw StateError('Resultados encontrados, mas nenhuma página de detalhes '
          'pôde ser lida. O site pode estar bloqueando o acesso.');
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  static Future<List<SubtitleEntry>> search(VideoInfo video,
      {String? alternateTitle, void Function(String)? onProgress}) async {
    if (catalogUrl.isEmpty) {
      return _searchPublic(video, alternateTitle: alternateTitle,
          onProgress: onProgress);
    }
    onProgress?.call('Consultando catálogo...');
    final uri = Uri.parse(catalogUrl);
    if (uri.scheme != 'https') throw StateError('O catálogo deve usar HTTPS.');
    final response = await _client.get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('Catálogo indisponível (HTTP ${response.statusCode}).');
    }
    return parseCatalog(utf8.decode(response.bodyBytes), video);
  }

  static Future<Uint8List> download(SubtitleEntry entry) async {
    final uri = Uri.parse(entry.url);
    if (uri.scheme != 'https') throw StateError('Download precisa usar HTTPS.');
    final response = await _client.get(uri).timeout(const Duration(seconds:25));
    if (response.statusCode != 200) throw StateError('Download falhou (HTTP ${response.statusCode}).');
    if (response.bodyBytes.length > 12 * 1024 * 1024) throw StateError('Legenda muito grande.');
    final bytes = response.bodyBytes;
    if (bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4b) {
      final zip = ZipDecoder().decodeBytes(bytes);
      for (final file in zip.files) {
        if (file.isFile && file.name.toLowerCase().endsWith('.srt')) {
          return Uint8List.fromList(file.content);
        }
      }
      throw StateError('ZIP não contém arquivo .srt.');
    }
    if (bytes.isEmpty) throw StateError('Legenda vazia.');
    return Uint8List.fromList(bytes);
  }
}
