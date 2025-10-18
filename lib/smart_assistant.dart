import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}
bool _isListening = false;
class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageBase64;
  final bool isLoading;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageBase64,
    this.isLoading = false,
  });
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isLoading = false;

  final String apiUrl = 'https://esha89-fashion-chat-api.hf.space/chatbot';
  final String speakUrl = 'https://esha89-fashion-chat-api.hf.space/speak';
  final String listenUrl = 'https://esha89-fashion-chat-api.hf.space/voicebot';


  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _isLoading = true;
      _messages.add(ChatMessage(
        text: "Generating response...",
        isUser: false,
        isLoading: true,
      ));
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"prompt": message}),
      );

      _messages.removeWhere((msg) => msg.isLoading);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botReply = data['answer'] ?? 'No response';
        final imageBase64 = data['generated_image'];

        setState(() {
          _messages.add(ChatMessage(
            text: botReply,
            isUser: false,
            imageBase64: imageBase64,
          ));
        });

      //  _playBotSpeech(botReply);
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "Error: ${response.statusCode}",
            isUser: false,
          ));
        });
      }
    } catch (e) {
      print("Error during request: $e");
      _messages.removeWhere((msg) => msg.isLoading);
      setState(() {
        _messages.add(ChatMessage(text: "Connection error.", isUser: false));
      });
    } finally {
      _isLoading = false;
      _controller.clear();
    }
  }

  Future<void> _playBotSpeech(String text) async {
    try {
      final response = await http.post(
        Uri.parse(speakUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final base64Audio = data['audio'];

        if (base64Audio != null) {
          Uint8List bytes = base64Decode(base64Audio);
          final uri = Uri.dataFromBytes(bytes, mimeType: 'audio/mp3');
          await _audioPlayer.setUrl(uri.toString());
          await _audioPlayer.play();
        }
      } else {
        print("Speech request failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Speech playback error: $e");
    }
  }

  Future<void> listenAndSend() async {
    if (_isListening) return;

    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "⚠️ Microphone permission denied.",
            isUser: false,
          ));
        });
        return;
      }
    }

    final record = AudioRecorder();
    if (!await record.hasPermission()) {
      setState(() {
        _messages.add(ChatMessage(
          text: "⚠️ Unable to access microphone.",
          isUser: false,
        ));
      });
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/recorded_audio.wav';

      setState(() {
        _isListening = true;
        _messages.add(ChatMessage(
          text: "🎙️ Listening...",
          isUser: false,
          isLoading: true,
        ));
      });

      // Start recording to a file
      await record.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          noiseSuppress: true,
        ),
        path: path,
      );

      // Record for fixed duration (or implement silence detection)
      await Future.delayed(Duration(seconds: 7));

      await record.stop();

      setState(() {
        _isListening = false;
        _messages.removeWhere((msg) => msg.text == "🎙️ Listening...");
      });

      File audioFile = File(path);
      if (!(await audioFile.exists()) || (await audioFile.length() == 0)) {
        _messages.add(ChatMessage(
          text: "⚠️ Audio file is empty.",
          isUser: false,
        ));
        return;
      }

      var request = http.MultipartRequest('POST', Uri.parse(listenUrl));
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("Response: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recognizedText = data['transcript']?.toString().trim();

        if (recognizedText != null && recognizedText.isNotEmpty) {
          await sendMessage(recognizedText);
        } else {
          _messages.add(ChatMessage(
            text: "⚠️ No speech detected.",
            isUser: false,
          ));
        }
      } else {
        _messages.add(ChatMessage(
          text: "❌ Listening failed: ${response.statusCode}",
          isUser: false,
        ));
      }
    } catch (e, stack) {
      print("🎙️ Error: $e");
      print(stack);
      _messages.add(ChatMessage(
        text: "⚠️ Error while listening: $e",
        isUser: false,
      ));
    }
  }


  Widget buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isUser ? Colors.pink[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isLoading)
              Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text("Thinking..."),
                ],
              )
            else ...[
              if (msg.imageBase64 != null && msg.imageBase64!.length > 100)
                Column(
                  children: [
                    Builder(
                      builder: (context) {
                        try {
                          Uint8List bytes = base64Decode(msg.imageBase64!);
                          return Image.memory(
                            bytes,
                            height: 200,
                            width: 200,
                            fit: BoxFit.cover,
                          );
                        } catch (e) {
                          return Text("⚠️ Failed to decode image.");
                        }
                      },
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(child: Text(msg.text)),
                  if (!msg.isUser)
                    IconButton(
                      icon: Icon(Icons.volume_up),
                      onPressed: () => _playBotSpeech(msg.text),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fashion Chatbot')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => buildMessage(_messages[index]),
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.mic),
                  onPressed: listenAndSend,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: sendMessage,
                    decoration: InputDecoration.collapsed(
                      hintText: "Ask me about fashion...",
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
