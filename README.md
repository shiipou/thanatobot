# Thanatobot

A Flutter chatbot application with support for both OpenAI Assistant API and Realtime API with voice communication.

## Features

- 🤖 **OpenAI API Integration**: Connect to OpenAI services
  - **Assistant API**: Traditional text-based conversations with custom assistants
  - **Realtime API**: Real-time voice and text conversations with low latency
- 🎤 **Voice Communication**: Speak to the assistant and hear responses in real-time (Realtime API)
- 💬 **Multiple Conversation Threads**: Create and manage multiple chat conversations
- 💾 **Persistent Storage**: All conversations are saved locally on your device
- 📱 **Cross-Platform**: Works on both Android and iOS
- 🎨 **Modern UI**: Clean and intuitive Material Design interface
- 🔊 **Multiple Voices**: Choose from 6 different AI voices
- 🎯 **Communication Modes**: Text-only, voice-only, or mixed mode

## Prerequisites

Before you can use this app, you need:

1. An OpenAI account (sign up at [platform.openai.com](https://platform.openai.com))
2. An OpenAI API key

**For Assistant API mode (traditional):**
3. An OpenAI Assistant ID (create one in the [Assistants playground](https://platform.openai.com/assistants))

**For Realtime API mode (voice support):**
3. Realtime API access (may require waitlist approval from OpenAI)

## Getting Started

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/shiipou/thanatobot.git
   cd thanatobot
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run
   ```

### Configuration

On first launch, the app will prompt you to configure your OpenAI credentials:

#### Assistant API Mode (Traditional)
1. Tap the settings icon in the top right corner
2. Enter your OpenAI API key (starts with `sk-`)
3. Keep "Use Realtime API" toggle OFF
4. Enter your Assistant ID (starts with `asst_`)
5. Tap "Save Configuration"

#### Realtime API Mode (Voice Support)
1. Tap the settings icon in the top right corner
2. Enter your OpenAI API key (starts with `sk-`)
3. Toggle "Use Realtime API" ON
4. Select your preferred voice (alloy, echo, fable, onyx, nova, shimmer)
5. Choose communication mode (Text, Voice, or Text & Voice)
6. Tap "Save Configuration"

For detailed information about voice features, see [REALTIME_API.md](REALTIME_API.md).

### Creating Your OpenAI Assistant

1. Go to [OpenAI Assistants](https://platform.openai.com/assistants)
2. Click "Create" to create a new assistant
3. Configure your assistant:
   - Give it a name and instructions
   - Choose a model (e.g., gpt-4, gpt-3.5-turbo)
   - Optionally add tools or files
4. Copy the Assistant ID from the assistant details page

### Usage

#### Text Mode
1. **Create a new conversation**: Tap the + button on the main screen
2. **Send messages**: Type your message and tap the send button
3. **Switch conversations**: Go back to the main screen and select a different thread
4. **Delete conversations**: Swipe left on any conversation to delete it

#### Voice Mode (Realtime API)
1. **Create a new conversation**: Tap the + button on the main screen
2. **Record voice message**: Long press the microphone button and speak
3. **Release to send**: Release the button when done speaking
4. **Listen to response**: The assistant will respond with voice and text
5. **Interrupt**: Start speaking while the assistant is talking to interrupt

You can also type messages in voice mode if "Text & Voice" mode is selected.

## Building for Release

### Android

```bash
flutter build apk --release
# Or for app bundle
flutter build appbundle --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ios --release
```

Then open the project in Xcode and archive it for distribution.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── chat_thread.dart      # Thread model
│   └── chat_message.dart     # Message model
├── services/                 # Business logic services
│   ├── openai_service.dart   # OpenAI API integration
│   └── storage_service.dart  # Local storage management
├── providers/                # State management
│   └── chat_provider.dart    # Main chat state provider
├── screens/                  # UI screens
│   ├── thread_list_screen.dart  # Main conversation list
│   ├── chat_screen.dart         # Individual chat view
│   └── settings_screen.dart     # Configuration screen
└── widgets/                  # Reusable UI components
    └── message_bubble.dart   # Chat message display
```

## Dependencies

- **flutter**: Flutter SDK
- **http**: HTTP client for API calls
- **shared_preferences**: Local key-value storage
- **path_provider**: Access to device storage paths
- **provider**: State management solution
- **cupertino_icons**: iOS-style icons
- **flutter_markdown**: Markdown rendering
- **record**: Audio recording for voice input
- **audioplayers**: Audio playback for voice output
- **permission_handler**: Handle microphone permissions

## Troubleshooting

### API Key Issues

If you get authentication errors:
- Verify your API key is correct and starts with `sk-`
- Check that your OpenAI account has credits available
- Ensure your API key has the necessary permissions

### Assistant Not Responding (Assistant API)

If the assistant doesn't respond:
- Verify the Assistant ID is correct
- Check that the assistant is active in your OpenAI dashboard
- Ensure you have a stable internet connection

### Voice Not Working (Realtime API)

If voice features don't work:
- Grant microphone permission when prompted
- Check that your API key has Realtime API access
- Ensure stable internet connection for WebSocket
- Try restarting the app

### Storage Issues

If conversations don't persist:
- Check that the app has storage permissions on your device
- Try clearing the app data and reconfiguring

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Powered by [OpenAI Assistants API](https://platform.openai.com/docs/assistants/overview)
