# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Prerequisites
- Flutter SDK installed ([flutter.dev](https://flutter.dev))
- OpenAI account with API access
- Android device or emulator (iOS support included but not tested)

### 2. Get Your OpenAI Credentials

#### API Key
1. Visit https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Copy the key (format: `sk-...`)

#### Assistant ID
1. Visit https://platform.openai.com/assistants
2. Click "Create" or select existing assistant
3. Copy the Assistant ID (format: `asst_...`)

### 3. Run the App

```bash
# Clone and enter directory (if needed)
cd thanatobot

# Get dependencies
flutter pub get

# Run on connected device
flutter run
```

### 4. Configure the App

On first launch:
1. Enter your **API Key** (sk-...)
2. Enter your **Assistant ID** (asst_...)
3. Tap **Save Settings**

### 5. Start Chatting!

**Text Chat:**
- Tap **+** to create a new thread
- Type a message and send
- Wait for AI response

**Voice Call:**
- Open any thread
- Tap the **phone icon**
- Allow microphone permission
- Start speaking!

## 📱 What You Can Do

### Text Messaging
- Create unlimited conversation threads
- Send and receive text messages
- View message history
- Delete old threads

### Voice Calls
- Real-time voice conversations
- Live transcription of your speech
- Live transcription of AI responses
- Natural conversation flow
- Voice Activity Detection (no need to press buttons)

## 💡 Tips

- Voice calls require a stable internet connection
- Speak clearly for best transcription accuracy
- Monitor your OpenAI usage (voice calls can be costly)
- Settings are saved locally on your device

## ⚠️ Important Notes

### Costs
OpenAI charges for API usage:
- Text messages: ~$0.03-0.06 per 1K tokens
- Voice calls: ~$0.30 per minute of conversation

**Monitor your usage at:** https://platform.openai.com/usage

### Permissions
The app needs:
- **Internet**: To connect to OpenAI
- **Microphone**: For voice calls

These are requested when needed.

## 🐛 Troubleshooting

### "Failed to connect"
- Check your API key is correct
- Verify you have OpenAI credits
- Test your internet connection

### "Microphone not working"
- Grant microphone permission
- Check device settings
- Restart the app

### "No response from AI"
- Check your Assistant ID is correct
- Verify the assistant exists in your OpenAI account
- Check OpenAI API status

## 📚 Learn More

- **USER_GUIDE.md** - Detailed user instructions
- **IMPLEMENTATION.md** - Technical implementation details
- **Python version** - https://github.com/shiipou/ha-realtime-gpt-va

## 🎯 Next Steps

After you're comfortable with the basics:
1. Customize your assistant at platform.openai.com/assistants
2. Add instructions for specific use cases
3. Experiment with different conversation styles
4. Monitor and optimize your API usage

Enjoy your AI assistant! 🤖
