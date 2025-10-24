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
  final bool isAudio;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imageBase64,
    this.isLoading = false,
    this.isAudio = false,
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

    // Add typed message and clear input
    setState(() {
      _messages.add(ChatMessage(text: message, isUser: true));
      _controller.clear();
      _isLoading = true;
      _messages.add(ChatMessage(
        text: "Thinking...",
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

        // Optional: play bot speech
        //_playBotSpeech(botReply);
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

      // Show voice message bubble immediately
      setState(() {
        _isListening = true;
        _messages.add(ChatMessage(
          text: "🎤 Voice message sent",
          isUser: true,
          isAudio: true,
          isLoading: true,
        ));
      });

      await record.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          noiseSuppress: true,
        ),
        path: path,
      );

      await Future.delayed(Duration(seconds: 7));
      await record.stop();

      setState(() {
        _isListening = false;
        _messages.removeWhere((msg) => msg.isLoading && msg.isAudio);
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

      // Add "Thinking..." bubble
      setState(() {
        _messages.add(ChatMessage(
          text: "Thinking...",
          isUser: false,
          isLoading: true,
        ));
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _messages.removeWhere((msg) => msg.isLoading && !msg.isAudio);

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

  Widget buildMessage(ChatMessage msg, double width) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: width * 0.015),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: msg.isUser ? Colors.pink[100] : Colors.grey[200],
      child: Padding(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.isLoading)
              Row(
                children: [
                  SizedBox(
                    width: width * 0.04,
                    height: width * 0.04,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: width * 0.02),
                  Text("Thinking...", style: TextStyle(fontSize: width * 0.035)),
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
                            height: width * 0.5,
                            width: width * 0.5,
                            fit: BoxFit.cover,
                          );
                        } catch (e) {
                          return Text("⚠️ Failed to decode image.", style: TextStyle(fontSize: width * 0.035));
                        }
                      },
                    ),
                    SizedBox(height: width * 0.02),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.isAudio)
                    Icon(Icons.mic, size: width * 0.06, color: Colors.black54),
                  SizedBox(width: msg.isAudio ? width * 0.02 : 0),
                  Expanded(child: Text(msg.text, style: TextStyle(fontSize: width * 0.035))),
                  if (!msg.isUser)
                    IconButton(
                      icon: Icon(Icons.volume_up, size: width * 0.06),
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
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final fontSize = screenWidth * 0.045;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(
          icon: Image.asset(
            "assets/images/white_back_btn.png",
            height: 28,
            width: 28,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Fashion Chatbot",
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Container(
          width: screenWidth * 0.99,
          height: screenHeight * 0.99,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
          child: Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                    child: Text("Your chat will appear here",
                        style: TextStyle(fontSize: fontSize)))
                    : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      buildMessage(_messages[index], screenWidth),
                ),
              ),
              Divider(),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.mic, size: screenWidth * 0.08),
                    onPressed: listenAndSend,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: sendMessage,
                      decoration: InputDecoration(
                        hintText: "Ask me about fashion...",
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: fontSize * 0.8,
                            vertical: fontSize * 0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, size: screenWidth * 0.08),
                    onPressed: () => sendMessage(_controller.text),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
