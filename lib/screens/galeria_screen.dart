import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class GaleriaScreen extends StatelessWidget {
  final List<Uint8List> fotos;

  const GaleriaScreen({super.key, required this.fotos});

  Future<void> _compartilhar(Uint8List bytes) async {
    final arquivo = XFile.fromData(
      bytes,
      mimeType: 'image/jpeg',
      name: 'microscopio_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await SharePlus.instance.share(ShareParams(files: [arquivo]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Fotos desta sessão (${fotos.length})'),
      ),
      body: fotos.isEmpty
          ? const Center(
              child: Text(
                'Nenhuma foto capturada ainda',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: fotos.length,
              itemBuilder: (context, index) {
                final foto = fotos[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _FotoDetalheScreen(
                        bytes: foto,
                        onCompartilhar: () => _compartilhar(foto),
                      ),
                    ),
                  ),
                  child: Image.memory(foto, fit: BoxFit.cover),
                );
              },
            ),
    );
  }
}

class _FotoDetalheScreen extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onCompartilhar;

  const _FotoDetalheScreen({required this.bytes, required this.onCompartilhar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: onCompartilhar,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 5.0,
          child: Image.memory(bytes),
        ),
      ),
    );
  }
}
