# Realtime API Voice Support

This document explains how to use the voice and text communication features powered by OpenAI's Realtime API.

## Overview

The app now supports two modes of operation:

1. **Traditional Assistant API**: Text-based conversations using OpenAI Assistants
2. **Realtime API**: Real-time voice and text conversations with low latency

## Features

### Realtime API Mode

- **Voice Communication**: Speak to the assistant and hear responses in real-time
- **Text Communication**: Type messages just like before
- **Mixed Mode**: Use both voice and text in the same conversation
- **Voice Activity Detection (VAD)**: Automatic detection of when you start and stop speaking
- **Interruption Support**: Interrupt the assistant while it's speaking
- **Multiple Voices**: Choose from 6 different voices (alloy, echo, fable, onyx, nova, shimmer)

## Configuration

### Setting up Realtime API

1. Go to Settings (gear icon in the top right)
2. Enter your OpenAI API Key
3. Toggle "Use Realtime API (Voice Support)" to ON
4. Select your preferred voice from the dropdown
5. Choose your communication mode:
   - **Text**: Only text input/output (traditional chat)
   - **Voice**: Only voice input/output
   - **Text & Voice**: Both modes available
6. Click "Save Configuration"

### Setting up Assistant API (Traditional)

1. Go to Settings
2. Enter your OpenAI API Key
3. Enter your Assistant ID
4. Keep "Use Realtime API" toggle OFF
5. Click "Save Configuration"

## Using Voice Features

### Recording Voice Messages

1. Open a conversation thread
2. Long press the microphone button to start recording
3. Speak your message
4. Release the button to stop recording and send

The assistant will:
- Process your audio in real-time
- Respond with both audio and text
- Display the transcript of the conversation

### Tips for Best Results

- **Speak clearly**: Ensure good audio quality for better recognition
- **Use headphones**: Prevents echo and feedback
- **Quiet environment**: Reduces background noise interference
- **Natural speech**: Speak naturally, pauses are detected automatically

## Permissions

The app requires microphone permission for voice features:

### Android
- Microphone permission is requested automatically
- Grant permission when prompted

### iOS
- Microphone permission is requested automatically
- Grant permission when prompted in the iOS system dialog

## Technical Details

### Audio Format
- **Sample Rate**: 24kHz
- **Format**: PCM16 (16-bit PCM)
- **Channels**: Mono

### Voice Activity Detection (VAD)
- **Type**: Server-side VAD
- **Threshold**: 0.5
- **Prefix Padding**: 300ms
- **Silence Duration**: 500ms

These settings help detect when you start and stop speaking automatically.

### Realtime API Model
- **Model**: gpt-4o-realtime-preview-2024-10-01
- **Latency**: ~300ms typical response time
- **Modalities**: Text and Audio

## Troubleshooting

### Voice Not Working

1. **Check Permissions**: Ensure microphone permission is granted
2. **Check API Key**: Verify your API key has Realtime API access
3. **Check Internet**: Ensure stable internet connection
4. **Restart App**: Sometimes a restart helps reset the connection

### Audio Quality Issues

1. **Use Headphones**: Reduces echo and feedback
2. **Check Microphone**: Test with other apps to ensure microphone works
3. **Reduce Background Noise**: Find a quieter environment

### Connection Issues

1. **Check Internet**: WebSocket requires stable connection
2. **Try Again**: Connection may fail occasionally, try reconnecting
3. **Check API Status**: Visit OpenAI status page to check for outages

## API Costs

Realtime API has different pricing than the traditional API:

- **Input Audio**: Charged per minute of audio
- **Output Audio**: Charged per minute of audio
- **Text**: Standard token pricing

Check OpenAI's pricing page for current rates.

## Limitations

- **Web Platform**: Voice features work best on mobile devices
- **Browser Support**: Some browsers may have limited audio support
- **Audio Playback**: Currently plays raw PCM audio (may need conversion for some platforms)
- **Conversation History**: Voice conversations are stored as text transcripts only

## Future Improvements

Potential enhancements for future versions:

- [ ] Audio file storage for playback later
- [ ] Voice cloning and customization
- [ ] Real-time translation
- [ ] Conversation analytics
- [ ] Enhanced audio playback with proper format conversion
- [ ] Background noise suppression
- [ ] Echo cancellation

## Support

For issues or questions:
1. Check this documentation first
2. Review OpenAI's Realtime API documentation
3. Open an issue on GitHub

## Resources

- [OpenAI Realtime API Documentation](https://platform.openai.com/docs/guides/realtime)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [OpenAI Pricing](https://openai.com/pricing)
