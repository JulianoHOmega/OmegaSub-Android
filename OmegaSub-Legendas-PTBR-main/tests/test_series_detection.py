import unittest
from series_detection import identify_episode, mismatched_episode_release

class SeriesDetectionTests(unittest.TestCase):
    def test_numbered_episode_parent_season(self):
        info = identify_episode('D:/Alien - Earth/1 (2025)/1 - Terra do nunca.mp4')
        self.assertEqual((info.series, info.season, info.episode, info.year), ('Alien - Earth', 1, 1, 2025))
    def test_later_episode(self):
        info = identify_episode('D:/Alien - Earth/1 (2025)/8 - Os monstros de verdade.mkv')
        self.assertEqual((info.season, info.episode), (1, 8))
    def test_movie_not_misclassified(self):
        self.assertIsNone(identify_episode('D:/Filmes/A odisseia (2026).mp4'))
    def test_explicit_sxe(self):
        info = identify_episode('D:/Alien - Earth/Season 1/Alien.Earth.S01E03.mkv')
        self.assertEqual((info.series, info.season, info.episode), ('Alien - Earth', 1, 3))
    def test_mismatch(self):
        info = identify_episode('D:/Alien - Earth/1 (2025)/1 - Terra do nunca.mp4')
        self.assertTrue(mismatched_episode_release('Other.Show.S02E01.srt', info))
        self.assertFalse(mismatched_episode_release('Alien.Earth.S01E01.srt', info))
        self.assertFalse(mismatched_episode_release('Sem dados', info))

if __name__ == '__main__': unittest.main()
