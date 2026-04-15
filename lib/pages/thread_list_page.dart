import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import '../services/openai_service.dart';
import 'chat_page.dart';
import 'settings_page.dart';

class ThreadListPage extends StatefulWidget {
  const ThreadListPage({super.key});

  @override
  State<ThreadListPage> createState() => _ThreadListPageState();
}

class _ThreadListPageState extends State<ThreadListPage> {
  final _settingsService = SettingsService();
  List<Thread> _threads = [];
  bool _isLoading = true;
  bool _isCreating = false;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _settings = await _settingsService.loadSettings();

      if (!_settings!.isConfigured) {
        // Navigate to settings if not configured
        if (mounted) {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
          if (result == true) {
            _loadData();
          }
        }
        return;
      }

      _threads = await _settingsService.loadThreads();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading threads: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createThread() async {
    if (_settings == null || !_settings!.isConfigured) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      final openAI = OpenAIService(
        apiKey: _settings!.apiKey,
        assistantId: _settings!.assistantId,
      );

      final thread = await openAI.createThread();
      await _settingsService.saveThread(thread);

      setState(() => _threads.insert(0, thread));

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ChatPage(thread: thread)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating thread: $e')));
      }
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _deleteThread(Thread thread) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Thread'),
        content: const Text('Are you sure you want to delete this thread?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _settingsService.deleteThread(thread.id);
        setState(() => _threads.removeWhere((t) => t.id == thread.id));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting thread: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
              if (result == true) {
                _loadData();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
          ? Center(
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
                    'No conversations yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to start a new conversation',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                itemCount: _threads.length,
                itemBuilder: (context, index) {
                  final thread = _threads[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.chat)),
                    title: Text('Thread ${thread.id.substring(0, 8)}...'),
                    subtitle: Text('Created: ${_formatDate(thread.createdAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteThread(thread),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatPage(thread: thread),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isCreating ? null : _createThread,
        child: _isCreating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
