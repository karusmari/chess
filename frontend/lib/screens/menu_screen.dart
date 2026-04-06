import 'package:flutter/material.dart';
import '../services/websocket_service.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vinge Male")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => socketService.connect(),
          child: const Text("OTSI MÄNGU"),
        ),
      ),
    );
  }
}