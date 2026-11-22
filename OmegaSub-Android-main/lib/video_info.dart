class VideoInfo {
  final String fileName;
  final String title;
  final int? year;
  final int? season;
  final int? episode;
  const VideoInfo(this.fileName, this.title, this.year, this.season, this.episode);
  bool get isEpisode => season != null && episode != null;

  static VideoInfo parse(String filename) {
    final stem = filename.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final ep = RegExp(r'\bS(\d{1,2})[ ._-]*E(\d{1,3})\b|\b(\d{1,2})x(\d{1,3})\b', caseSensitive: false).firstMatch(stem);
    final yearMatch = RegExp(r'(?<!\d)(?:19|20)\d{2}(?!\d)').firstMatch(stem);
    final year = yearMatch == null ? null : int.tryParse(yearMatch.group(0)!);
    final stop = ep?.start ?? yearMatch?.start ?? stem.length;
    var title = stem.substring(0, stop)
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .replaceAll(RegExp(r'[\[\](){}]+$'), '')
        .replaceAll(RegExp(r'^[\[\](){}]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (title.isEmpty) title = stem.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    return VideoInfo(filename, title, year,
        ep == null ? null : int.parse((ep.group(1) ?? ep.group(3))!),
        ep == null ? null : int.parse((ep.group(2) ?? ep.group(4))!));
  }
}
