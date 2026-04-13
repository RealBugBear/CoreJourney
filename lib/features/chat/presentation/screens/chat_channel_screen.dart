import 'package:flutter/material.dart';

import '../../domain/models/chat_channel.dart';

class ChatChannelScreen extends StatelessWidget {
  const ChatChannelScreen({super.key, required this.channelId, this.channel});

  final String channelId;
  final ChatChannel? channel;

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(title: Text(channel?.channelDisplayName() ?? channelId)),
        body: const Center(child: Text('Chat Channel — coming soon')),
      );
}
