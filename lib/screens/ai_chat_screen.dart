import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:intl/intl.dart'; // Only needed if you format dates from context for display, not for current logic

// ChatMessage class
class ChatMessage {
  final String text;
  final bool isUserMessage;
  ChatMessage({required this.text, required this.isUserMessage});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  // !!! --- REPLACE WITH YOUR ACTUAL GROQ API KEY --- !!!
  // !!! --- AND CONSIDER A MORE SECURE WAY TO STORE IT LATER --- !!!
  final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  // !!! ---------------------------------------------- !!!

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = View.of(context).viewInsets.bottom;
    // A small delay helps ensure layout is complete before scrolling
    if (bottomInset > 0.0 && _messages.isNotEmpty) {
      _scrollToBottom(delayMilliseconds: 100);
    }
  }

  void _scrollToBottom({int delayMilliseconds = 50}) {
    Future.delayed(Duration(milliseconds: delayMilliseconds), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _getRecentLogContext() async {
    User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return "";

    List<String> contextParts = [];
    try {
      QuerySnapshot sleepSnapshot = await _firestore
          .collection('users').doc(currentUser.uid).collection('wellnessLogs')
          .where('logType', isEqualTo: 'sleep').orderBy('timestamp', descending: true).limit(1).get();
      if (sleepSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> sleepData = sleepSnapshot.docs.first.data() as Map<String, dynamic>;
        String sleepValue = sleepData['value']?.toString() ?? 'N/A';
        String sleepUnit = sleepData['unit']?.toString() ?? '';
        String sleepQuality = sleepData['quality']?.toString() ?? 'N/A';
        if (sleepQuality.isNotEmpty && sleepQuality != 'N/A') {
          contextParts.add("Last sleep: $sleepValue $sleepUnit (Quality: $sleepQuality).");
        } else {
          contextParts.add("Last sleep: $sleepValue $sleepUnit.");
        }
      }

      QuerySnapshot moodSnapshot = await _firestore
          .collection('users').doc(currentUser.uid).collection('wellnessLogs')
          .where('logType', isEqualTo: 'mood').orderBy('timestamp', descending: true).limit(1).get();
      if (moodSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> moodData = moodSnapshot.docs.first.data() as Map<String, dynamic>;
        String moodValue = moodData['value']?.toString() ?? 'N/A';
        contextParts.add("Recent mood: $moodValue.");
      }
    } catch (e) {
      print("Error fetching log context: $e");
    }

    if (contextParts.isEmpty) {
      return ""; // Return empty string instead of "No recent wellness data..."
                 // So we don't send it as system message if there's no real context
    }
    return "User's recent context: " + contextParts.join(" ");
  }

  Future<void> _sendMessageToGroq(String userMessageText) async {
    if ( _groqApiKey.isEmpty) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "Error: Groq API Key not configured for this screen.",
            isUserMessage: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Groq API Key not set in AiChatScreen.dart!"), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String logContext = await _getRecentLogContext();
    const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";
    List<Map<String, String>> groqMessages = [];

    if (logContext.isNotEmpty) {
        groqMessages.add({"role": "system", "content": logContext});
    }

    // Add previous chat messages to groqMessages, ensuring the current user's message is last
    for (int i = 0; i < _messages.length; i++) {
        final msg = _messages[i];
        // Check if it's the last message and it's the user's current input, to avoid duplication if already handled
        // The current userMessageText is the one we want to send now.
        // _messages already contains this as the last item due to optimistic update in _handleSubmitted.
         if (msg.isUserMessage || (!msg.isUserMessage && !msg.text.startsWith("Error:") && !msg.text.startsWith("Failed to connect:"))) {
            groqMessages.add({
              "role": msg.isUserMessage ? "user" : "assistant",
              "content": msg.text
            });
         }
    }


    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messages": groqMessages,
          "model": "llama3-8b-8192", // Ensure this model is available
          "temperature": 0.7,
          "max_tokens": 300,
        }),
      );

      String aiResponseText;
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          aiResponseText = responseData['choices'][0]['message']['content'].trim();
        } else {
          aiResponseText = "Could not parse AI response.";
          print("Full Groq Response: $responseData");
        }
      } else {
        aiResponseText = "Error from Groq API: ${response.statusCode}\n${response.body}";
        print("Error from Groq API: ${response.statusCode}");
        print("Error body: ${response.body}");
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: aiResponseText, isUserMessage: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }

    } catch (e) {
      print("Exception making Groq API call: $e");
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: "Failed to connect: $e", isUserMessage: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    final String messageText = text.trim();
    _textController.clear();

    ChatMessage userMessage = ChatMessage(text: messageText, isUserMessage: true);
    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();
    _sendMessageToGroq(messageText); // Pass the trimmed message text
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF00B894)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C9A7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Health Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your personal wellness companion',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ask me about fitness tips, nutrition advice, or wellness guidance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.fitness_center, 'label': 'Workout Tips', 'query': 'Give me a quick workout tip'},
      {'icon': Icons.restaurant, 'label': 'Nutrition', 'query': 'Share a healthy eating tip'},
      {'icon': Icons.bedtime, 'label': 'Sleep Health', 'query': 'How can I improve my sleep?'},
      {'icon': Icons.sentiment_satisfied, 'label': 'Mental Health', 'query': 'Give me stress management advice'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return GestureDetector(
                onTap: () => _handleSubmitted(action['query'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9A7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00C9A7).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        size: 16,
                        color: const Color(0xFF00C9A7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        action['label'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00C9A7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUserMessage) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C9A7), Color(0xFF00B894)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                gradient: message.isUserMessage
                    ? const LinearGradient(
                        colors: [Color(0xFF00C9A7), Color(0xFF00B894)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: message.isUserMessage ? null : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUserMessage ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: message.isUserMessage ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUserMessage 
                        ? const Color(0xFF00C9A7).withOpacity(0.2)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  color: message.isUserMessage ? Colors.white : const Color(0xFF2D3748),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUserMessage) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C9A7), Color(0xFF00B894)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AI is thinking',
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF00C9A7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C9A7), Color(0xFF00B894)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Row(
              children: [
                Icon(Icons.psychology, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'AI Health Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: _messages.isEmpty ? 2 : _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (_messages.isEmpty) {
                  if (index == 0) return _buildWelcomeCard();
                  if (index == 1) return _buildQuickActions();
                }
                
                if (index < _messages.length) {
                  return _buildMessage(_messages[index]);
                } else if (_isLoading) {
                  return _buildTypingIndicator();
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 10,
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFF00C9A7).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _isLoading ? null : _handleSubmitted,
                        decoration: InputDecoration(
                          hintText: _isLoading ? "AI is thinking..." : "Ask about your health...",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                        enabled: !_isLoading,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? LinearGradient(
                              colors: [Colors.grey[300]!, Colors.grey[400]!],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF00C9A7), Color(0xFF00B894)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: _isLoading 
                              ? Colors.transparent 
                              : const Color(0xFF00C9A7).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}