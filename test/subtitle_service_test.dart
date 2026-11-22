import 'package:flutter_test/flutter_test.dart';
import 'package:omegasub_android/subtitle_service.dart';
import 'package:omegasub_android/video_info.dart';
void main() {
  test('interpreta resultados de pesquisa', () {
    final links = SubtitleService.parseSearchPage('<a href="subs/123/Filme.2026.html">Filme</a>');
    expect(links.length, 1);
    expect(links.first.host, 'www.subtitlecat.com');
  });
  test('aceita apenas arquivos PT-BR existentes', () {
    final links = SubtitleService.parsePortugueseLinks('<a id="download_en" href="/subs/1/en.srt">EN</a><a id="download_pb" href="/subs/2/pb.srt">PT</a><button id="pt">Traduzir</button>');
    expect(links.length, 1);
    expect(links.single.path, '/subs/2/pb.srt');
  });
  test('busca com ano e alternativas sem acentos', () {
    final video = VideoInfo('A odisseia (2026).mp4', 'A odisseia', 2026, null, null);
    final queries = SubtitleService.buildSearchQueries(video, alternateTitle: 'The Odyssey');
    expect(queries, contains('A odisseia 2026'));
    expect(queries, contains('The Odyssey'));
    expect(queries, contains('A odisseia'));
  });
  test('segmentos com porcentagem não exigem segunda decodificação', () {
    final links = SubtitleService.parseSearchPage(
      '<a href="/subs/123/Filme.100%25.Completo.html">Filme</a>');
    expect(links.length, 1);
    expect(links.single.pathSegments.last, contains('100%'));
  });
  test('reconhece links de resultados absolutos', () {
    final links = SubtitleService.parseSearchPage(
      '<a href="https://www.subtitlecat.com/subs/123/Filme.2026.html">Filme</a>');
    expect(links.length, 1);
  });
}
