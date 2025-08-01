import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebaseproject2/screens/signin_screnn.dart';
import 'package:firebaseproject2/screens/add_wellness_log_screen.dart';
import 'package:firebaseproject2/screens/ai_chat_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  User? _currentUser;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final String _groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  String _aiResponse = "Tap the button below to get your personalized AI fitness tip! 🏃‍♂️💪";

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    
    // Initialize animation controller for pulse effect
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _getFitnessTipFromGroq() async {
    if (_groqApiKey.isEmpty) {
      setState(() {
        _aiResponse = "Error: Groq API Key not set. Please set it in the code.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Groq API Key not set in HomeScreen.dart!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _aiResponse = "🤖 Getting your personalized tip from AI...";
    });

    const String apiUrl = "https://api.groq.com/openai/v1/chat/completions";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "user",
              "content": "Suggest one quick and easy fitness tip for a beginner."
            }
          ],
          "model": "llama3-8b-8192",
          "temperature": 0.7,
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['choices'] != null &&
            responseData['choices'].isNotEmpty &&
            responseData['choices'][0]['message'] != null &&
            responseData['choices'][0]['message']['content'] != null) {
          setState(() {
            _aiResponse = "💡 " + responseData['choices'][0]['message']['content'].trim();
          });
        } else {
          setState(() {
            _aiResponse = "❌ Could not parse AI response. Check response structure.";
          });
          print("Full Groq Response: $responseData");
        }
      } else {
        setState(() {
          _aiResponse = "❌ Error from Groq API: ${response.statusCode}\n${response.body}";
        });
        print("Error from Groq API: ${response.statusCode}");
        print("Error body: ${response.body}");
      }
    } catch (e) {
      setState(() {
        _aiResponse = "❌ Failed to connect to Groq API: $e";
      });
      print("Exception making Groq API call: $e");
    }
  }

  Widget _buildLogItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String logType = data['logType'] as String? ?? 'Unknown Type';
    DateTime timestamp = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedDate = DateFormat('EEE, MMM d, yyyy - hh:mm a').format(timestamp);
    String notes = data['notes'] as String? ?? '';
    String summary = _getLogTypeName(logType);
    
    if (data.containsKey('value')) {
      summary += ' • ${data['value']}';
      if (data.containsKey('unit')) {
        summary += ' ${data['unit']}';
      }
    } else if (logType == 'bloodPressure' && data.containsKey('systolic') && data.containsKey('diastolic')) {
      summary += ' • ${data['systolic']}/${data['diastolic']} ${data['unit'] ?? 'mmHg'}';
    } else if (logType == 'medicationIntake' && data.containsKey('medicationName')) {
      summary += ' • ${data['medicationName']} (${data['dosage'] ?? ''})';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 8,
        shadowColor: _getColorForLogType(logType).withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getColorForLogType(logType).withOpacity(0.1),
                _getColorForLogType(logType).withOpacity(0.05),
              ],
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorForLogType(logType),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: _getColorForLogType(logType).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getIconForLogType(logType),
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              summary,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: $notes',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ],
                if (data.containsKey('category') && data['category'] != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getColorForLogType(logType).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${data['category']}',
                      style: TextStyle(
                        color: _getColorForLogType(logType),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }

  String _getLogTypeName(String logType) {
    switch (logType) {
      case 'sleep': return '😴 Sleep';
      case 'mood': return '😊 Mood';
      case 'water': return '💧 Water';
      case 'exercise': return '🏃‍♀️ Exercise';
      case 'weight': return '⚖️ Weight';
      case 'bloodPressure': return '🩺 Blood Pressure';
      case 'heartRate': return '❤️ Heart Rate';
      case 'medicationIntake': return '💊 Medication';
      case 'dietLog': return '🍎 Diet';
      case 'mentalHealthCheck': return '🧠 Mental Health';
      default: return '📝 Health Log';
    }
  }

  IconData _getIconForLogType(String logType) {
    switch (logType) {
      case 'sleep': return Icons.nights_stay_outlined;
      case 'mood': return Icons.sentiment_satisfied_alt_outlined;
      case 'water': return Icons.water_drop_outlined;
      case 'exercise': return Icons.fitness_center_outlined;
      case 'weight': return Icons.monitor_weight_outlined;
      case 'bloodPressure': return Icons.thermostat_auto_outlined;
      case 'heartRate': return Icons.favorite_border_outlined;
      case 'medicationIntake': return Icons.medication_outlined;
      case 'dietLog': return Icons.restaurant_outlined;
      case 'mentalHealthCheck': return Icons.psychology_outlined;
      default: return Icons.notes_outlined;
    }
  }

  Color _getColorForLogType(String logType) {
    switch (logType) {
      case 'sleep': return const Color(0xFF6366F1);
      case 'mood': return const Color(0xFFEC4899);
      case 'water': return const Color(0xFF06B6D4);
      case 'exercise': return const Color(0xFF10B981);
      case 'weight': return const Color(0xFF8B5CF6);
      case 'bloodPressure': return const Color(0xFFEF4444);
      case 'heartRate': return const Color(0xFFF59E0B);
      case 'medicationIntake': return const Color(0xFF3B82F6);
      case 'dietLog': return const Color(0xFF84CC16);
      case 'mentalHealthCheck': return const Color(0xFF14B8A6);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF10B981), // Green from theme
                    Color(0xFF06B6D4), // Cyan
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                title: const Text(
                  "Health Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF06B6D4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  ),
                  tooltip: 'AI Chat',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AiChatScreen()),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout, color: Colors.white),
                  ),
                  onPressed: () {
                    FirebaseAuth.instance.signOut().then((value) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                          (route) => false);
                    });
                  },
                ),
              ),
            ],
          ),
          
          // AI Tip Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Welcome card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF0FDF4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.waving_hand,
                                color: Color(0xFF10B981),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome Back!",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  Text(
                                    "Ready to boost your health today?",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // AI Tip Button with animation
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                                  ),
                                  icon: const Icon(Icons.psychology_outlined, size: 24),
                                  label: const Text(
                                    "Get AI Fitness Tip",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: _getFitnessTipFromGroq,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // AI Response Container
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF06B6D4).withOpacity(0.1),
                                const Color(0xFF10B981).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06B6D4).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Color(0xFF06B6D4),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SelectableText(
                                  _aiResponse,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Wellness Logs Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.history, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Recent Wellness Logs",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Wellness Logs List
          _currentUser == null
              ? const SliverToBoxAdapter(
                  child: Center(child: Text("Not logged in.")),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser!.uid)
                      .collection('wellnessLogs')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      print('Firestore Error: ${snapshot.error}');
                      return SliverToBoxAdapter(
                        child: Center(child: Text('Error: ${snapshot.error}')),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.add_circle_outline,
                                  size: 48,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No wellness logs yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first log!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildLogItem(snapshot.data!.docs[index]);
                        },
                        childCount: snapshot.data!.docs.length,
                      ),
                    );
                  },
                ),
          
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      
      // Enhanced Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddWellnessLogScreen()),
            );
          },
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          label: const Text(
            'Add Log',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          icon: const Icon(Icons.add, size: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}