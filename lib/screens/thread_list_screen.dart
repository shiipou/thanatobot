import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ThreadListScreen extends StatelessWidget {
  const ThreadListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanatobot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (!provider.isConfigured) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Please configure your OpenAI API credentials',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            );
          }

          if (provider.threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to start a new chat',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.threads.length,
            itemBuilder: (context, index) {
              final thread = provider.threads[index];
              return Dismissible(
                key: Key(thread.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  provider.deleteThread(thread.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thread deleted')),
                  );
                },
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.chat),
                  ),
                  title: Text(thread.title),
                  subtitle: Text(
                    _formatDateTime(thread.lastMessageAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(thread: thread),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (!provider.isConfigured) return const SizedBox.shrink();
          
          return FloatingActionButton(
            onPressed: () => _showNewThreadDialog(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showNewThreadDialog(BuildContext context) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'Enter conversation title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              
              Navigator.pop(context);
              
              final provider = context.read<ChatProvider>();
              try {
                final thread = await provider.createThread(controller.text.trim());
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(thread: thread),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
