import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(DoctorAIApp());

class DoctorAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor AI',
      theme: ThemeData.dark(),
      home: AnimeCompanionWorkspace(),
    );
  }
}

class AnimeCompanionWorkspace extends StatefulWidget {
  @override
  _AnimeCompanionWorkspaceState createState() => _AnimeCompanionWorkspaceState();
}

class _AnimeCompanionWorkspaceState extends State<AnimeCompanionWorkspace> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  FlutterTts _flutterTts = FlutterTts();
  stt.SpeechToText _speech = stt.SpeechToText();
  
  String _speechText = "হ্যালো! আমি আপনার অ্যানিমে ডক্টর অ্যাসিস্ট্যান্ট। কথা বলতে মাইক্রোফোন বাটনটি চাপুন।";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // ক্যারেক্টারের লাইভ অ্যানিমে মুভমেন্ট ও ব্রিদিং অ্যানিমেশন কন্ট্রোলার
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _initVoiceSystem();
  }

  void _initVoiceSystem() async {
    await _flutterTts.setLanguage("bn-BD");
    await _flutterTts.setSpeechRate(0.5);
  }

  // গুগলের ফ্রি এআই ব্যাকএন্ড (Google Gemini API কানেকশন)
  Future<void> _fetchAIResponse(String userInput) async {
    setState(() {
      _speechText = "ডক্টর চিন্তা করছেন...";
    });

    try {
      final url = Uri.parse('https://googleapis.com');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': 'You are an Anime Boy Doctor Assistant. Respond nicely in Bengali to: $userInput'}]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiReply = data['candidates']['content']['parts']['text'];
        
        setState(() {
          _speechText = aiReply;
        });
        
        await _flutterTts.speak(aiReply);
      }
    } catch (e) {
      setState(() {
        _speechText = "কানেকশন সমস্যা। দয়া করে ইন্টারনেট চেক করুন।";
      });
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          if (val.finalResult) {
            setState(() => _isListening = false);
            _fetchAIResponse(val.recognizedWords);
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Doctor AI - Anime System")),
      body: Column(
        children: [
          // অ্যানিমে ক্যারেক্টার স্টেজ ও লাইভ মোশন
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animationController.value * -12),
                    child: Container(
                      width: 250,
                      height: 380,
                      child: Text(
                        "👨‍🔬", // এখানে আপনার আসল অ্যানিমে বয়ের ইমেজ ফাইলটি লোড হবে
                        style: TextStyle(fontSize: 120),
                        textAlign: Center,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // এআই সংলাপ বক্স
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(12)),
              child: Text(_speechText, style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          // ভয়েস কন্ট্রোল বাটন
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: FloatingActionButton(
              onPressed: _listen,
              backgroundColor: _isListening ? Colors.green : Colors.blue,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
