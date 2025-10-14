# Thanatobot

A Flutter chatbot application using OpenAI Assistant API with multi-threaded conversations and persistent storage.

## Features

- 🤖 **OpenAI Assistant API Integration**: Connect to your custom OpenAI assistant
- 💬 **Multiple Conversation Threads**: Create and manage multiple chat conversations
- 💾 **Persistent Storage**: All conversations are saved locally on your device
- 📱 **Cross-Platform**: Works on both Android and iOS
- 🎨 **Modern UI**: Clean and intuitive Material Design interface

## Prerequisites

Before you can use this app, you need:

1. An OpenAI account (sign up at [platform.openai.com](https://platform.openai.com))
2. An OpenAI API key
3. An OpenAI Assistant ID (create one in the [Assistants playground](https://platform.openai.com/assistants))

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

1. Tap the settings icon in the top right corner
2. Enter your OpenAI API key (starts with `sk-`)
3. Enter your Assistant ID (starts with `asst_`)
4. Tap "Save Configuration"

### Creating Your OpenAI Assistant

1. Go to [OpenAI Assistants](https://platform.openai.com/assistants)
2. Click "Create" to create a new assistant
3. Configure your assistant:
   - Give it a name and instructions
   - Choose a model (e.g., gpt-4, gpt-3.5-turbo)
   - Optionally add tools or files
4. Copy the Assistant ID from the assistant details page

### Usage

1. **Create a new conversation**: Tap the + button on the main screen
2. **Send messages**: Type your message and tap the send button
3. **Switch conversations**: Go back to the main screen and select a different thread
4. **Delete conversations**: Swipe left on any conversation to delete it

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

## Troubleshooting

### API Key Issues

If you get authentication errors:
- Verify your API key is correct and starts with `sk-`
- Check that your OpenAI account has credits available
- Ensure your API key has the necessary permissions

### Assistant Not Responding

If the assistant doesn't respond:
- Verify the Assistant ID is correct
- Check that the assistant is active in your OpenAI dashboard
- Ensure you have a stable internet connection

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
