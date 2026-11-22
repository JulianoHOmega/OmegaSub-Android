import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
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
  static const MethodChannel _python = MethodChannel('omegasub/python');

  static Future<List<SubtitleEntry>> search(VideoInfo video,
      {String? alternateTitle, void Function(String)? onProgress}) async {
    onProgress?.call('Consultando provedores pelo Subliminal no celular...');
    final payload = <String, dynamic>{
      'filename': video.fileName,
      'title': alternateTitle != null && alternateTitle.trim().isNotEmpty
          ? alternateTitle.trim() : video.title,
      if (video.year != null) 'year': video.year,
      if (video.season != null) 'season': video.season,
      if (video.episode != null) 'episode': video.episode,
    };
    final raw = await _python.invokeMethod<String>('search', jsonEncode(payload))
        .timeout(const Duration(seconds: 100));
    if (raw == null) throw StateError('Resposta vazia do Subliminal local.');
    final decoded = jsonDecode(raw);
    if (decoded is! Map || decoded['results'] is! List) {
      throw const FormatException('Resposta inválida do Subliminal local.');
    }
    return (decoded['results'] as List).map((item) {
      if (item is! Map || item['id'] is! String) {
        throw const FormatException('Resultado de legenda inválido.');
      }
      return SubtitleEntry(
        title: video.title,
        release: '${item['release'] ?? 'Não informado'}',
        language: 'PT-BR',
        provider: '${item['provider'] ?? 'Subliminal'}',
        url: item['id'] as String,
        score: (item['score'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  static Future<Uint8List> download(SubtitleEntry entry) async {
    if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(entry.url)) {
      throw StateError('Identificador de legenda inválido. Pesquise novamente.');
    }
    final data = await _python.invokeMethod<Uint8List>('download', entry.url)
        .timeout(const Duration(seconds: 100));
    if (data == null || data.isEmpty || data.length > 12 * 1024 * 1024) {
      throw StateError('Legenda vazia ou excede 12 MB.');
    }
    return data;
  }
}
