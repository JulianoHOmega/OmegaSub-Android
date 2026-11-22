import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
import sys
import types

# Isolate the existing Subliminal engine for tests without external network.
if 'subliminal' not in sys.modules:
    try:
        import subliminal
    except ImportError:
        m = types.ModuleType('subliminal')
        for name in ('scan_video', 'list_subtitles', 'download_subtitles', 'save_subtitles'):
            setattr(m, name, lambda *a, **k: None)
        score = types.ModuleType('subliminal.score')
        score.compute_score = lambda *a: 0
        m.score = score
        sys.modules['subliminal'] = m
        sys.modules['subliminal.score'] = score
        b = types.ModuleType('babelfish')
        b.Language = lambda *a: 'por-BR'
        sys.modules['babelfish'] = b
from subtitle_engine import download, videos_in

class BatchSafetyTests(unittest.TestCase):
    def test_video_folder_recursive(self):
        with TemporaryDirectory() as d:
            base = Path(d)
            (base / 'season').mkdir()
            (base / 'season' / 'episode.MKV').write_bytes(b'')
            (base / 'notes.txt').write_text('x')
            self.assertEqual(len(videos_in(base)), 1)

    def test_does_not_overwrite_existing_srt(self):
        with TemporaryDirectory() as d:
            p = Path(d) / 'movie.mp4'
            p.write_bytes(b'')
            sub = p.with_suffix('.srt')
            sub.write_text('original', encoding='utf-8')
            with patch('subtitle_engine.download_subtitles') as fetch:
                with self.assertRaises(FileExistsError):
                    download(p, object(), object())
                fetch.assert_not_called()
            self.assertEqual(sub.read_text(encoding='utf-8'), 'original')

if __name__ == '__main__':
    unittest.main()
