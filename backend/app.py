"""OmegaSub API: Subliminal runs on Python host, never inside the APK."""
import os
import secrets
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel, Field
from babelfish import Language
from subliminal import list_subtitles, download_subtitles
from subliminal.video import Movie, Episode
from subliminal.score import compute_score

app = FastAPI(title="OmegaSub Subliminal API", docs_url=None, redoc_url=None)
LANGUAGE = Language('por', 'BR')
TTL = 20 * 60
MAX_ENTRIES = 200
CACHE = {}
LOCK = threading.RLock()
POOL = ThreadPoolExecutor(max_workers=4)

class SearchRequest(BaseModel):
    filename: str = Field(min_length=1, max_length=255)
    title: str = Field(min_length=1, max_length=200)
    year: int | None = Field(default=None, ge=1888, le=2100)
    season: int | None = Field(default=None, ge=0, le=100)
    episode: int | None = Field(default=None, ge=0, le=10000)

def make_video(req):
    # No local video transfer: Subliminal queries metadata from the filename.
    name = Path(req.filename).name
    if (req.season is None) != (req.episode is None):
        raise HTTPException(422, 'Temporada e episódio devem ser informados juntos.')
    if req.season is not None:
        return Episode(name, req.title, req.season, [req.episode], year=req.year)
    return Movie(name, req.title, year=req.year)

def score(sub, video):
    try:
        value = compute_score(sub, video)
        return int(value[0] if isinstance(value, (tuple, list)) else value)
    except Exception:
        return 0

def release_label(sub):
    for field in ('release_info', 'release', 'filename'):
        value = getattr(sub, field, None)
        if value:
            return ' '.join(str(value).split())[:160]
    return 'Versão não informada'

def _cleanup():
    now = time.monotonic()
    for key, value in list(CACHE.items()):
        if value[0] < now:
            del CACHE[key]
    while len(CACHE) > MAX_ENTRIES:
        CACHE.pop(next(iter(CACHE)))

@app.get('/health')
def health():
    return {'status': 'ok', 'engine': 'subliminal'}

@app.post('/v1/search')
def search(req: SearchRequest):
    video = make_video(req)
    try:
        subtitles = list(list_subtitles({video}, {LANGUAGE}).get(video, []))
    except Exception as exc:
        raise HTTPException(502, f'Falha ao consultar provedores: {type(exc).__name__}') from exc
    subtitles = [s for s in subtitles if s.language == LANGUAGE]
    subtitles.sort(key=lambda s: score(s, video), reverse=True)
    results = []
    seen = set()
    with LOCK:
        _cleanup()
        for sub in subtitles[:150]:
            provider = str(getattr(sub, 'provider_name', 'Subliminal'))
            release = release_label(sub)
            key = (provider, str(getattr(sub, 'id', release)))
            if key in seen:
                continue
            seen.add(key)
            token = secrets.token_urlsafe(24)
            CACHE[token] = (time.monotonic() + TTL, video, sub)
            results.append({'id': token, 'release': release, 'provider': provider,
                            'language': 'PT-BR', 'score': score(sub, video)})
        _cleanup()
    return {'results': results}

@app.get('/v1/download/{token}')
def download(token: str):
    with LOCK:
        _cleanup()
        item = CACHE.get(token)
    if item is None:
        raise HTTPException(404, 'Resultado expirado. Pesquise novamente.')
    _, video, subtitle = item
    try:
        download_subtitles([subtitle])
        content = subtitle.content
    except Exception as exc:
        raise HTTPException(502, f'Falha ao baixar legenda: {type(exc).__name__}') from exc
    if not content:
        raise HTTPException(502, 'Provedor retornou legenda vazia.')
    if len(content) > 12 * 1024 * 1024:
        raise HTTPException(502, 'Legenda excede o limite de tamanho.')
    return Response(content=content, media_type='application/octet-stream',
                    headers={'Cache-Control': 'no-store',
                             'Content-Disposition': 'attachment; filename="subtitle.srt"'})
