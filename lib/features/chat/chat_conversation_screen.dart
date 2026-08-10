import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/api_auth_service.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key});
  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  ChatSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final list = await ChatService.getMessages();
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
      _scrollToBottom();
    }

    try {
      final me = await ApiAuthService.me();
      final userId = me['id'] as int?;
      if (userId == null) return;
      _subscription = ChatService.subscribe(userId);
      _subscription!.messages.listen((msg) {
        if (!mounted) return;
        if (_messages.any((m) => m.id == msg.id)) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
      });
    } catch (_) {
      // best-effort — user can still pull-to-refresh via re-opening the screen
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    final msg = await ChatService.send(text);
    if (mounted) {
      setState(() {
        _sending = false;
        if (msg != null && !_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _subscription?.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ຝ່າຍບໍລິການລູກຄ້າ'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFFFEF3C7),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Color(0xFFB45309), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'ຕອນນີ້ມີຜູ້ໃຊ້ຈຳນວນຫຼາຍກຳລັງລໍຖ້າ ພະນັກງານອາດຕອບຊ້າກວ່າປົກກະຕິ ກະລຸນາລໍຖ້າບ່ອນດຽວ',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _messages.isEmpty
                  ? const Center(child: Text('ສົ່ງຂໍ້ຄວາມມາຫາພວກເຮົາໄດ້ເລີຍ', style: TextStyle(color: AppColors.grey500)))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _bubble(_messages[i]),
                    ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.grey100))),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(hintText: 'ພິມຂໍ້ຄວາມ...', border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : const Icon(Icons.send, color: AppColors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _bubble(ChatMessage m) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: m.fromUser ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(m.body, style: TextStyle(fontSize: 14, color: m.fromUser ? AppColors.white : AppColors.black)),
              ),
              const SizedBox(height: 3),
              Text(DateFormat('HH:mm').format(m.createdAt.toLocal()),
                  style: const TextStyle(fontSize: 10, color: AppColors.grey400)),
            ],
          ),
        ),
      );
}
