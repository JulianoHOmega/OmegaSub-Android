"""Subtitle discovery/download via Subliminal providers."""
from pathlib import Path
import re
from subliminal import scan_video, list_subtitles, download_subtitles, save_subtitles
from babelfish import Language
from series_detection import identify_episode, mismatched_episode_release

EXTENSIONS = {'.mkv', '.mp4', '.avi', '.mov', '.wmv', '.m4v', '.ts', '.webm'}
LANGUAGE = Language('por', 'BR')


def videos_in(path):
    target = Path(path)
    if target.is_file():
        return [target] if target.suffix.lower() in EXTENSIONS else []
    return sorted(p for p in target.rglob('*') if p.is_file() and p.suffix.lower() in EXTENSIONS)


def subtitle_exists(path):
    p = Path(path)
    return any(p.with_suffix(ext).exists() for ext in ('.srt', '.ass', '.ssa', '.sub')) or any(
        x.is_file() and x.suffix.lower() in {'.srt', '.ass', '.ssa'} and x.stem.lower().startswith(p.stem.lower() + '.')
        for x in p.parent.iterdir()
    )


def subtitle_score(subtitle, video):
    """Subliminal versions return either an int or a (score, matches) tuple."""
    from subliminal.score import compute_score
    result = compute_score(subtitle, video)
    return result[0] if isinstance(result, (tuple, list)) else result


def release_label(sub):
    """Prefer provider release metadata; never invent a release."""
    for attr in ('release_info', 'release', 'filename'):
        value = getattr(sub, attr, None)
        if value:
            if isinstance(value, (list, tuple, set)):
                value = ', '.join(map(str, value))
            label = re.sub(r'\s+', ' ', str(value)).strip()
            if label:
                return label[:140]
    return 'Não informado'


def candidate_key(sub):
    """Keep distinct IDs; deduplicate exact provider/release pairs when ID absent."""
    provider = str(getattr(sub, 'provider_name', '')).casefold()
    identifier = getattr(sub, 'id', None)
    if identifier is not None:
        return (provider, 'id', str(identifier))
    release = release_label(sub)
    if release == 'Não informado':
        return (provider, 'object', id(sub))
    return (provider, 'release', release.casefold(), str(getattr(sub, 'language', '')))


def search(path):
    video = scan_video(str(path))
    episode_info = identify_episode(path)
    if episode_info:
        # Subliminal's scanner cannot infer the series from files such as
        # "1 - Terra do nunca.mp4". Construct an Episode explicitly.
        from subliminal.video import Episode
        video = Episode(str(path), episode_info.series, episode_info.season,
                        [episode_info.episode], title=episode_info.title,
                        year=episode_info.year)
    results = list(list_subtitles({video}, {LANGUAGE}).get(video, []))
    # Keep PT-BR and rank by release matching (Subliminal scoring).
    results = [s for s in results if s.language == LANGUAGE]
    if episode_info:
        # Do not offer a subtitle that explicitly names a different season/episode.
        results = [s for s in results if not mismatched_episode_release(release_label(s), episode_info)]
    results.sort(key=lambda s: subtitle_score(s, video), reverse=True)
    # Remove only repeated provider IDs, preserving distinct releases and revisions.
    unique = []
    seen = set()
    for item in results:
        key = candidate_key(item)
        if key in seen:
            continue
        seen.add(key)
        unique.append(item)
    return video, unique[:150]


def describe(sub, video):
    score = subtitle_score(sub, video)
    return {'provider': sub.provider_name, 'release': release_label(sub), 'language': 'PT-BR', 'score': score, 'subtitle': sub}


def download(path, video, subtitle, overwrite=False):
    output = Path(path).with_suffix('.srt')
    if output.exists() and not overwrite:
        raise FileExistsError(f"Legenda já existe: {output.name}. O arquivo não foi sobrescrito.")
    # Fetch subtitle content and save with the video's basename.
    download_subtitles([subtitle])
    if not subtitle.content:
        raise RuntimeError('O provedor não retornou o conteúdo da legenda.')
    save_subtitles(video, [subtitle], single=True)
    if not output.exists():
        raise RuntimeError('A legenda foi baixada, mas não foi encontrada no destino esperado.')
    return output
