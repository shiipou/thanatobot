import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_thread.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final ChatThread thread;

  const ChatScreen({super.key, required this.thread});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.thread.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.thread.id);
                
                if (messages.isEmpty && !provider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (provider.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    
                    final message = messages[index];
                    return MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (context, provider, child) {
              if (provider.error != null) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red[100],
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final supportsVoice = provider.useRealtimeApi && 
                              provider.communicationMode.supportsVoice;
        final supportsText = !provider.useRealtimeApi || 
                            provider.communicationMode.supportsText;
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (supportsText)
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !provider.isLoading && !provider.isRecording,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(context, provider),
                  ),
                ),
              if (!supportsText && supportsVoice)
                Expanded(
                  child: Center(
                    child: Text(
                      provider.isRecording 
                          ? 'Recording...' 
                          : 'Tap microphone to speak',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (supportsText)
                IconButton(
                  onPressed: provider.isLoading || provider.isRecording
                      ? null
                      : () => _sendMessage(context, provider),
                  icon: Icon(
                    Icons.send,
                    color: provider.isLoading || provider.isRecording
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
              if (supportsVoice)
                GestureDetector(
                  onLongPressStart: (_) => _startVoiceRecording(context, provider),
                  onLongPressEnd: (_) => _stopVoiceRecording(context, provider),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: provider.isRecording 
                          ? Colors.red 
                          : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      provider.isRecording ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, ChatProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    provider.sendMessage(widget.thread.id, text);
  }

  void _startVoiceRecording(BuildContext context, ChatProvider provider) {
    provider.startVoiceRecording(widget.thread.id).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $error')),
      );
    });
  }

  void _stopVoiceRecording(BuildContext context, ChatProvider provider) {
    provider.stopVoiceRecording(widget.thread.id).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $error')),
      );
    });
  }
}
