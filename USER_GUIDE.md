# OpenAI Realtime Assistant - User Guide

## Overview

This Flutter app provides an instant messaging interface with OpenAI's AI assistants, featuring both text-based chat and real-time voice conversations.

## Setup

### 1. Get Your OpenAI Credentials

**API Key:**
1. Go to [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Click "Create new secret key"
3. Copy the key (starts with `sk-`)

**Assistant ID:**
1. Go to [platform.openai.com/assistants](https://platform.openai.com/assistants)
2. Create or select an assistant
3. Copy the Assistant ID (starts with `asst_`)

### 2. Configure the App

1. Launch the app
2. Enter your API Key and Assistant ID in the settings
3. Tap "Save Settings"

## Features

### Text Chat
- Create conversation threads
- Send and receive text messages
- View message history
- Delete threads

### Voice Calls
- Real-time voice conversations
- Live transcription of both sides
- Voice Activity Detection
- Interruption support

## Usage

### Starting a Conversation
1. Tap the **+** button on the home screen
2. A new thread will be created
3. Type your message and send

### Making a Voice Call
1. Open any conversation thread
2. Tap the **phone** icon
3. Allow microphone permissions
4. Start speaking when connected
5. Tap "End Call" when finished

### Transcriptions
- All voice conversations are transcribed in real-time
- Transcriptions appear in the voice call screen
- They are saved back to the thread's message history

## Permissions

The app requires:
- **Internet**: To connect to OpenAI API
- **Microphone**: For voice calls

## Cost Warning

OpenAI's Realtime API charges approximately:
- $0.06 per minute for audio input
- $0.24 per minute for audio output

Monitor your usage at [platform.openai.com/usage](https://platform.openai.com/usage)

## Troubleshooting

**Can't connect:**
- Verify your API key is correct
- Check internet connection
- Ensure you have OpenAI credits

**Microphone issues:**
- Grant permissions in device settings
- Restart the app
- Check if another app is using the microphone

**Poor audio quality:**
- Ensure stable internet connection
- Speak clearly into the microphone
- Reduce background noise
