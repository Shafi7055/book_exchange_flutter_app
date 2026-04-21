import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/firestore_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/loading_widget.dart';
import '../utils/helpers.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String bookTitle;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.bookTitle,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  String _otherUserName = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    _markMessagesAsRead();
  }

  Future<void> _loadOtherUser() async {
    var userDoc = await _firestoreService.getUser(widget.otherUserId);
    if (userDoc.exists && mounted) {
      setState(() {
        _otherUserName = userDoc['name'] ?? 'User';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _chatService.markAsRead(widget.chatId);
  }

  void _sendMessage(String text) async {
    await _chatService.sendMessage(
      chatId: widget.chatId,
      text: text,
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: const ChatAppBar(title: '', bookTitle: ''),
        body: LoadingWidget(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp background color
      appBar: ChatAppBar(
        title: _otherUserName,
        bookTitle: widget.bookTitle,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const LoadingWidget();
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.grey)),
                        Text('Start the conversation', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                    List<String> deletedBy = List<String>.from(data['deletedBy'] ?? []);

                    if (deletedBy.contains(currentUserId)) {
                      return const SizedBox.shrink();
                    }

                    return ChatBubble(
                      messageId: doc.id,
                      chatId: widget.chatId,
                      message: data['text'] ?? '',
                      senderId: data['senderId'] ?? '',
                      timestamp: (data['timestamp'] as Timestamp).toDate(),
                      isRead: data['isRead'] ?? false,
                      isUnsent: data['isUnsent'] ?? false,
                      reactions: Map<String, String>.from(data['reactions'] ?? {}),
                      onReact: (msgId, emoji) async {
                        await _chatService.reactToMessage(
                          chatId: widget.chatId,
                          messageId: msgId,
                          emoji: emoji,
                        );
                      },
                      onDeleteForMe: (msgId) async {
                        await _chatService.deleteMessageForMe(
                          chatId: widget.chatId,
                          messageId: msgId,
                        );
                      },
                      onUnsend: (msgId) async {
                        await _chatService.unsendMessage(
                          chatId: widget.chatId,
                          messageId: msgId,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          ChatInputBar(onSend: _sendMessage),
        ],
      ),
    );
  }
}

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String bookTitle;

  const ChatAppBar({
    super.key,
    required this.title,
    required this.bookTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Text(
            bookTitle,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      backgroundColor: Colors.teal.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}