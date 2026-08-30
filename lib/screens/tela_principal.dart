import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../controllers/microscopio_controller.dart';
import '../services/uvc_camera_service.dart';
import 'galeria_screen.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  late final MicroscopioController _controller;
  double _flashOpacity = 0.0;
  String _feedback = '';
  final List<Uint8List> _fotosSessao = [];
  final TransformationController _zoomController = TransformationController();

  @override
  void initState() {
    super.initState();
    _controller = MicroscopioController();
    _controller.addListener(_onControllerChanged);
    _controller.inicializar();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _capturar() async {
    final picture = _controller.capturarFoto();
    if (picture == null) {
      _mostrarFeedback('Falha ao capturar');
      return;
    }
    _dispararFlash();
    setState(() => _fotosSessao.insert(0, picture.jpegBytes));
    try {
      await Gal.putImageBytes(picture.jpegBytes, name: 'microscopio_${DateTime.now().millisecondsSinceEpoch}');
      _mostrarFeedback('Foto salva na galeria!');
    } on GalException catch (e) {
      _mostrarFeedback('Erro ao salvar: ${e.type.message}');
    }
  }

  void _resetarZoom() {
    _zoomController.value = Matrix4.identity();
  }

  void _abrirGaleria() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GaleriaScreen(fotos: _fotosSessao)),
    );
  }

  Color _corStatus() {
    switch (_controller.status) {
      case UvcStatus.connected:
        return Colors.green;
      case UvcStatus.connecting:
        return Colors.orange;
      case UvcStatus.error:
        return Colors.red;
      case UvcStatus.disconnected:
        return Colors.grey;
    }
  }

  void _dispararFlash() {
    setState(() => _flashOpacity = 1.0);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _flashOpacity = 0.0);
    });
  }

  void _mostrarFeedback(String texto) {
    setState(() => _feedback = texto);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _feedback = '');
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildPreview()),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashOpacity,
              duration: const Duration(milliseconds: 80),
              child: Container(color: Colors.white),
            ),
          ),
          if (_feedback.isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_feedback, style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _corStatus(),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              children: [
                _botaoTopo(Icons.photo_library, _abrirGaleria),
                const SizedBox(width: 8),
                _botaoTopo(Icons.zoom_out_map, _resetarZoom),
                const SizedBox(width: 8),
                _botaoTopo(Icons.rotate_left, _controller.girarAntiHorario),
                const SizedBox(width: 8),
                _botaoTopo(Icons.flip, _controller.espelharHorizontal),
                const SizedBox(width: 8),
                _botaoTopo(Icons.swap_vert, _controller.espelharVertical),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _botao(Icons.refresh, 'Reconectar', _controller.reconectar),
                _botaoGrande(Icons.camera_alt, _capturar),
                _botao(Icons.rotate_right, 'Girar', _controller.girarHorario),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_controller.estaCarregando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Conectando ao microscópio...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    if (_controller.estaConectado && _controller.textureId != null) {
      return Center(
        child: InteractiveViewer(
          transformationController: _zoomController,
          minScale: 1.0,
          maxScale: 5.0,
          panEnabled: true,
          child: AspectRatio(
            aspectRatio: _controller.currentAspectRatio ?? 16 / 9,
            child: Texture(textureId: _controller.textureId!),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.usb_off, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            _controller.lastError ?? 'Conecte o microscópio USB',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _controller.inicializar,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _botao(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white, size: 28)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _botaoTopo(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black45,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _botaoGrande(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          color: Colors.white24,
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
