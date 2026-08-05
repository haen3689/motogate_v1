import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, appBar: const MgHeader(title: 'Help'),
      body: ListView(padding: const EdgeInsets.all(22), children: [
        MgListItemCard(title: 'Customer Service', subtitle: 'How can I help?', trailing: '10:30', icon: Icons.headset_mic, onTap: () => Navigator.of(context).pushNamed('/chat/conversation'))]));
  }
}
