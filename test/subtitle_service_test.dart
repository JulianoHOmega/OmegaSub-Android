import 'package:flutter_test/flutter_test.dart';
import 'package:omegasub_android/subtitle_service.dart';

void main() {
  test('bloqueia download externo ao backend', () async {
    await expectLater(
      SubtitleService.download(const SubtitleEntry(
        title: 'Filme', release: 'Filme', language: 'PT-BR',
        provider: 'Subliminal', url: 'https://example.com/sub.srt')),
      throwsA(isA<StateError>()),
    );
  });
}
