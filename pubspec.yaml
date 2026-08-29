import 'dart:async';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';

enum UvcStatus { disconnected, connecting, connected, error }

class UvcCameraService {
  final UvcCamera _camera = uvcCamera;

  StreamSubscription<UvcDeviceEvent>? _eventSub;
  UvcCameraMode? _currentMode;
  int _textureId = -1;

  final StreamController<UvcStatus> _statusController =
      StreamController<UvcStatus>.broadcast();

  Stream<UvcStatus> get statusStream => _statusController.stream;

  UvcCameraMode? get currentMode => _currentMode;
  int get textureId => _textureId;
  bool get isConnected => _textureId != -1 && _currentMode != null;

  double? get aspectRatio {
    if (_currentMode == null) return null;
    final (w, h) = _camera.previewTransform
        .applyToSize(_currentMode!.width, _currentMode!.height);
    return w / h;
  }

  Future<bool> connect() async {
    try {
      _statusController.add(UvcStatus.connecting);

      await _camera.ensureCameraPermission();

      final devices = await _camera.listUsbDevices();
      if (devices.isEmpty) {
        print('[UVC] Nenhum dispositivo UVC encontrado');
        _statusController.add(UvcStatus.disconnected);
        return false;
      }

      final device = devices.first;
      print('[UVC] Dispositivo: ${device.displayName}');

      final openResult = await _camera.openUsbDevice(device.deviceId);
      if (openResult != 0) {
        print('[UVC] Erro ao abrir: ${_camera.lastError}');
        _statusController.add(UvcStatus.error);
        return false;
      }

      _eventSub?.cancel();
      _eventSub = _camera.deviceEvents.listen((event) {
        if (event.type == UvcDeviceEventType.detached) {
          print('[UVC] Dispositivo desconectado');
          _disconnect();
        }
      });

      _textureId = await _camera.createPreviewTexture();

      final previewResult = await _camera.startPreviewAuto();
      if (!previewResult.success) {
        print('[UVC] Falha no preview:');
        for (final attempt in previewResult.attempts) {
          print('  ${attempt.mode.label}: ${attempt.lastError}');
        }
        await _safeCleanup();
        _statusController.add(UvcStatus.error);
        return false;
      }

      _currentMode = previewResult.mode!;
      print(
          '[UVC] Modo: ${_currentMode!.width}x${_currentMode!.height} @ ${_currentMode!.fps}fps');

      await _camera.attachPreviewTexture(
        _textureId,
        width: _currentMode!.width,
        height: _currentMode!.height,
      );

      _statusController.add(UvcStatus.connected);
      return true;
    } catch (e, s) {
      print('[UVC] Erro: $e\n$s');
      await _safeCleanup();
      _statusController.add(UvcStatus.error);
      return false;
    }
  }

  UvcPreviewFrame? captureFrame() {
    if (!isConnected) return null;
    return _camera.copyLatestFrameTransformed(_camera.previewTransform);
  }

  UvcStillPicture? takePicture({int quality = 92}) {
    if (!isConnected) return null;
    return _camera.takePicture(quality: quality);
  }

  void setPreviewTransform(UvcPreviewTransform transform) =>
      _camera.setPreviewTransform(transform);

  void rotateClockwise() => _camera.rotatePreviewClockwise();
  void rotateCounterClockwise() => _camera.rotatePreviewCounterClockwise();
  void toggleFlipHorizontal() => _camera.togglePreviewFlipHorizontal();
  void toggleFlipVertical() => _camera.togglePreviewFlipVertical();

  Future<void> _safeCleanup() async {
    try {
      _camera.stopPreview();
    } catch (_) {}
    if (_textureId != -1) {
      try {
        await _camera.disposePreviewTexture(_textureId);
      } catch (_) {}
      _textureId = -1;
    }
    try {
      await _camera.closeUsbDevice();
    } catch (_) {}
    _currentMode = null;
  }

  Future<void> disconnect() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _safeCleanup();
    _statusController.add(UvcStatus.disconnected);
  }

  /// Usado internamente quando o dispositivo é desconectado (evento "detached").
  /// Diferente de disconnect(), não cancela a assinatura de deviceEvents,
  /// pois ela mesma que disparou esta chamada.
  Future<void> _disconnect() async {
    await _safeCleanup();
    _statusController.add(UvcStatus.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }
}
