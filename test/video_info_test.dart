import 'package:flutter_test/flutter_test.dart';
import 'package:omegasub_android/video_info.dart';
import 'package:omegasub_android/subtitle_service.dart';
void main() {
  test('identifica filme e ano', () {
    final v=VideoInfo.parse('A.Odisseia.2026.1080p.mkv');
    expect(v.title,'A Odisseia'); expect(v.year,2026); expect(v.isEpisode,false);
  });
  test('identifica episódio', () {
    final v=VideoInfo.parse('Minha.Serie.S02E03.WEB-DL.mp4');
    expect(v.title,'Minha Serie'); expect(v.season,2); expect(v.episode,3);
  });
  test('não mistura episódios e filtra idioma', () {
    final v=VideoInfo.parse('Minha.Serie.S02E03.mkv');
    final results=SubtitleService.parseCatalog('''{"subtitles":[
      {"title":"Minha Serie","language":"pt-br","season":2,"episode":3,"url":"https://example.org/a.srt"},
      {"title":"Minha Serie","language":"pt-br","season":2,"episode":4,"url":"https://example.org/b.srt"},
      {"title":"Minha Serie","language":"en","season":2,"episode":3,"url":"https://example.org/c.srt"}
    ]}''',v);
    expect(results.length,1);
  });
}
