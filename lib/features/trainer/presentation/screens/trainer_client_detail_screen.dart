import 'package:flutter/material.dart';

class TrainerClientDetailScreen extends StatelessWidget {
  final String clientId;
  const TrainerClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Detail')),
      body: Center(child: Text('Client: $clientId')),
    );
  }
}
