# harnessvm-app

A Flutter mobile app that uses Tailscale connectivity (phone + VM) to chat with AI agents running in the cloud through a VM-hosted HTTP chat endpoint.

## What this app does

- Lets you enter a VM chat endpoint URL (Tailscale IP or MagicDNS)
- Sends chat messages from the phone to that VM endpoint
- Displays AI responses in a simple chat interface

## Expected network setup

1. Install and sign in to Tailscale on your phone.
2. Install and sign in to Tailscale on the VM that can reach your cloud AI agent service.
3. Expose an HTTP endpoint on the VM (default used by this app is `http://100.64.0.10:8000/chat`) that accepts:
   - `POST /chat`
   - JSON body: `{ "message": "..." }`
   - JSON response with one of: `response`, `reply`, or `message`

## Run the Flutter app

```bash
flutter pub get
flutter run
```

Then update the endpoint field in the app if your VM uses a different Tailscale IP/MagicDNS name or port.
