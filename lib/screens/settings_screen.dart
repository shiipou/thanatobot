import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/communication_mode.dart';
import '../services/realtime_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _assistantIdController = TextEditingController();
  bool _obscureApiKey = true;
  bool _useRealtimeApi = false;
  String _selectedModel = RealtimeConstants.defaultModel;
  String _selectedVoice = RealtimeConstants.defaultVoice;
  CommunicationMode _selectedMode = CommunicationMode.text;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _assistantIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'API Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureApiKey,
            decoration: InputDecoration(
              labelText: 'OpenAI API Key',
              hintText: 'sk-...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureApiKey = !_obscureApiKey;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Use Realtime API (Voice Support)'),
            subtitle: const Text('Enable voice and real-time communication'),
            value: _useRealtimeApi,
            onChanged: (value) {
              setState(() {
                _useRealtimeApi = value;
              });
            },
          ),
          const SizedBox(height: 16),
          if (!_useRealtimeApi) ...[
            TextField(
              controller: _assistantIdController,
              decoration: const InputDecoration(
                labelText: 'Assistant ID',
                hintText: 'asst_...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_useRealtimeApi) ...[
            DropdownButtonFormField<String>(
              value: _selectedModel,
              decoration: const InputDecoration(
                labelText: 'Model',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'gpt-4o-realtime-preview-2024-10-01',
                  child: Text('GPT-4o Realtime Preview'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedModel = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: const InputDecoration(
                labelText: 'Voice',
                border: OutlineInputBorder(),
              ),
              items: RealtimeConstants.availableVoices
                  .map((voice) => DropdownMenuItem(
                        value: voice,
                        child: Text(voice[0].toUpperCase() + voice.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedVoice = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CommunicationMode>(
              value: _selectedMode,
              decoration: const InputDecoration(
                labelText: 'Communication Mode',
                border: OutlineInputBorder(),
              ),
              items: CommunicationMode.values
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: _saveConfiguration,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save Configuration'),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thanatobot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Version 1.0.0'),
                  SizedBox(height: 16),
                  Text(
                    'A chatbot application with support for OpenAI Assistant API and Realtime API for voice communication.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to get started:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Create an OpenAI account at platform.openai.com'),
                  const Text('2. Generate an API key from your account'),
                  if (!_useRealtimeApi) ...[
                    const Text('3. Create an Assistant in the Assistants section'),
                    const Text('4. Copy the Assistant ID'),
                    const Text('5. Enter both values above and save'),
                  ] else ...[
                    const Text('3. Enable Realtime API access in your account'),
                    const Text('4. Choose your preferred voice and mode'),
                    const Text('5. Enter your API key and save'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveConfiguration() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_useRealtimeApi) {
      final assistantId = _assistantIdController.text.trim();
      if (assistantId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter an Assistant ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        await context.read<ChatProvider>().configure(apiKey, assistantId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      try {
        await context.read<ChatProvider>().configureRealtime(
              apiKey: apiKey,
              useRealtime: true,
              model: _selectedModel,
              voice: _selectedVoice,
              mode: _selectedMode,
            );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Realtime API configuration saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
