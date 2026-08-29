import 'package:flutter/material.dart';
import 'screens/tela_principal.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MicroscopioApp());
}

class MicroscopioApp extends StatelessWidget {
  const MicroscopioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Microscópio USB',
      theme: ThemeData.dark(useMaterial3: true),
      home: const TelaPrincipal(),
    );
  }
}
