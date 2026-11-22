import unittest
from types import SimpleNamespace
from subtitle_engine import release_label, candidate_key

class ResultsTests(unittest.TestCase):
    def test_release_info(self):
        self.assertEqual(release_label(SimpleNamespace(release_info=' WEB-DL\n1080p ')), 'WEB-DL 1080p')
    def test_missing_release(self):
        self.assertEqual(release_label(SimpleNamespace()), 'Não informado')
    def test_same_provider_id(self):
        a = SimpleNamespace(provider_name='x', id='12')
        b = SimpleNamespace(provider_name='x', id='12')
        self.assertEqual(candidate_key(a), candidate_key(b))
    def test_different_provider(self):
        a = SimpleNamespace(provider_name='x', id='12')
        b = SimpleNamespace(provider_name='y', id='12')
        self.assertNotEqual(candidate_key(a), candidate_key(b))

if __name__ == '__main__':
    unittest.main()
