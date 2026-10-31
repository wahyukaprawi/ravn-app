import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

const _redText = Color(0xFFC2464A);
const _greenText = Color(0xFF48B48D);
const _redLine = Color(0xFFFF0000);
const _greenLine = Color(0xFF00FF00);
const _muted = Color(0xFF9E9E9E);
const _verificationBackground = Color(0xFF111111);
const _flashPink = Color(0xFFFF3C65);
const _flashBlue = Color(0xFF3C00FF);
const _flashGreen = Color(0xFF3CDC3D);
const _flashYellow = Color(0xFFFFC83C);

class FaceLivenessPage extends StatefulWidget {
  const FaceLivenessPage({super.key});

  @override
  State<FaceLivenessPage> createState() => _FaceLivenessPageState();
}

enum _LivenessPhase { searching, flashing, capturing, verifying, success }

class _FaceLivenessPageState extends State<FaceLivenessPage> {
  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  static const _flashColors = [
    _flashPink,
    _flashBlue,
    _flashGreen,
    _flashYellow,
  ];

  static const _flashDurations = [
    Duration(milliseconds: 300),
    Duration(milliseconds: 400),
    Duration(milliseconds: 300),
    Duration(milliseconds: 300),
  ];

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableClassification: false,
      enableTracking: true,
      enableLandmarks: false,
      enableContours: false,
    ),
  );

  CameraController? _controller;
  CameraDescription? _camera;
  bool _initializing = true;
  bool _processing = false;
  bool _finished = false;
  String? _error;
  _LivenessPhase _phase = _LivenessPhase.searching;
  String _title = 'Pastikan wajah kamu terlihat jelas.';
  Color _titleColor = _redText;
  Color _backgroundColor = Colors.white;
  Color _iconColor = _muted;
  bool _showCamera = true;
  bool _showSilhouette = false;
  bool _showTips = true;
  Rect? _faceBox;
  bool _faceValid = false;
  DateTime? _readySince;
  DateTime _lastFrameAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _flashToken = 0;
  int _countdown = 5;
  String? _capturedPath;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No camera available.');
      }
      final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _camera = front;
      _controller = controller;
      setState(() => _initializing = false);
      await controller.startImageStream(_onImage);
    } catch (error) {
      if (!mounted) return;
      final code = error is CameraException ? error.code : '';
      setState(() {
        _initializing = false;
        _error =
            code == 'CameraAccessDenied' ||
                code == 'CameraAccessDeniedWithoutPrompt' ||
                code == 'CameraAccessRestricted'
            ? 'Izin kamera diperlukan untuk verifikasi wajah.'
            : 'Kamera tidak dapat dibuka. Tutup aplikasi kamera lain lalu coba lagi.';
      });
    }
  }

  Future<void> _retry() async {
    _countdownTimer?.cancel();
    _flashToken++;
    await _deleteFile(_capturedPath);
    _capturedPath = null;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
      await controller.dispose();
    }
    if (!mounted) return;
    setState(() {
      _error = null;
      _initializing = true;
      _finished = false;
      _processing = false;
      _phase = _LivenessPhase.searching;
      _title = 'Pastikan wajah kamu terlihat jelas.';
      _titleColor = _redText;
      _backgroundColor = Colors.white;
      _iconColor = _muted;
      _showCamera = true;
      _showSilhouette = false;
      _showTips = true;
      _faceBox = null;
      _faceValid = false;
      _readySince = null;
      _countdown = 5;
    });
    await _initialize();
  }

  void _onImage(CameraImage image) {
    if (_processing || _finished || _error != null) return;
    if (_phase == _LivenessPhase.capturing ||
        _phase == _LivenessPhase.verifying ||
        _phase == _LivenessPhase.success) {
      return;
    }
    final now = DateTime.now();
    if (now.difference(_lastFrameAt) < const Duration(milliseconds: 200)) {
      return;
    }
    _lastFrameAt = now;
    final inputImage = _inputImage(image);
    if (inputImage == null) return;
    _processing = true;
    unawaited(
      _detector
          .processImage(inputImage)
          .then((faces) {
            if (!mounted || _finished || _error != null) return;
            _handleFaces(faces, image);
          })
          .catchError((Object _) {})
          .whenComplete(() => _processing = false),
    );
  }

  InputImage? _inputImage(CameraImage image) {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else {
      var compensation = _orientations[controller.value.deviceOrientation];
      if (compensation == null) return null;
      compensation = camera.lensDirection == CameraLensDirection.front
          ? (sensorOrientation + compensation) % 360
          : (sensorOrientation - compensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(compensation);
    }
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _handleFaces(List<Face> faces, CameraImage image) {
    if (_phase == _LivenessPhase.capturing ||
        _phase == _LivenessPhase.verifying ||
        _phase == _LivenessPhase.success) {
      return;
    }
    if (faces.length != 1) {
      _readySince = null;
      if (_phase == _LivenessPhase.flashing) {
        _updateFace(null, false);
        return;
      }
      _updateGuidance(
        faces.isEmpty
            ? 'Pastikan wajah kamu terlihat jelas.'
            : 'Pastikan hanya satu wajah terlihat.',
        _redText,
        null,
        false,
      );
      return;
    }

    final face = faces.first;
    final box = face.boundingBox;
    final normalized = Rect.fromLTRB(
      (box.left / image.width).clamp(0.0, 1.0).toDouble(),
      (box.top / image.height).clamp(0.0, 1.0).toDouble(),
      (box.right / image.width).clamp(0.0, 1.0).toDouble(),
      (box.bottom / image.height).clamp(0.0, 1.0).toDouble(),
    );
    final valid = _isFaceValid(face, image);

    if (_phase == _LivenessPhase.flashing) {
      _updateFace(normalized, valid);
      return;
    }

    if (!valid) {
      _readySince = null;
      _updateGuidance(
        'Maju sedikit agar seluruh bagian wajah terlihat.',
        _redText,
        normalized,
        false,
      );
      return;
    }

    _readySince ??= DateTime.now();
    _updateGuidance(
      'Akan ada flash, tahan posisi kamu.',
      _greenText,
      normalized,
      true,
    );
    if (DateTime.now().difference(_readySince!) >=
        const Duration(milliseconds: 700)) {
      _startFlash();
    }
  }

  bool _isFaceValid(Face face, CameraImage image) {
    final box = face.boundingBox;
    final sizeRatio = math.max(
      box.width / image.width,
      box.height / image.height,
    );
    final centerX = box.center.dx / image.width;
    final centerY = box.center.dy / image.height;
    final yaw = (face.headEulerAngleY ?? 0).abs();
    final roll = (face.headEulerAngleZ ?? 0).abs();
    return sizeRatio >= 0.28 &&
        centerX >= 0.24 &&
        centerX <= 0.76 &&
        centerY >= 0.18 &&
        centerY <= 0.82 &&
        yaw <= 18 &&
        roll <= 12;
  }

  void _updateGuidance(String title, Color color, Rect? box, bool valid) {
    if (!mounted) return;
    if (_title == title &&
        _titleColor == color &&
        _faceBox == box &&
        _faceValid == valid) {
      return;
    }
    setState(() {
      _title = title;
      _titleColor = color;
      _faceBox = box;
      _faceValid = valid;
    });
  }

  void _updateFace(Rect? box, bool valid) {
    if (!mounted) return;
    if (_faceBox == box && _faceValid == valid) return;
    setState(() {
      _faceBox = box;
      _faceValid = valid;
    });
  }

  void _startFlash() {
    if (!mounted || _phase != _LivenessPhase.searching) return;
    final token = ++_flashToken;
    setState(() {
      _phase = _LivenessPhase.flashing;
      _title = 'Tahan posisi kamu.';
      _titleColor = Colors.black87;
      _iconColor = Colors.white;
      _readySince = null;
    });
    unawaited(_runFlash(token));
  }

  Future<void> _runFlash(int token) async {
    for (var index = 0; index < _flashColors.length; index++) {
      if (!mounted || token != _flashToken) return;
      setState(() => _backgroundColor = _flashColors[index]);
      await Future<void>.delayed(_flashDurations[index]);
    }
    if (!mounted || token != _flashToken) return;
    setState(() {
      _backgroundColor = Colors.white;
      _title = 'Wajah kamu akan difoto secara otomatis.';
      _titleColor = const Color(0xFFBDBDBD);
      _iconColor = _muted;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || token != _flashToken) return;
    await _capturePhoto();
  }

  Future<void> _capturePhoto() async {
    if (!mounted) return;
    setState(() {
      _phase = _LivenessPhase.capturing;
      _backgroundColor = Colors.white;
      _title = 'Mengambil foto, mohon jangan bergerak.';
      _titleColor = _greenText;
      _iconColor = _muted;
      _showCamera = false;
      _showSilhouette = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || _finished) return;

    final controller = _controller;
    String? path;
    try {
      if (controller == null) {
        throw StateError('Camera is not ready.');
      }
      try {
        await controller.stopImageStream();
      } catch (_) {}
      final file = await controller.takePicture();
      path = file.path;
      final faceCount = await _countFacesInFile(path);
      if (faceCount != 1) {
        await _deleteFile(path);
        await _restartAfterFailure('Wajah tidak terdeteksi. Coba lagi.');
        return;
      }
    } catch (_) {
      await _deleteFile(path);
      await _restartAfterFailure('Foto wajah tidak dapat diambil. Coba lagi.');
      return;
    }

    if (!mounted) {
      await _deleteFile(path);
      return;
    }

    setState(() {
      _capturedPath = path;
      _backgroundColor = const Color(0xFFE0E0E0);
      _titleColor = Colors.transparent;
      _showSilhouette = true;
      _showTips = false;
      _countdown = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _phase = _LivenessPhase.verifying;
      _backgroundColor = _verificationBackground;
      _title = 'Sedang memverifikasi wajah, tolong tunggu sebentar.';
      _titleColor = Colors.white;
      _iconColor = Colors.white70;
      _showSilhouette = false;
      _countdown = 5;
    });
    _startCountdown();
  }

  Future<int> _countFacesInFile(String path) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: false,
        enableTracking: false,
      ),
    );
    try {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      return faces.length;
    } catch (_) {
      return 1;
    } finally {
      await detector.close();
    }
  }

  Future<void> _restartAfterFailure(String message) async {
    final controller = _controller;
    var restarted = false;
    if (controller != null) {
      try {
        await controller.startImageStream(_onImage);
        restarted = true;
      } catch (_) {}
    }
    if (!mounted) return;
    if (!restarted) {
      setState(() {
        _error = 'Kamera tidak dapat dimulai ulang. Coba lagi.';
        _initializing = false;
      });
      return;
    }
    setState(() {
      _phase = _LivenessPhase.searching;
      _backgroundColor = Colors.white;
      _title = message;
      _titleColor = _redText;
      _iconColor = _muted;
      _showCamera = true;
      _showSilhouette = false;
      _showTips = true;
      _faceBox = null;
      _faceValid = false;
      _readySince = null;
      _countdown = 5;
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        _finishSuccess();
        return;
      }
      setState(() => _countdown--);
    });
  }

  void _finishSuccess() {
    if (!mounted || _finished) return;
    _finished = true;
    setState(() {
      _phase = _LivenessPhase.success;
      _title = 'Wajah berhasil diverifikasi.';
      _titleColor = Colors.white;
      _iconColor = Colors.white70;
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  void _cancel() {
    _finished = true;
    _flashToken++;
    _countdownTimer?.cancel();
    Navigator.of(context).pop(false);
  }

  Future<void> _deleteFile(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _flashToken++;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    unawaited(_detector.close());
    final path = _capturedPath;
    _capturedPath = null;
    if (path != null) {
      unawaited(_deleteFile(path));
    }
    super.dispose();
  }

  SystemUiOverlayStyle get _systemUiStyle {
    final dark =
        _phase == _LivenessPhase.flashing ||
        _phase == _LivenessPhase.verifying ||
        _phase == _LivenessPhase.success;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final screen = MediaQuery.sizeOf(context);
    final circleSize = math.min(screen.width * 0.66, 290.0);
    final verificationSize = math.min(screen.width * 0.60, 270.0);
    final verifying =
        _phase == _LivenessPhase.verifying || _phase == _LivenessPhase.success;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _systemUiStyle,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: AnimatedContainer(
          duration: _phase == _LivenessPhase.flashing
              ? Duration.zero
              : const Duration(milliseconds: 250),
          color: _backgroundColor,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topBar(),
                    if (verifying)
                      Expanded(
                        child: Center(
                          child: Transform.translate(
                            offset: const Offset(0, -48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _titleText(verifying: true),
                                const SizedBox(height: 48),
                                _verificationCircle(verificationSize),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            _titleText(verifying: false),
                            const SizedBox(height: 36),
                            _captureCircle(circleSize, controller),
                            const Spacer(),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_initializing)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (_error != null) Positioned.fill(child: _errorView()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final showTips =
        _showTips &&
        _phase != _LivenessPhase.verifying &&
        _phase != _LivenessPhase.success;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancel,
            icon: Icon(Icons.chevron_left, size: 32, color: _iconColor),
            tooltip: 'Kembali',
          ),
          const Spacer(),
          if (showTips)
            TextButton.icon(
              onPressed: _showTipsSheet,
              icon: Icon(Icons.lightbulb_outline, size: 18, color: _iconColor),
              label: Text(
                'Tips',
                style: TextStyle(color: _iconColor, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titleText({required bool verifying}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: TextStyle(
          color: _titleColor,
          fontSize: verifying ? 16 : 20,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        child: Text(_title, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _captureCircle(double size, CameraController? controller) {
    final showCamera =
        _showCamera && controller != null && controller.value.isInitialized;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _showSilhouette ? const Color(0xFFE0E0E0) : Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showCamera)
              _cameraPreview(controller)
            else if (_showSilhouette)
              const ColoredBox(color: Color(0xFFE0E0E0))
            else
              const ColoredBox(color: Color(0xFFF4F4F4)),
            CustomPaint(
              painter: _FaceGuidePainter(
                faceBox: _faceBox,
                valid: _faceValid,
                silhouette: _showSilhouette,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraPreview(CameraController controller) {
    final preview = controller.value.previewSize;
    if (preview == null) {
      return const ColoredBox(color: Color(0xFFF4F4F4));
    }
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: preview.height,
        height: preview.width,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _verificationCircle(double size) {
    final path = _capturedPath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0E0E0),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (path != null)
              Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFFE0E0E0)),
              )
            else
              CustomPaint(
                painter: _FaceGuidePainter(
                  faceBox: null,
                  valid: true,
                  silhouette: true,
                ),
              ),
            if (_phase == _LivenessPhase.verifying && _countdown > 0)
              Center(
                child: Container(
                  width: size * 0.42,
                  height: size * 0.42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFC9D6).withValues(alpha: 0.92),
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            if (_phase == _LivenessPhase.success)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF00E676),
                    size: 72,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 56,
                color: _muted,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Kamera tidak tersedia.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _retry, child: const Text('Coba lagi')),
              TextButton(onPressed: _cancel, child: const Text('Kembali')),
            ],
          ),
        ),
      ),
    );
  }

  void _showTipsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tips verifikasi wajah',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              _tipRow(Icons.light_mode_outlined, 'Pastikan pencahayaan cukup.'),
              _tipRow(
                Icons.face_retouching_natural,
                'Pastikan seluruh wajah terlihat jelas.',
              ),
              _tipRow(
                Icons.remove_red_eye_outlined,
                'Lepas masker atau penutup wajah.',
              ),
              _tipRow(Icons.phone_iphone, 'Tahan ponsel dan jangan bergerak.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _greenText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final Rect? faceBox;
  final bool valid;
  final bool silhouette;

  const _FaceGuidePainter({
    required this.faceBox,
    required this.valid,
    required this.silhouette,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (silhouette) {
      final head = _headPath(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.04,
          size.width * 0.76,
          size.height * 0.92,
        ),
      );
      canvas.drawPath(head, Paint()..color = Colors.black);
      canvas.drawPath(
        head,
        Paint()
          ..color = _greenLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else if (faceBox != null) {
      final rect = Rect.fromLTWH(
        faceBox!.left * size.width,
        faceBox!.top * size.height,
        faceBox!.width * size.width,
        faceBox!.height * size.height,
      );
      final side = math.max(rect.width, rect.height);
      final expanded = Rect.fromCenter(
        center: rect.center,
        width: side * 0.92,
        height: side * 1.12,
      );
      final contour = _headPath(expanded);
      canvas.drawPath(
        contour,
        Paint()
          ..color = valid ? _greenLine : _redLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    final guide = _guidePath(
      Rect.fromLTRB(
        size.width * 0.22,
        size.height * 0.14,
        size.width * 0.78,
        size.height * 0.88,
      ),
    );
    _drawDashedPath(
      canvas,
      guide,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _headPath(Rect rect) {
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;
    return Path()
      ..moveTo(left + width * 0.50, top + height * 0.02)
      ..cubicTo(
        left + width * 0.72,
        top + height * 0.02,
        left + width * 0.89,
        top + height * 0.14,
        left + width * 0.92,
        top + height * 0.34,
      )
      ..cubicTo(
        left + width * 0.95,
        top + height * 0.50,
        left + width * 0.93,
        top + height * 0.64,
        left + width * 0.86,
        top + height * 0.75,
      )
      ..cubicTo(
        left + width * 0.80,
        top + height * 0.84,
        left + width * 0.70,
        top + height * 0.93,
        left + width * 0.58,
        top + height * 0.97,
      )
      ..cubicTo(
        left + width * 0.54,
        top + height * 0.985,
        left + width * 0.46,
        top + height * 0.985,
        left + width * 0.42,
        top + height * 0.97,
      )
      ..cubicTo(
        left + width * 0.30,
        top + height * 0.93,
        left + width * 0.20,
        top + height * 0.84,
        left + width * 0.14,
        top + height * 0.75,
      )
      ..cubicTo(
        left + width * 0.07,
        top + height * 0.64,
        left + width * 0.05,
        top + height * 0.50,
        left + width * 0.08,
        top + height * 0.34,
      )
      ..cubicTo(
        left + width * 0.11,
        top + height * 0.14,
        left + width * 0.28,
        top + height * 0.02,
        left + width * 0.50,
        top + height * 0.02,
      )
      ..close();
  }

  Path _guidePath(Rect rect) {
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;
    return Path()
      ..moveTo(left + width * 0.50, top + height * 0.02)
      ..cubicTo(
        left + width * 0.72,
        top + height * 0.02,
        left + width * 0.88,
        top + height * 0.18,
        left + width * 0.90,
        top + height * 0.40,
      )
      ..cubicTo(
        left + width * 0.92,
        top + height * 0.62,
        left + width * 0.80,
        top + height * 0.82,
        left + width * 0.64,
        top + height * 0.92,
      )
      ..cubicTo(
        left + width * 0.58,
        top + height * 0.96,
        left + width * 0.54,
        top + height * 0.97,
        left + width * 0.50,
        top + height * 0.97,
      )
      ..cubicTo(
        left + width * 0.46,
        top + height * 0.97,
        left + width * 0.42,
        top + height * 0.96,
        left + width * 0.36,
        top + height * 0.92,
      )
      ..cubicTo(
        left + width * 0.20,
        top + height * 0.82,
        left + width * 0.08,
        top + height * 0.62,
        left + width * 0.10,
        top + height * 0.40,
      )
      ..cubicTo(
        left + width * 0.12,
        top + height * 0.18,
        left + width * 0.28,
        top + height * 0.02,
        left + width * 0.50,
        top + height * 0.02,
      )
      ..close();
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 10.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + 7.0;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.faceBox != faceBox ||
        oldDelegate.valid != valid ||
        oldDelegate.silhouette != silhouette;
  }
}
