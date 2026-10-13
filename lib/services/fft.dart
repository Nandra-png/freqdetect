import 'dart:math' as math;

class FFT {
  FFT(this.size);

  final int size;

  final _real = <double>[];
  final _imag = <double>[];
  final _cos = <double>[];
  final _sin = <double>[];
  int _bit = 0;

  List<double> hitung(List<double> input) {
    if (_real.isEmpty) _siapkan();

    for (var i = 0; i < size; i++) {
      _real[i] = i < input.length ? _hann(i, input.length) * input[i] : 0;
      _imag[i] = 0;
    }

    _bitReverse();
    _transform();

    final out = List<double>.filled(size ~/ 2, 0);
    for (var i = 0; i < out.length; i++) {
      final m = math.sqrt(_real[i] * _real[i] + _imag[i] * _imag[i]);
      out[i] = 20 * (math.log(m + 1e-9) / math.ln10);
    }
    return _normalisasi(out);
  }

  double _hann(int i, int n) {
    return 0.5 * (1 - math.cos(2 * math.pi * i / (n - 1)));
  }

  void _siapkan() {
    var b = 0;
    while ((1 << b) < size) {
      b++;
    }
    _bit = b;

    for (var i = 0; i < size; i++) {
      _real.add(0);
      _imag.add(0);
      _cos.add(math.cos(2 * math.pi * i / size));
      _sin.add(math.sin(2 * math.pi * i / size));
    }
  }

  void _bitReverse() {
    for (var i = 0; i < size; i++) {
      final j = _balik(i);
      if (j > i) {
        var t = _real[i];
        _real[i] = _real[j];
        _real[j] = t;
        t = _imag[i];
        _imag[i] = _imag[j];
        _imag[j] = t;
      }
    }
  }

  int _balik(int x) {
    var r = 0;
    for (var i = 0; i < _bit; i++) {
      r = (r << 1) | (x & 1);
      x >>= 1;
    }
    return r;
  }

  void _transform() {
    for (var len = 2; len <= size; len <<= 1) {
      final step = size ~/ len;
      final half = len ~/ 2;
      for (var i = 0; i < size; i += len) {
        for (var j = 0; j < half; j++) {
          final k = j * step;
          final wr = _cos[k];
          final wi = -_sin[k];
          final a = i + j;
          final b = a + half;
          final tr = wr * _real[b] - wi * _imag[b];
          final ti = wr * _imag[b] + wi * _real[b];
          _real[b] = _real[a] - tr;
          _imag[b] = _imag[a] - ti;
          _real[a] += tr;
          _imag[a] += ti;
        }
      }
    }
  }

  List<double> _normalisasi(List<double> v) {
    var maks = 0.0;
    for (final x in v) {
      if (x > maks) maks = x;
    }
    if (maks <= 0) return v;
    return v.map((x) => x - maks).toList();
  }

  double cariPuncak(List<double> magnitudo, int sampleRate) {
    var bin = 0;
    var nilai = -1e9;

    for (var i = 2; i < magnitudo.length; i++) {
      if (magnitudo[i] > nilai) {
        nilai = magnitudo[i];
        bin = i;
      }
    }

    if (nilai < -60) return 0;

    final kiri = bin > 0 ? magnitudo[bin - 1] : magnitudo[bin];
    final kanan = bin < magnitudo.length - 1 ? magnitudo[bin + 1] : magnitudo[bin];
    final denom = 2 * magnitudo[bin] - kiri - kanan;
    final delta = denom.abs() < 1e-9 ? 0.0 : 0.5 * (kanan - kiri) / denom;

    final binHalus = bin + delta.clamp(-0.5, 0.5);
    return binHalus * sampleRate / size;
  }
}
