import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _assistantIdController = TextEditingController();
  final _settingsService = SettingsService();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _obscureApiKey = true;
  String _selectedVoice = 'alloy';

  // Available OpenAI voices
  static const List<Map<String, String>> _availableVoices = [
    {'value': 'alloy', 'name': 'Alloy'},
    {'value': 'ash', 'name': 'Ash'},
    {'value': 'ballad', 'name': 'Ballad'},
    {'value': 'cedar', 'name': 'Cedar'},
    {'value': 'coral', 'name': 'Coral'},
    {'value': 'echo', 'name': 'Echo'},
    {'value': 'fable', 'name': 'Fable'},
    {'value': 'marin', 'name': 'Marin'},
    {'value': 'nova', 'name': 'Nova'},
    {'value': 'onyx', 'name': 'Onyx'},
    {'value': 'sage', 'name': 'Sage'},
    {'value': 'shimmer', 'name': 'Shimmer'},
    {'value': 'verse', 'name': 'Verse'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _settingsService.loadSettings();
      _apiKeyController.text = settings.apiKey;
      _assistantIdController.text = settings.assistantId;
      _selectedVoice = settings.voice;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading settings: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final settings = AppSettings(
        apiKey: _apiKeyController.text.trim(),
        assistantId: _assistantIdController.text.trim(),
        voice: _selectedVoice,
      );
      await _settingsService.saveSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving settings: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _assistantIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'OpenAI Configuration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        hintText: 'sk-...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKey
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => _obscureApiKey = !_obscureApiKey);
                          },
                        ),
                      ),
                      obscureText: _obscureApiKey,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your OpenAI API key';
                        }
                        if (!value.trim().startsWith('sk-')) {
                          return 'API key should start with sk-';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _assistantIdController,
                      decoration: const InputDecoration(
                        labelText: 'Assistant ID',
                        hintText: 'asst_...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your Assistant ID';
                        }
                        if (!value.trim().startsWith('asst_')) {
                          return 'Assistant ID should start with asst_';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedVoice,
                      decoration: const InputDecoration(
                        labelText: 'Voice',
                        border: OutlineInputBorder(),
                        helperText:
                            'Select the voice for realtime conversations',
                      ),
                      items: _availableVoices.map((voice) {
                        return DropdownMenuItem<String>(
                          value: voice['value'],
                          child: Text(voice['name']!),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _selectedVoice = newValue);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'How to get your credentials:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. API Key:\n'
                      '   • Go to platform.openai.com\n'
                      '   • Navigate to API Keys section\n'
                      '   • Create a new secret key\n\n'
                      '2. Assistant ID:\n'
                      '   • Go to platform.openai.com/assistants\n'
                      '   • Create or select an assistant\n'
                      '   • Copy the Assistant ID (starts with asst_)',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Settings'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
