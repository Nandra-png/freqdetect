import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/fft.dart';
import '../widgets/spectrum_painter.dart';

class DetectorScreen extends StatefulWidget {
  const DetectorScreen({super.key});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> {
  final _recorder = AudioRecorder();
  final _fft = FFT(1024);

  StreamSubscription? _sub;
  List<double> _spektrum = List.filled(512, 0);
  double _puncak = 0;
  String _catatan = '-';
  bool _jalan = false;

  static const int _sampleRate = 44100;

  @override
  void dispose() {
    _sub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _mulai() async {
    final izin = await Permission.microphone.request();
    if (!izin.isGranted) {
      setState(() => _catatan = 'izin mikrofon ditolak');
      return;
    }

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: _sampleRate,
      numChannels: 1,
    ));

    setState(() => _jalan = true);

    _sub = stream.listen((data) {
      final sampel = _keDouble(data);
      if (sampel.length < _fft.size) return;

      final magnitudo = _fft.hitung(sampel.sublist(0, _fft.size));
      final hz = _fft.cariPuncak(magnitudo, _sampleRate);

      if (!mounted) return;
      setState(() {
        _spektrum = magnitudo;
        _puncak = hz;
        _catatan = _namanada(hz);
      });
    });
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _jalan = false;
      _spektrum = List.filled(512, 0);
      _puncak = 0;
      _catatan = '-';
    });
  }

  List<double> _keDouble(List<int> byte) {
    final n = byte.length ~/ 2;
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      var v = byte[i * 2] | (byte[i * 2 + 1] << 8);
      if (v >= 32768) v -= 65536;
      out[i] = v / 32768.0;
    }
    return out;
  }

  String _namanada(double hz) {
    if (hz <= 0) return '-';
    const nama = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final midi = 69 + 12 * (math.log(hz / 440) / math.ln2);
    final bulat = midi.round();
    final oktaf = (bulat ~/ 12) - 1;
    return '${nama[bulat % 12]}$oktaf';
  }

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('Deteksi Frekuensi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Text(
                    _puncak > 0 ? '${_puncak.round()} Hz' : '-- Hz',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _catatan,
                    style: TextStyle(
                      fontSize: 22,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                height: 180,
                width: lebar,
                child: CustomPaint(
                  painter: SpectrumPainter(_spektrum, maxHz: _sampleRate / 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _jalan ? _stop : _mulai,
            icon: Icon(_jalan ? Icons.stop : Icons.mic),
            label: Text(_jalan ? 'Stop' : 'Mulai dengar'),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Catatan: puncak frekuensi diambil dari bin FFT paling kuat. '
                'Kalau suaranya berisik, hasilnya bisa lompat-lompat.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
