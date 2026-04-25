import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/gemini_service.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(ref.read(geminiServiceProvider)),
);

class ChatMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final DateTime time;
  ChatMessage({required this.role, required this.text}) : time = DateTime.now();
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final GeminiService _gemini;
  ChatNotifier(this._gemini) : super([
    ChatMessage(role: 'ai', text: 'CrisisSync AI online. 2 active incidents detected. How can I assist coordination?'),
  ]);

  Future<void> send(String message) async {
    state = [...state, ChatMessage(role: 'user', text: message)];
    final reply = await _gemini.sendMessage(message);
    state = [...state, ChatMessage(role: 'ai', text: reply)];
  }
}

final loadingProvider = StateProvider<bool>((_) => false);

class AiAssistScreen extends ConsumerStatefulWidget {
  const AiAssistScreen({super.key});
  @override
  ConsumerState<AiAssistScreen> createState() => _AiAssistScreenState();
}

class _AiAssistScreenState extends ConsumerState<AiAssistScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  final _quickPrompts = [
    'Evacuate Banquet Hall — steps?',
    'Status of all critical incidents',
    'Nearest AED to Room 412',
    'Draft PA for fire in kitchen',
    'Who is available for dispatch?',
  ];

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ref.read(loadingProvider.notifier).state = true;
    await ref.read(chatProvider.notifier).send(text);
    ref.read(loadingProvider.notifier).state = false;
    await Future.delayed(const Duration(milliseconds: 100));
    _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final loading  = ref.watch(loadingProvider);

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF111418),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFFBF5AF2)]),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gemini AI Command Center',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Powered by Gemini 1.5 Pro · Real-time crisis intelligence',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2010),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF30D158)),
            ),
            child: const Row(children: [
              Icon(Icons.circle, color: Color(0xFF30D158), size: 8),
              SizedBox(width: 6),
              Text('ONLINE', style: TextStyle(color: Color(0xFF30D158), fontSize: 10, fontWeight: FontWeight.bold)),
            ]),
          ),
        ]),
      ),

      // Messages
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length + (loading ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (loading && i == messages.length) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E242E)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (int d = 0; d < 3; d++)
                      Container(
                        width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(color: Color(0xFF0A84FF), shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat())
                          .fadeIn(delay: Duration(milliseconds: d * 200))
                          .fadeOut(delay: Duration(milliseconds: 400 + d * 200)),
                  ]),
                ),
              );
            }
            final msg = messages[i];
            final isUser = msg.role == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.7),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFF0060CC)])
                      : null,
                  color: isUser ? null : const Color(0xFF181C22),
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(16),
                    topRight:    const Radius.circular(16),
                    bottomLeft:  Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser ? null : Border.all(color: const Color(0xFF1E242E)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!isUser)
                    const Text('✦ Gemini',
                        style: TextStyle(color: Color(0xFF0A84FF), fontSize: 10, fontWeight: FontWeight.bold)),
                  if (!isUser) const SizedBox(height: 4),
                  Text(msg.text, style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFFE8EDF5),
                    fontSize: 13, height: 1.6,
                  )),
                ]),
              ).animate().fadeIn().slideY(begin: 0.1),
            );
          },
        ),
      ),

      // Quick prompts
      Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        color: const Color(0xFF111418),
        child: Wrap(spacing: 8, children: _quickPrompts.map((q) => ActionChip(
          label: Text(q, style: const TextStyle(fontSize: 10)),
          onPressed: () { _ctrl.text = q; _send(); },
          backgroundColor: const Color(0xFF181C22),
          side: const BorderSide(color: Color(0xFF1E242E)),
        )).toList()),
      ),

      // Input
      Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF111418),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ask Gemini for crisis coordination help...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF181C22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E242E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1E242E)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A84FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
      ),
    ]);
  }
}
