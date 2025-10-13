# Thanatobot Architecture

## Application Architecture

```
┌─────────────────────────────────────────────────────────┐
│                         User                             │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                            │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │ ThreadListScreen│  │   ChatScreen    │              │
│  └─────────────────┘  └─────────────────┘              │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │ SettingsScreen  │  │  MessageBubble  │              │
│  └─────────────────┘  └─────────────────┘              │
└──────────────────┬──────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│                  State Management                        │
│            (Provider - ChatProvider)                     │
└──────────────────┬──────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌────────────────┐    ┌────────────────┐
│ StorageService │    │ OpenAIService  │
└────────────────┘    └────────────────┘
        │                     │
        ▼                     ▼
┌────────────────┐    ┌────────────────┐
│ SharedPrefs    │    │  OpenAI API    │
│ (Local Device) │    │  (Internet)    │
└────────────────┘    └────────────────┘
```

## Data Flow

### Creating a New Thread
```
User clicks + button
    ↓
Shows dialog for thread title
    ↓
ChatProvider.createThread()
    ↓
OpenAIService.createThread() → API Call
    ↓
StorageService.saveThread() → Local Storage
    ↓
UI updates with new thread
```

### Sending a Message
```
User types message and sends
    ↓
ChatProvider.sendMessage()
    ↓
StorageService.saveMessage() (user message)
    ↓
OpenAIService.sendMessageAndGetResponse()
    ├─ addMessage() → API Call
    ├─ runAssistant() → API Call
    ├─ Wait for completion (polling)
    └─ getMessages() → API Call
    ↓
StorageService.saveMessage() (assistant response)
    ↓
UI updates with both messages
```

## Models

### ChatThread
- `id`: OpenAI thread identifier
- `title`: User-defined thread name
- `createdAt`: Creation timestamp
- `lastMessageAt`: Last activity timestamp

### ChatMessage
- `id`: Unique message identifier
- `threadId`: Associated thread ID
- `content`: Message text
- `isUser`: Boolean (true for user, false for assistant)
- `timestamp`: Message timestamp

## Storage Strategy

All data is stored locally using SharedPreferences in JSON format:

- **Threads**: Stored as `threads` key with JSON array
- **Messages**: Stored as `messages_{threadId}` keys with JSON arrays
- **Configuration**: API key and Assistant ID stored separately

## API Integration

Uses OpenAI Assistants API v2:

- **Create Thread**: `POST /v1/threads`
- **Add Message**: `POST /v1/threads/{thread_id}/messages`
- **Run Assistant**: `POST /v1/threads/{thread_id}/runs`
- **Check Run Status**: `GET /v1/threads/{thread_id}/runs/{run_id}`
- **Get Messages**: `GET /v1/threads/{thread_id}/messages`

## Security Considerations

- API keys stored locally on device (encrypted by SharedPreferences)
- No API keys in source code
- HTTPS communication with OpenAI API
- User must provide their own credentials
