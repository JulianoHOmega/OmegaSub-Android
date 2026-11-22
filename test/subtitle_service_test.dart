import 'package:flutter_test/flutter_test.dart';
import 'package:omegasub_android/subtitle_service.dart';
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
}
