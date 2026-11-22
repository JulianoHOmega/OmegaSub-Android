import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'video_info.dart';

class SubtitleEntry {
  final String title, release, language, url, provider;
  final int? year, season, episode;
  final int score;
  const SubtitleEntry({required this.title, required this.release,
    required this.language, required this.url, required this.provider,
    this.year, this.season, this.episode, this.score = 0});
}

class SubtitleService {
  // Public HTTPS URL for the OmegaSub Python/Subliminal service.
  // Configure in GitHub Actions as a repository variable OMEGASUB_API_URL.
  static const apiUrl = String.fromEnvironment('OMEGASUB_API_URL');
  static final http.Client _client = http.Client();

  static Uri get _base {
    final uri = Uri.tryParse(apiUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
        uri.userInfo.isNotEmpty || uri.query.isNotEmpty || uri.fragment.isNotEmpty) {
      throw StateError('Servidor Subliminal não configurado. Defina OMEGASUB_API_URL '
          'com o endereço HTTPS do backend no GitHub Actions.');
    }
    return uri;
  }

  static Uri _endpoint(String path) => _base.replace(
      path: '${_base.path.replaceAll(RegExp(r'/$'), '')}$path');

  static Future<List<SubtitleEntry>> search(VideoInfo video,
      {String? alternateTitle, void Function(String)? onProgress}) async {
    onProgress?.call('Consultando provedores pelo Subliminal...');
    final payload = <String, dynamic>{
      'filename': video.fileName,
      'title': alternateTitle != null && alternateTitle.trim().isNotEmpty
          ? alternateTitle.trim() : video.title,
      if (video.year != null) 'year': video.year,
      if (video.season != null) 'season': video.season,
      if (video.episode != null) 'episode': video.episode,
    };
    final response = await _client.post(_endpoint('/v1/search'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      throw StateError('Pesquisa Subliminal indisponível (HTTP ${response.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map || decoded['results'] is! List) {
      throw const FormatException('Resposta inválida do servidor Subliminal.');
    }
    return (decoded['results'] as List).map((raw) {
      if (raw is! Map || raw['id'] is! String) {
        throw const FormatException('Resultado de legenda inválido.');
      }
      return SubtitleEntry(
        title: video.title,
        release: '${raw['release'] ?? 'Não informado'}',
        language: 'PT-BR',
        provider: '${raw['provider'] ?? 'Subliminal'}',
        url: _endpoint('/v1/download/${raw['id']}').toString(),
        score: (raw['score'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static Future<Uint8List> download(SubtitleEntry entry) async {
    final uri = Uri.tryParse(entry.url);
    final base = _base;
    if (uri == null || uri.scheme != 'https' || uri.host != base.host ||
        uri.port != base.port || !uri.path.startsWith('${base.path.replaceAll(RegExp(r'/$'), '')}/v1/download/')) {
      throw StateError('Endereço de download inválido.');
    }
    final response = await _client.get(uri).timeout(const Duration(seconds: 90));
    if (response.statusCode != 200) {
      throw StateError('Download indisponível (HTTP ${response.statusCode}). Pesquise novamente.');
    }
    if (response.bodyBytes.isEmpty || response.bodyBytes.length > 12 * 1024 * 1024) {
      throw StateError('Arquivo de legenda vazio ou muito grande.');
    }
    return response.bodyBytes;
  }
}
