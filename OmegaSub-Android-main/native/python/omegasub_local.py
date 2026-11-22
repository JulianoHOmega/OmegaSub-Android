"""Subliminal embutido no APK. Não usa Render nem API própria."""
import json
import secrets
import threading
from babelfish import Language
from subliminal import list_subtitles, download_subtitles
from subliminal.video import Movie, Episode
from subliminal.score import compute_score

LANGUAGE = Language('por', 'BR')
_cache = {}
_lock = threading.RLock()

def _score(sub, video):
    try:
        value = compute_score(sub, video)
        return int(value[0] if isinstance(value, (tuple, list)) else value)
    except Exception:
        return 0

def search(payload):
    req = json.loads(payload)
    filename = str(req['filename']).split('/')[-1].split('\\')[-1]
    title = str(req['title']).strip()
    if not title:
        raise ValueError('Título de pesquisa vazio.')
    year = req.get('year')
    season, episode = req.get('season'), req.get('episode')
    if (season is None) != (episode is None):
        raise ValueError('Temporada e episódio devem ser informados juntos.')
    if season is not None:
        video = Episode(filename, title, int(season), [int(episode)], year=year)
    else:
        video = Movie(filename, title, year=year)
    subtitles = list(list_subtitles({video}, {LANGUAGE}).get(video, []))
    subtitles = [sub for sub in subtitles if sub.language == LANGUAGE]
    subtitles.sort(key=lambda sub: _score(sub, video), reverse=True)
    result = []
    with _lock:
        _cache.clear()
        seen = set()
        for sub in subtitles[:100]:
            provider = str(getattr(sub, 'provider_name', 'Subliminal'))
            release = str(getattr(sub, 'release_info', None) or getattr(sub, 'release', None) or getattr(sub, 'filename', None) or 'Versão não informada')[:160]
            key = (provider, str(getattr(sub, 'id', release)))
            if key in seen:
                continue
            seen.add(key)
            token = secrets.token_hex(16)
            _cache[token] = sub
            result.append({'id': token, 'release': release, 'provider': provider,
                           'language': 'PT-BR', 'score': _score(sub, video)})
    return json.dumps({'results': result}, ensure_ascii=False)

def download(token):
    with _lock:
        sub = _cache.get(token)
    if sub is None:
        raise ValueError('Legenda expirada. Pesquise novamente.')
    download_subtitles([sub])
    content = sub.content
    if not content or len(content) > 12 * 1024 * 1024:
        raise ValueError('Legenda vazia ou muito grande.')
    return bytes(content)
