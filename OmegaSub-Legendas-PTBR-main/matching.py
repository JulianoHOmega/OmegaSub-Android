"""Conservative subtitle matching heuristics; no network dependencies."""
import re
import unicodedata


def normalize(value):
    value = unicodedata.normalize('NFKD', str(value or ''))
    value = ''.join(ch for ch in value if not unicodedata.combining(ch))
    return re.sub(r'[^a-z0-9]+', ' ', value.casefold()).strip()


def release_tokens(value):
    text = normalize(value)
    groups = {
        'web': ('web dl', 'web rip', 'webdl', 'webrip'),
        'bluray': ('blu ray', 'bluray', 'bdrip', 'brrip'),
        'hdtv': ('hdtv',),
        'dvdrip': ('dvdrip', 'dvd rip'),
        '1080p': ('1080p',), '720p': ('720p',), '2160p': ('2160p', '4k'),
    }
    return {group for group, aliases in groups.items() if any(re.search(r'(?<!\w)' + re.escape(alias) + r'(?!\w)', text) for alias in aliases)}


def episode_marker(text):
    match = re.search(r'(?i)\bS(\d{1,2})[ ._-]*E(\d{1,3})\b', str(text or ''))
    return (int(match.group(1)), int(match.group(2))) if match else None


def evaluate(video, subtitle, base_score, release):
    """Return adjusted ranking and explicit contradictions, never claim verified sync."""
    reasons = []
    contradictions = []
    bonus = 0
    video_name = str(getattr(video, 'name', '') or '')
    video_title = getattr(video, 'title', None) or getattr(video, 'series', None)
    sub_title = getattr(subtitle, 'movie_name', None) or getattr(subtitle, 'series', None) or getattr(subtitle, 'title', None)
    if video_title and sub_title:
        if normalize(video_title) == normalize(sub_title):
            bonus += 25
            reasons.append('Título correspondente')
        else:
            contradictions.append('Título diferente')
    video_year = getattr(video, 'year', None)
    sub_year = getattr(subtitle, 'year', None) or getattr(subtitle, 'movie_year', None)
    if video_year and sub_year:
        if str(video_year) == str(sub_year):
            bonus += 15
            reasons.append('Ano correspondente')
        else:
            contradictions.append('Ano diferente')
    video_episode = (getattr(video, 'season', None), getattr(video, 'episode', None))
    sub_episode = (getattr(subtitle, 'season', None), getattr(subtitle, 'episode', None))
    if all(v is not None for v in video_episode) and all(v is not None for v in sub_episode):
        if video_episode == sub_episode:
            bonus += 35
            reasons.append('Episódio correspondente')
        else:
            contradictions.append('Temporada/episódio diferente')
    # Release labels sometimes include the episode marker even without structured metadata.
    release_ep = episode_marker(release)
    video_ep = episode_marker(video_name)
    if video_ep and release_ep and video_ep != release_ep:
        contradictions.append('Episódio do release diferente')
    video_tokens = release_tokens(video_name)
    subtitle_tokens = release_tokens(release)
    matched = video_tokens & subtitle_tokens
    if matched:
        bonus += 10 * len(matched)
        reasons.append('Release compatível: ' + ', '.join(sorted(matched)))
    if video_tokens & {'web', 'bluray', 'hdtv', 'dvdrip'} and subtitle_tokens & {'web', 'bluray', 'hdtv', 'dvdrip'} and not (video_tokens & subtitle_tokens & {'web', 'bluray', 'hdtv', 'dvdrip'}):
        reasons.append('Fonte do release diferente (sincronização incerta)')
    if contradictions:
        return {'rank': int(base_score) + bonus - 1000, 'confidence': 'Incompatível', 'reason': '; '.join(dict.fromkeys(contradictions)), 'safe': False}
    # Subliminal's base score reflects filename and provider matches. It is not proof of synchronization.
    rank = int(base_score) + bonus
    confidence = 'Boa correspondência' if bonus >= 25 else 'Estimativa'
    reason = '; '.join(reasons) if reasons else 'Sem dados adicionais para confirmar a versão'
    return {'rank': rank, 'confidence': confidence, 'reason': reason, 'safe': True}


def choose_automatic(rows):
    """Reject contradictory candidates; prefer rank, then stable provider order."""
    eligible = [row for row in rows if row['assessment']['safe']]
    return max(eligible, key=lambda row: row['assessment']['rank']) if eligible else None
