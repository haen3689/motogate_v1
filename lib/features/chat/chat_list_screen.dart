import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../core/services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ChatService.getMessages();
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _messages.isNotEmpty ? _messages.last : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MgHeader(title: 'ຊ່ວຍເຫຼືອ'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(22),
              children: [
                MgListItemCard(
                  title: 'ຝ່າຍບໍລິການລູກຄ້າ',
                  subtitle: last != null ? last.body : 'ສົ່ງຂໍ້ຄວາມມາຫາພວກເຮົາ',
                  trailing: last != null ? DateFormat('HH:mm').format(last.createdAt.toLocal()) : '',
                  icon: Icons.headset_mic,
                  onTap: () async {
                    await Navigator.of(context).pushNamed('/chat/conversation');
                    _load();
                  },
                ),
              ],
            ),
    );
  }
}
