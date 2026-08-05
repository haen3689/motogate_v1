import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
class ChatConversationScreen extends StatelessWidget {
  const ChatConversationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Customer Service'), backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
      body: Column(children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [_b('Hello, how can I help?', false), _b('I need info about road tax', true), _b('Sure, send your plate number', false)])),
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.grey100))),
          child: SafeArea(top: false, child: Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
              child: const TextField(decoration: InputDecoration(hintText: 'Type a message...', border: InputBorder.none)))),
            const SizedBox(width: 8), Container(width: 44, height: 44, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.send, color: AppColors.white, size: 20))])))]));
  }
  Widget _b(String m, bool me) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Align(alignment: me ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(constraints: const BoxConstraints(maxWidth: 280), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: me ? AppColors.primary : AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Text(m, style: TextStyle(fontSize: 14, color: me ? AppColors.white : AppColors.black)))));
}
