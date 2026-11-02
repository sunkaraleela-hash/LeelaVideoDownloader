import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const LeelaVideoDownloaderApp());
}

class LeelaVideoDownloaderApp extends StatelessWidget {
  const LeelaVideoDownloaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leela Video Downloader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Leela Video Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _urlController = TextEditingController();

  String _quality = 'Best available';
  String? _outputDirectory;

  bool _isDownloading = false;
  bool _isPreviewing = false;

  double _progress = 0;
  String _status = 'వీడియో URL నమోదు చేయండి';

  Map<String, dynamic>? _videoInfo;

  String get _root => Directory.current.path;
  String get _separator => Platform.pathSeparator;

  String get _ytDlpPath => '$_root${_separator}tools${_separator}yt-dlp.exe';

  String get _ffmpegPath =>
      '$_root${_separator}tools${_separator}ffmpeg${_separator}ffmpeg.exe';

  String get _defaultOutputDirectory => '$_root${_separator}downloads';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);

    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
  }

  Future<void> _chooseFolder() async {
    try {
      final folder = await FilePicker.getDirectoryPath(
        dialogTitle: 'వీడియో సేవ్ చేసే ఫోల్డర్ ఎంచుకోండి',
      );

      if (folder != null && mounted) {
        setState(() {
          _outputDirectory = folder;
          _status = 'సేవ్ చేసే ఫోల్డర్ ఎంపికైంది';
        });
      }
    } catch (e) {
      _showMessage('ఫోల్డర్ ఎంచుకోవడంలో సమస్య: $e');
    }
  }

  // Read video metadata without downloading the video.
  Future<void> _previewVideo() async {
    if (_isDownloading || _isPreviewing) return;

    final url = _urlController.text.trim();

    if (!_isValidUrl(url)) {
      _showMessage('సరైన http లేదా https వీడియో URL నమోదు చేయండి.');
      return;
    }

    final ytDlp = File(_ytDlpPath);

    if (!await ytDlp.exists()) {
      _showMessage('yt-dlp.exe దొరకలేదు: $_ytDlpPath');
      return;
    }

    setState(() {
      _isPreviewing = true;
      _videoInfo = null;
      _status = 'వీడియో వివరాలు సేకరిస్తున్నాం...';
    });

    try {
      final result = await Process.run(
        _ytDlpPath,
        [
          '--dump-single-json',
          '--skip-download',
          '--no-warnings',
          '--no-playlist',
          '--',
          url,
        ],
        runInShell: false,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (!mounted) return;

      if (result.exitCode != 0) {
        final error = result.stderr.toString().trim();
        throw Exception(
          error.isEmpty ? 'వీడియో వివరాలు పొందలేకపోయాం.' : error,
        );
      }

      final decoded = jsonDecode(result.stdout.toString());

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'వీడియో వివరాలు సరైన ఫార్మాట్‌లో లేవు.',
        );
      }

      setState(() {
        _videoInfo = decoded;
        _status = 'వీడియో వివరాలు సిద్ధంగా ఉన్నాయి';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _videoInfo = null;
        _status = 'Preview విఫలమైంది';
      });

      _showMessage('Preview సమస్య: $e');
    } finally {
      if (mounted) {
        setState(() => _isPreviewing = false);
      }
    }
  }

  String _formatDuration(dynamic seconds) {
    final total = seconds is num ? seconds.toInt() : 0;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final secs = total % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildVideoPreview() {
    final info = _videoInfo;
    if (info == null) return const SizedBox.shrink();

    final thumbnail = info['thumbnail']?.toString();
    final title = info['title']?.toString() ?? 'తెలియని వీడియో';
    final uploader = info['uploader']?.toString() ??
        info['channel']?.toString() ??
        'తెలియదు';
    final duration = _formatDuration(info['duration']);
    final width = info['width'] ?? '?';
    final height = info['height'] ?? '?';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (thumbnail != null && thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  thumbnail,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      height: 150,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 45,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _infoRow(Icons.person, 'Uploader', uploader),
            _infoRow(Icons.timer, 'Duration', duration),
            _infoRow(
              Icons.high_quality,
              'Resolution',
              '$width × $height',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 19),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelector() {
    switch (_quality) {
      case '2160p':
        return 'bestvideo[height<=2160]+bestaudio/best[height<=2160]';
      case '1440p':
        return 'bestvideo[height<=1440]+bestaudio/best[height<=1440]';
      case '1080p':
        return 'bestvideo[height<=1080]+bestaudio/best[height<=1080]';
      case '720p':
        return 'bestvideo[height<=720]+bestaudio/best[height<=720]';
      case '480p':
        return 'bestvideo[height<=480]+bestaudio/best[height<=480]';
      default:
        return 'bestvideo+bestaudio/best';
    }
  }

  Future<void> _download() async {
    if (_isDownloading || _isPreviewing) return;

    final url = _urlController.text.trim();

    if (!_isValidUrl(url)) {
      _showMessage('సరైన http లేదా https వీడియో URL నమోదు చేయండి.');
      return;
    }

    final ytDlp = File(_ytDlpPath);
    final ffmpeg = File(_ffmpegPath);

    if (!await ytDlp.exists()) {
      _showMessage('yt-dlp.exe దొరకలేదు: $_ytDlpPath');
      return;
    }

    if (!await ffmpeg.exists()) {
      _showMessage('ffmpeg.exe దొరకలేదు: $_ffmpegPath');
      return;
    }

    final outputDirectory = _outputDirectory ?? _defaultOutputDirectory;

    try {
      await Directory(outputDirectory).create(recursive: true);

      setState(() {
        _isDownloading = true;
        _progress = 0;
        _status = 'డౌన్‌లోడ్ ప్రారంభమవుతోంది...';
      });

      final outputTemplate =
          '$outputDirectory$_separator%(title).200B [%(id)s].%(ext)s';

      final args = <String>[
        '--newline',
        '--no-warnings',
        '--ffmpeg-location',
        _ffmpegPath,
        '--format',
        _formatSelector(),
        '--merge-output-format',
        'mkv',
        '--output',
        outputTemplate,
        '--',
        url,
      ];

      final process = await Process.start(
        _ytDlpPath,
        args,
        runInShell: false,
      );

      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .toList();

      await for (final line in process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final match = RegExp(r'\[download\]\s+([\d.]+)%').firstMatch(line);

        if (match != null) {
          final percent = double.tryParse(match.group(1)!) ?? 0;

          if (mounted) {
            setState(() {
              _progress = (percent / 100).clamp(0.0, 1.0);
              _status = 'డౌన్‌లోడ్ జరుగుతోంది: ${percent.toStringAsFixed(1)}%';
            });
          }
        } else if (line.contains('[Merger]')) {
          if (mounted) {
            setState(() {
              _status = 'వీడియో, ఆడియో కలుపుతోంది...';
            });
          }
        } else if (line.contains('[download] Destination:')) {
          if (mounted) {
            setState(() {
              _status = 'వీడియో ఫైల్ డౌన్‌లోడ్ అవుతోంది...';
            });
          }
        }
      }

      final exitCode = await process.exitCode;
      final stderrLines = await stderrFuture;
      final errorText =
          stderrLines.where((line) => line.trim().isNotEmpty).join('\n');

      if (!mounted) return;

      setState(() {
        if (exitCode == 0) {
          _progress = 1;
          _status = 'డౌన్‌లోడ్ పూర్తయింది!';
        } else {
          _status = 'డౌన్‌లోడ్ విఫలమైంది (Exit code: $exitCode)';
        }
      });

      if (exitCode == 0) {
        _showMessage('వీడియో సేవ్ అయింది: $outputDirectory');
      } else {
        _showMessage(
          errorText.isEmpty
              ? 'డౌన్‌లోడ్ విఫలమైంది. URL లేదా నెట్‌వర్క్‌ను తనిఖీ చేయండి.'
              : errorText.length > 500
                  ? errorText.substring(errorText.length - 500)
                  : errorText,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'లోపం: $e');
      }
      _showMessage('డౌన్‌లోడ్ ప్రారంభించలేకపోయాం: $e');
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = _outputDirectory ?? _defaultOutputDirectory;
    final busy = _isDownloading || _isPreviewing;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.video_library, size: 68),
                const SizedBox(height: 12),
                const Text(
                  'Leela Video Downloader',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _urlController,
                  enabled: !busy,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Video URL',
                    hintText: 'https://example.com/video',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _quality,
                  decoration: const InputDecoration(
                    labelText: 'Video Quality',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Best available',
                      child: Text('Best available quality'),
                    ),
                    DropdownMenuItem(
                      value: '2160p',
                      child: Text('2160p (4K), if available'),
                    ),
                    DropdownMenuItem(
                      value: '1440p',
                      child: Text('1440p (2K), if available'),
                    ),
                    DropdownMenuItem(
                      value: '1080p',
                      child: Text('1080p Full HD'),
                    ),
                    DropdownMenuItem(
                      value: '720p',
                      child: Text('720p HD'),
                    ),
                    DropdownMenuItem(
                      value: '480p',
                      child: Text('480p'),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _quality = value);
                          }
                        },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: busy ? null : _previewVideo,
                  icon: _isPreviewing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.preview),
                  label: Text(
                    _isPreviewing
                        ? 'వివరాలు సేకరిస్తున్నాం...'
                        : 'Preview Video',
                  ),
                ),
                const SizedBox(height: 12),
                _buildVideoPreview(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: busy ? null : _chooseFolder,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('సేవ్ చేసే ఫోల్డర్ ఎంచుకోండి'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Save location: $folder',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : _download,
                  icon: const Icon(Icons.download),
                  label: Text(
                    _isDownloading ? 'Downloading...' : 'Download Video',
                  ),
                ),
                const SizedBox(height: 20),
                if (_isDownloading || _progress > 0) ...[
                  LinearProgressIndicator(
                    value: _isDownloading ? _progress : 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_progress * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'గమనిక: మీరు డౌన్‌లోడ్ చేయడానికి అనుమతి ఉన్న వీడియోలను మాత్రమే ఉపయోగించండి. '
                  'కొన్ని సైట్‌లు లాగిన్, సభ్యత్వం లేదా ఇతర పరిమితుల కారణంగా పనిచేయకపోవచ్చు.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
