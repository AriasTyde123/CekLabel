import 'dart:math' as math;

import 'package:flutter/material.dart';

const _mint = Color(0xFF10B981);
const _white = Color(0xFFF3FCF7);
const _glass = Color(0xDB13251F);
const _outline = Color(0x47E2F8EC);

class ScannerView extends StatelessWidget {
  const ScannerView({
    super.key,
    required this.barcode,
    required this.flash,
    required this.busy,
    required this.hasProfile,
    required this.hint,
    required this.onClose,
    required this.onMode,
    required this.onFlash,
    required this.onHelp,
    required this.onGallery,
    required this.onCapture,
    required this.onProfiles,
    required this.onRetry,
    this.error,
  });

  final bool barcode;
  final bool flash;
  final bool busy;
  final bool hasProfile;
  final String hint;
  final String? error;
  final VoidCallback onClose;
  final ValueChanged<bool> onMode;
  final VoidCallback onFlash;
  final VoidCallback onHelp;
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onProfiles;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = math.max(500.0, constraints.maxHeight);
        final compact = height < 650;
        final width = constraints.maxWidth;
        final frame = Rect.fromCenter(
          center: Offset(width / 2, height * (barcode ? .62 : .515)),
          width: math.min(width * .81, 370.0),
          height: math.min(height * (barcode ? .21 : compact ? .38 : .42), barcode ? 165.0 : 350.0),
        );
        return SingleChildScrollView(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    1, 0, 0, 0, flash ? 22.0 : -5.0,
                    0, 1, 0, 0, flash ? 22.0 : -5.0,
                    0, 0, 1, 0, flash ? 22.0 : -5.0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.asset(
                    'assets/scanner/label-viewfinder.webp',
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xF506120F), Color(0x9C06120F), Color(0x0006120F),
                        Color(0x0006120F), Color(0x7D06120F), Color(0xFB06120F),
                      ],
                      stops: [0, .18, .37, .63, .8, 1],
                    ),
                  ),
                ),
                IgnorePointer(child: CustomPaint(painter: _ViewfinderPainter(frame))),
                if (height >= 570)
                  Positioned(
                    left: frame.left,
                    bottom: height - frame.top + 9,
                    child: _FrameCaption(barcode ? 'PRATINJAU MODE' : 'AREA PINDAI'),
                  ),
                Positioned(
                  top: frame.bottom + (compact ? 9 : 15),
                  left: 22,
                  right: 22,
                  child: Center(
                    child: Semantics(
                      liveRegion: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xE8081713),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _outline),
                        ),
                        child: Text(
                          hint,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _white, fontSize: compact ? 11 : 12, height: 1.45, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (error != null)
                  Positioned.fromRect(
                    rect: frame.deflate(9),
                    child: Center(
                      child: Material(
                        color: const Color(0xFA112B22),
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9FF0C9)),
                              const SizedBox(height: 6),
                              Text(
                                error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              TextButton(
                                onPressed: onRetry,
                                style: TextButton.styleFrom(foregroundColor: const Color(0xFF9FF0C9)),
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(width < 360 ? 14 : 22, compact ? 10 : 18, width < 360 ? 14 : 22, 0),
                      child: Column(
                        children: [
                          _ScannerTop(
                            flash: flash,
                            onClose: onClose,
                            onFlash: busy ? null : onFlash,
                            onHelp: busy ? null : onHelp,
                          ),
                          SizedBox(height: compact ? 12 : 23),
                          _ModeSwitch(barcode: barcode, onSelected: busy ? null : onMode),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(width < 360 ? 14 : 22, 0, width < 360 ? 14 : 22, compact ? 13 : 23),
                      child: _ActionBar(
                        busy: busy,
                        hasProfile: hasProfile,
                        onGallery: busy ? null : onGallery,
                        onCapture: busy ? null : onCapture,
                        onProfiles: busy ? null : onProfiles,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScannerTop extends StatelessWidget {
  const _ScannerTop({required this.flash, required this.onClose, required this.onFlash, required this.onHelp});

  final bool flash;
  final VoidCallback onClose;
  final VoidCallback? onFlash;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _RoundIcon(icon: Icons.close_rounded, label: 'Tutup pemindai', onPressed: onClose),
          ),
        ),
        const Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 6, color: Color(0xFF62E5AD)),
              SizedBox(width: 5),
              Flexible(
                child: Text(
                  'SIMULASI KAMERA',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Semantics(
                toggled: flash,
                child: _RoundIcon(
                  icon: flash ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  label: 'Lampu kilat simulasi',
                  active: flash,
                  onPressed: onFlash,
                ),
              ),
              const SizedBox(width: 4),
              _RoundIcon(icon: Icons.help_outline_rounded, label: 'Bantuan', onPressed: onHelp),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.label, required this.onPressed, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 21),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(42),
        minimumSize: const Size.square(42),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: active ? const Color(0xFF145E46) : _glass,
        disabledBackgroundColor: _glass,
        foregroundColor: active ? const Color(0xFFA4FFD0) : _white,
        disabledForegroundColor: const Color(0xFFC0DBCC),
        side: const BorderSide(color: _outline),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.barcode, required this.onSelected});

  final bool barcode;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 350),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xEA0B1D17),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _outline),
          boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            Expanded(flex: 135, child: _option(false, Icons.document_scanner_outlined, 'Scan Komposisi (AI)')),
            const SizedBox(width: 4),
            Expanded(flex: 100, child: _option(true, Icons.qr_code_scanner_rounded, 'Scan Barcode')),
          ],
        ),
      ),
    );
  }

  Widget _option(bool value, IconData icon, String label) {
    final selected = barcode == value;
    return Semantics(
      selected: selected,
      child: FilledButton(
        onPressed: onSelected == null ? null : () => onSelected!(value),
        style: FilledButton.styleFrom(
          backgroundColor: selected ? _mint : Colors.transparent,
          disabledBackgroundColor: selected ? _mint : Colors.transparent,
          foregroundColor: selected ? const Color(0xFF042C20) : const Color(0xFFCEE1D8),
          disabledForegroundColor: selected ? const Color(0xFF042C20) : const Color(0xFFCEE1D8),
          minimumSize: const Size(0, 43),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, height: 1.25, fontWeight: selected ? FontWeight.w800 : FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrameCaption extends StatelessWidget {
  const _FrameCaption(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xEC102A20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x47AFF9CF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.center_focus_weak_rounded, size: 13, color: Color(0xFFB4F4D2)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFB4F4D2), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.busy, required this.hasProfile, required this.onGallery, required this.onCapture, required this.onProfiles,
  });

  final bool busy;
  final bool hasProfile;
  final VoidCallback? onGallery;
  final VoidCallback? onCapture;
  final VoidCallback? onProfiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onGallery,
              style: TextButton.styleFrom(
                foregroundColor: _white,
                disabledForegroundColor: const Color(0xFFC0DBCC),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: _glass,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: _outline),
                    ),
                    child: const Icon(Icons.photo_library_outlined, size: 21),
                  ),
                  const SizedBox(height: 6),
                  const Text('Galeri', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        SizedBox.square(
          dimension: 76,
          child: IconButton.outlined(
            tooltip: 'Ambil foto',
            onPressed: onCapture,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x15FFFFFF),
              disabledBackgroundColor: const Color(0x15FFFFFF),
              side: const BorderSide(color: _white, width: 2),
            ),
            icon: CircleAvatar(
              radius: 30,
              backgroundColor: _white,
              child: busy
                  ? const SizedBox.square(
                      dimension: 25,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF03744D)),
                    )
                  : const Icon(Icons.photo_camera_outlined, color: Color(0xFF163B2E), size: 27),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onProfiles,
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xEA102D22),
                  disabledBackgroundColor: const Color(0xEA102D22),
                  foregroundColor: _white,
                  minimumSize: const Size(0, 49),
                  padding: const EdgeInsets.fromLTRB(6, 5, 9, 5),
                  side: const BorderSide(color: Color(0x548BE8B9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF24543F),
                      child: Icon(Icons.group_outlined, size: 17, color: Color(0xFF97F3C3)),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mengecek', style: TextStyle(color: Color(0xFFC0DBCC), fontSize: 9, fontWeight: FontWeight.w600)),
                          Text(
                            hasProfile ? '1 Profil' : '2 Profil',
                            semanticsLabel: hasProfile ? null : '2 profil contoh',
                            style: const TextStyle(color: _white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(23);
    final rounded = RRect.fromRectAndRadius(frame, radius);
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rounded);
    canvas.drawPath(shade, Paint()..color = const Color(0x65020E0A));
    canvas.drawRRect(
      rounded,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x8CF6FFF8),
    );

    final corner = Path()
      ..moveTo(0, 34)
      ..lineTo(0, 23)
      ..arcToPoint(const Offset(23, 0), radius: radius)
      ..lineTo(34, 0);
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _white;
    for (final (point, x, y) in [
      (frame.topLeft, 1.0, 1.0),
      (frame.topRight, -1.0, 1.0),
      (frame.bottomLeft, 1.0, -1.0),
      (frame.bottomRight, -1.0, -1.0),
    ]) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.scale(x, y);
      canvas.drawPath(corner, bracket);
      canvas.restore();
    }

    final y = frame.top + frame.height * .52;
    final beam = Rect.fromLTRB(frame.left, y - 1, frame.right, y + 1);
    canvas.drawRect(
      beam,
      Paint()..shader = const LinearGradient(
        colors: [Color(0x006DFCC8), Color(0xDD91FFD8), Color(0x006DFCC8)],
      ).createShader(beam),
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) => oldDelegate.frame != frame;
}
