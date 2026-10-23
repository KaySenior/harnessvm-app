import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const HarnessVmApp());
}

class HarnessVmApp extends StatelessWidget {
  const HarnessVmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HarnessVM Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final String role;
  final String text;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const String _defaultEndpoint = 'http://100.64.0.10:8000/chat';

  final TextEditingController _endpointController =
      TextEditingController(text: _defaultEndpoint);
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = <ChatMessage>[];

  bool _sending = false;

  @override
  void dispose() {
    _endpointController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final String userMessage = _messageController.text.trim();
    if (userMessage.isEmpty || _sending) {
      return;
    }

    final Uri? endpoint = Uri.tryParse(_endpointController.text.trim());
    if (endpoint == null || !endpoint.hasScheme || !endpoint.hasAuthority) {
      setState(() {
        _messages.add(
          const ChatMessage(
            role: 'system',
            text: 'Please enter a valid VM endpoint URL.',
          ),
        );
      });
      return;
    }

    _messageController.clear();
    setState(() {
      _sending = true;
      _messages.add(ChatMessage(role: 'user', text: userMessage));
    });

    try {
      final http.Response response = await http.post(
        endpoint,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{'message': userMessage}),
      );

      final String reply = _extractReply(response);
      setState(() {
        _messages.add(ChatMessage(role: 'agent', text: reply));
      });
    } catch (error) {
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'system',
            text:
                'Failed to reach the VM endpoint over Tailscale: $error',
          ),
        );
      });
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  String _extractReply(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'VM endpoint returned HTTP ${response.statusCode}: ${response.body}';
    }

    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final Object? text =
            decoded['response'] ?? decoded['reply'] ?? decoded['message'];
        if (text is String && text.trim().isNotEmpty) {
          return text;
        }
      }
    } catch (_) {
      return response.body;
    }

    return response.body.isEmpty
        ? 'Agent replied with an empty response.'
        : response.body;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HarnessVM Chat'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _endpointController,
                decoration: const InputDecoration(
                  labelText: 'VM chat endpoint (Tailscale IP or MagicDNS)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final ChatMessage message = _messages[index];
                  final bool isUser = message.role == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${message.role}: ${message.text}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_sending,
                      decoration: const InputDecoration(
                        hintText: 'Send a message to the cloud agent…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _sendMessage,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
