import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/uvc_camera_service.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';

class MicroscopioController extends ChangeNotifier {
  final UvcCameraService _service = UvcCameraService();

  UvcStatus _status = UvcStatus.disconnected;
  String? _lastError;
  StreamSubscription<UvcStatus>? _statusSub;

  UvcStatus get status => _status;
  bool get estaConectado => _status == UvcStatus.connected;
  bool get estaCarregando => _status == UvcStatus.connecting;
  int? get textureId => _service.isConnected ? _service.textureId : null;
  double? get currentAspectRatio => _service.aspectRatio;
  String? get lastError => _lastError;

  MicroscopioController() {
    _statusSub = _service.statusStream.listen((s) {
      _status = s;
      notifyListeners();
    });
  }

  Future<void> inicializar() async {
    _lastError = null;
    notifyListeners();

    final ok = await _service.connect();
    if (!ok) {
      _lastError = 'Não foi possível conectar ao microscópio';
      notifyListeners();
    }
  }

  Future<void> reconectar() async {
    await _service.disconnect();
    await inicializar();
  }

  UvcStillPicture? capturarFoto({int quality = 92}) {
    return _service.takePicture(quality: quality);
  }

  UvcPreviewFrame? capturarFrame() {
    return _service.captureFrame();
  }

  void girarHorario() {
    _service.rotateClockwise();
    notifyListeners();
  }

  void girarAntiHorario() {
    _service.rotateCounterClockwise();
    notifyListeners();
  }

  void espelharHorizontal() {
    _service.toggleFlipHorizontal();
    notifyListeners();
  }

  void espelharVertical() {
    _service.toggleFlipVertical();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
