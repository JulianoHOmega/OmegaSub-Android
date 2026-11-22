import 'package:flutter_test/flutter_test.dart';
import 'package:omegasub_android/video_info.dart';

void main() {
  test('identifica filme e ano', () {
    final video = VideoInfo.parse('A.Odisseia.2026.1080p.mkv');
    expect(video.title, 'A Odisseia');
    expect(video.year, 2026);
    expect(video.isEpisode, isFalse);
  });

  test('identifica episódio e temporada', () {
    final video = VideoInfo.parse('Minha.Serie.S02E03.WEB-DL.mp4');
    expect(video.title, 'Minha Serie');
    expect(video.season, 2);
    expect(video.episode, 3);
    expect(video.isEpisode, isTrue);
  });

  test('não interpreta filme como episódio', () {
    final video = VideoInfo.parse('Meu.Filme.2025.mp4');
    expect(video.title, 'Meu Filme');
    expect(video.year, 2025);
    expect(video.season, isNull);
    expect(video.episode, isNull);
    expect(video.isEpisode, isFalse);
  });
}
