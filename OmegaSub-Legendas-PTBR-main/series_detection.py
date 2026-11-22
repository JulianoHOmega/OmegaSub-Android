"""Identify episodic files using their containing folders, without changing movie detection."""
from dataclasses import dataclass
from pathlib import Path
import re

@dataclass(frozen=True)
class EpisodeInfo:
    series: str
    season: int
    episode: int
    year: int | None = None
    title: str | None = None

EXPLICIT = re.compile(r'(?i)(?:\bS(\d{1,2})[ ._-]*E(\d{1,3})\b|\b(\d{1,2})x(\d{1,3})\b)')
NUMBERED = re.compile(r'^\s*(\d{1,3})\s*[-–.]\s*(.+)$')
SEASON_FOLDER = re.compile(r'(?i)^(?:temporada|season|saison|temp\.?|s)\s*0*(\d{1,2})(?:\s*\((\d{4})\))?$')
NUMERIC_SEASON = re.compile(r'^0*(\d{1,2})\s*(?:\((\d{4})\))?$')
YEAR = re.compile(r'\b(?:19|20)\d{2}\b')

def identify_episode(path):
    path = Path(path)
    stem = path.stem
    explicit = EXPLICIT.search(stem)
    if explicit:
        season = int(explicit.group(1) or explicit.group(3))
        episode = int(explicit.group(2) or explicit.group(4))
        folder = path.parent
        season_match = SEASON_FOLDER.fullmatch(folder.name) or NUMERIC_SEASON.fullmatch(folder.name)
        series_folder = folder.parent if season_match else folder
        series = series_folder.name.strip()
        if not series or series in ('.', '..'):
            return None
        year_match = YEAR.search(series)
        year = int(year_match.group()) if year_match else None
        series = re.sub(r'\s*\((?:19|20)\d{2}\)\s*$', '', series).strip()
        return EpisodeInfo(series, season, episode, year)
    folder = path.parent
    season_match = SEASON_FOLDER.fullmatch(folder.name) or NUMERIC_SEASON.fullmatch(folder.name)
    numbered = NUMBERED.match(stem)
    if not season_match or not numbered:
        return None
    season = int(season_match.group(1))
    episode = int(numbered.group(1))
    if not 1 <= season <= 50 or not 1 <= episode <= 999:
        return None
    series = folder.parent.name.strip()
    if not series or series in ('.', '..'):
        return None
    year = int(season_match.group(2)) if season_match.group(2) else None
    year_match = YEAR.search(series)
    if year is None and year_match:
        year = int(year_match.group())
    series = re.sub(r'\s*\((?:19|20)\d{2}\)\s*$', '', series).strip()
    return EpisodeInfo(series, season, episode, year, numbered.group(2).strip())

def mismatched_episode_release(release, info):
    """Reject explicitly conflicting SxxExx/1x02 markers; never guess from unrelated numbers."""
    markers = [(int(a or c), int(b or d)) for a,b,c,d in EXPLICIT.findall(str(release or ''))]
    return bool(markers) and not any(s == info.season and e == info.episode for s,e in markers)
