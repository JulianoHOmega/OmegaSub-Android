import unittest
from types import SimpleNamespace
from matching import evaluate, choose_automatic, episode_marker, release_tokens

class MatchingTests(unittest.TestCase):
    def test_episode_marker(self):
        self.assertEqual(episode_marker('Show.S02E09.1080p'), (2, 9))
    def test_release(self):
        self.assertIn('1080p', release_tokens('Film.WEB-DL.1080p'))
    def test_correct_title_and_year(self):
        v = SimpleNamespace(name='Film.2026.WEB-DL.1080p.mkv', title='Film', year=2026)
        s = SimpleNamespace(movie_name='Film', movie_year=2026)
        result = evaluate(v, s, 100, 'Film WEB-DL 1080p')
        self.assertTrue(result['safe'])
        self.assertEqual(result['confidence'], 'Boa correspondência')
    def test_wrong_year(self):
        v = SimpleNamespace(name='Film.2026.mkv', title='Film', year=2026)
        s = SimpleNamespace(movie_name='Film', movie_year=2024)
        self.assertFalse(evaluate(v, s, 100, 'Film 2024')['safe'])
    def test_wrong_episode_release(self):
        v = SimpleNamespace(name='Show.S01E02.mkv', series='Show', season=1, episode=2)
        s = SimpleNamespace()
        self.assertFalse(evaluate(v, s, 100, 'Show.S01E03.WEB-DL')['safe'])
    def test_choose_safe(self):
        a = {'assessment': {'safe': False, 'rank': 999}}
        b = {'assessment': {'safe': True, 'rank': 120}}
        self.assertIs(choose_automatic([a, b]), b)
        self.assertIsNone(choose_automatic([a]))

if __name__ == '__main__':
    unittest.main()
