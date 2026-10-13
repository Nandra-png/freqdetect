import 'package:flutter/material.dart';

class SpectrumPainter extends CustomPainter {
  SpectrumPainter(this.data, {required this.maxHz});

  final List<double> data;
  final double maxHz;

  @override
  void paint(Canvas canvas, Size size) {
    final garis = Paint()
      ..color = const Color(0xFF1E88E5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final grid = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;

    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (data.isEmpty) return;

    final path = Path();
    const bawah = -60.0;
    final lebar = size.width / data.length;

    for (var i = 0; i < data.length; i++) {
      final v = data[i].clamp(bawah, 0);
      final t = (v - bawah) / -bawah;
      final y = size.height * (1 - t);
      final x = i * lebar;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, garis);

    final sumbu = TextPainter(
      text: TextSpan(
        text: '0 Hz',
        style: const TextStyle(fontSize: 10, color: Colors.black45),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    sumbu.paint(canvas, Offset(2, size.height - 14));

    final kanan = TextPainter(
      text: TextSpan(
        text: '${(maxHz / 1000).toStringAsFixed(1)} kHz',
        style: const TextStyle(fontSize: 10, color: Colors.black45),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    kanan.paint(canvas, Offset(size.width - kanan.width - 2, size.height - 14));
  }

  @override
  bool shouldRepaint(SpectrumPainter old) => old.data != data;
}
