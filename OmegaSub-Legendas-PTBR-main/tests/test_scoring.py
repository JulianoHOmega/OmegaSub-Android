import unittest
from unittest.mock import patch
from subtitle_engine import subtitle_score

class TestScore(unittest.TestCase):
    @patch("subliminal.score.compute_score", return_value=42)
    def test_integer(self, mock):
        self.assertEqual(subtitle_score(object(), object()), 42)

    @patch("subliminal.score.compute_score", return_value=(42, set()))
    def test_tuple(self, mock):
        self.assertEqual(subtitle_score(object(), object()), 42)

if __name__ == "__main__":
    unittest.main()
