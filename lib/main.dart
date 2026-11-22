import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'subtitle_service.dart';
import 'video_info.dart';

void main() => runApp(const OmegaSubApp());

class OmegaSubApp extends StatelessWidget {
  const OmegaSubApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OmegaSub — Legendas PT-BR',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xff171b25),
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xffdc2f40), brightness: Brightness.dark),
          useMaterial3: true,
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff455f91),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18))),
        ),
        home: const OmegaHome(),
      );
}

class OmegaHome extends StatefulWidget {
  const OmegaHome({super.key});
  @override
  State<OmegaHome> createState() => _OmegaHomeState();
}

class _OmegaHomeState extends State<OmegaHome> {
  VideoInfo? video;
  List<SubtitleEntry> results = [];
  SubtitleEntry? selected;
  bool busy = false;
  bool pickingVideo = false;
  String? alternateTitle;
  int _searchSequence = 0;
  bool automatic = true;
  String status = 'Selecione um vídeo para começar.';
  final queryController = TextEditingController();
  final alternateController = TextEditingController();

  @override
  void dispose() {
    queryController.dispose();
    alternateController.dispose();
    super.dispose();
  }

  Future<void> pickVideo() async {
    if (busy || pickingVideo) return;
    setState(() {
      pickingVideo = true;
      status = 'Abrindo seletor de vídeos... Aguarde.';
    });
    try {
      // Permite desenhar o indicador antes de abrir o seletor nativo.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'webm', 'm4v', 'wmv']);
      if (picked == null || picked.files.isEmpty) {
        if (mounted) setState(() => status = 'Seleção cancelada.');
        return;
      }
      if (mounted) setState(() => status = 'Identificando o vídeo selecionado...');
      final parsed = VideoInfo.parse(picked.files.single.name);
      if (!mounted) return;
      setState(() {
        video = parsed;
        alternateTitle = null;
        alternateController.clear();
        results = [];
        selected = null;
        queryController.text = parsed.title;
        status = 'Vídeo selecionado: ${parsed.fileName}';
      });
      if (mounted) setState(() => pickingVideo = false);
      if (automatic) await search();
    } catch (e) {
      if (mounted) setState(() => status = 'Erro ao selecionar vídeo: $e');
    } finally {
      if (mounted) setState(() => pickingVideo = false);
    }
  }

  Future<void> search() async {
    final v = video;
    if (v == null) {
      setState(() => status = 'Selecione um vídeo primeiro.');
      return;
    }
    final q = automatic ? v.title : queryController.text.trim();
    final target = q.isEmpty ? v : VideoInfo(v.fileName, q, v.year, v.season, v.episode);
    final searchId = ++_searchSequence;
    setState(() {
      busy = true;
      results = [];
      selected = null;
      status = 'Procurando legendas PT-BR...';
    });
    try {
      final list = await SubtitleService.search(target,
          alternateTitle: alternateTitle,
          onProgress: (message) {
            if (mounted && searchId == _searchSequence) {
              setState(() => status = message);
            }
          });
      if (!mounted) return;
      setState(() {
        results = list;
        selected = list.isEmpty ? null : list.first;
        status = list.isEmpty
            ? 'A fonte respondeu, mas não foram encontradas legendas PT-BR prontas para esse título. Tente informar o título original no modo manual.'
            : '${list.length} legenda(s) encontrada(s).';
      });
    } catch (e) {
      if (mounted) {
        setState(() => status =
            'Busca indisponível: ${e.toString().replaceFirst('Bad state: ', '')}');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> download() async {
    final item = selected;
    if (item == null || video == null) return;
    setState(() {
      busy = true;
      status = 'Baixando legenda...';
    });
    try {
      final Uint8List bytes = await SubtitleService.download(item);
      final filename = '${video!.fileName.replaceFirst(RegExp(r'\.[^.]+$'), '')}.srt';
      final path = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(data: bytes, fileName: filename));
      if (mounted) {
        setState(() => status = path == null
            ? 'Salvamento cancelado.'
            : 'Legenda salva com sucesso!');
      }
    } catch (e) {
      if (mounted) setState(() => status = 'Falha no download: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('OmegaSub'),
            backgroundColor: const Color(0xff171b25)),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Center(
                  child: Image.asset('assets/images/omegasub.png',
                      height: 112, width: 112)),
              const SizedBox(height: 12),
              const Center(
                  child: Text('OmegaSub · Legendas PT-BR',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))),
              const SizedBox(height: 5),
              const Center(
                  child: Text('Android · Simples, rápido e sem cadastro',
                      style: TextStyle(color: Colors.white70))),
              const SizedBox(height: 24),
              FilledButton.icon(
                  onPressed: busy || pickingVideo ? null : pickVideo,
                  icon: const Icon(Icons.video_file),
                  label: const Text('Selecionar vídeo')),
              if (pickingVideo) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
                const SizedBox(height: 5),
                const Text('Carregando seletor de vídeos... Aguarde.',
                    style: TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 12),
              Text(video == null
                  ? 'Nenhum vídeo selecionado'
                  : 'Selecionado: ${video!.fileName}', maxLines: 3),
              if (video != null) ...[
                const SizedBox(height: 12),
                Text(
                    'Identificado: ${video!.title}${video!.year == null ? '' : ' (${video!.year})'}${video!.isEpisode ? ' · S${video!.season}E${video!.episode}' : ''}',
                    style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 20),
              const Text('Modo:',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(automatic ? 'Automático (padrão)' : 'Manual'),
                subtitle: Text(automatic
                    ? 'A busca inicia ao selecionar o vídeo.'
                    : 'Digite ou corrija o título antes de buscar.'),
                value: automatic,
                onChanged: busy || pickingVideo ? null : (value) => setState(() => automatic = value),
              ),
              if (!automatic) ...[
                const SizedBox(height: 10),
                TextField(
                    controller: queryController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) { if (!busy) search(); },
                    decoration: const InputDecoration(
                        labelText: 'Título para pesquisa',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search))),
                const SizedBox(height: 10),
                TextField(
                  controller: alternateController,
                  onChanged: (value) => alternateTitle = value.trim().isEmpty ? null : value.trim(),
                  decoration: const InputDecoration(
                    labelText: 'Título original / alternativo (opcional)',
                    hintText: 'Ex.: The Odyssey',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.translate),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                  onPressed: busy || pickingVideo ? null : search,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar legendas PT-BR')),
              const SizedBox(height: 14),
              if (busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(status, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 22),
              const Text('Resultados',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final item in results)
                Card(
                  child: RadioListTile<SubtitleEntry>(
                    value: item,
                    groupValue: selected,
                    onChanged: busy ? null : (value) => setState(() => selected = value),
                    title: Text(item.release),
                    subtitle: Text(
                        '${item.provider} · PT-BR · compatibilidade ${item.score}'),
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                  onPressed: busy || selected == null ? null : download,
                  icon: const Icon(Icons.download),
                  label: const Text('Baixar legenda selecionada')),
              const SizedBox(height: 18),
              const Text(
                  'Fonte experimental: SubtitleCat. Somente legendas PT-BR já disponíveis. A busca depende da disponibilidade do site.',
                  style: TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
      );
}
