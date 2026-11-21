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

  static Future<List<SubtitleEntry>> search(VideoInfo video) async {
    if (catalogUrl.isEmpty) throw StateError('Nenhuma fonte de legendas configurada. O projeto inclui a interface e o mecanismo de busca, mas ainda precisa de um catálogo público autorizado para pesquisas reais.');
    final uri = Uri.parse(catalogUrl);
    if (uri.scheme != 'https') throw StateError('O catálogo deve usar HTTPS.');
    final response = await _client.get(uri, headers:{'Accept':'application/json'}).timeout(const Duration(seconds:15));
    if (response.statusCode != 200) throw StateError('Catálogo indisponível (HTTP ${response.statusCode}).');
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
          final content = file.content;
          return Uint8List.fromList(content);
        }
      }
      throw StateError('ZIP não contém arquivo .srt.');
    }
    if (bytes.isEmpty) throw StateError('Legenda vazia.');
    return Uint8List.fromList(bytes);
  }
}
