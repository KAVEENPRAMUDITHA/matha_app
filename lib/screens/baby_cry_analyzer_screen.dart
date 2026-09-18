import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// =============================================================================
/// MAATHA (මාතා) - BABY CRY ANALYZER FLUTTER SCREEN (HUGGING FACE LIVE CONNECTED)
/// =============================================================================

class BabyCryAnalyzerScreen extends StatefulWidget {
  const BabyCryAnalyzerScreen({Key? key}) : super(key: key);

  @override
  State<BabyCryAnalyzerScreen> createState() => _BabyCryAnalyzerScreenState();
}

class _BabyCryAnalyzerScreenState extends State<BabyCryAnalyzerScreen>
    with SingleTickerProviderStateMixin {
  // Hugging Face Live Cloud Endpoint
  final String _hfBaseUrl = "https://yemani-maatha-cry-api.hf.space";

  late final AudioRecorder _audioRecorder;
  late AnimationController _pulseController;

  bool _isRecording = false;
  bool _isAnalyzing = false;
  int _recordSecondsRemaining = 5;
  Timer? _countdownTimer;
  String? _recordedFilePath;

  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  /// Start 5-second automatic recording
  Future<void> _startRecording() async {
    setState(() {
      _errorMessage = null;
      _analysisResult = null;
      _recordSecondsRemaining = 5;
    });

    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _recordedFilePath = '${dir.path}/baby_cry_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: _recordedFilePath!,
        );

        setState(() {
          _isRecording = true;
        });

        // 5 Seconds Countdown
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_recordSecondsRemaining > 1) {
            setState(() {
              _recordSecondsRemaining--;
            });
          } else {
            _stopAndAnalyze();
          }
        });
      } else {
        setState(() {
          _errorMessage = "මයික්‍රෆෝනය භාවිතයට අවසර (Permission) ලබා දෙන්න.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "ශබ්දය පටිගත කිරීමේ දෝෂයක්: $e";
        _isRecording = false;
      });
    }
  }

  /// Stop recording & send to Hugging Face Cloud API
  Future<void> _stopAndAnalyze() async {
    _countdownTimer?.cancel();
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
      _recordedFilePath = path;
    });

    if (path == null) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "ශබ්ද ගොනුව සුරැකීමට නොහැකි විය.";
      });
      return;
    }

    try {
      // 1. Upload audio file to Hugging Face Space
      final uploadUri = Uri.parse('$_hfBaseUrl/gradio_api/upload');
      var uploadRequest = http.MultipartRequest('POST', uploadUri);
      uploadRequest.files.add(await http.MultipartFile.fromPath('files', path));

      var streamedUpload = await uploadRequest.send().timeout(const Duration(seconds: 25));
      var uploadResponse = await http.Response.fromStream(streamedUpload);

      if (uploadResponse.statusCode != 200) {
        throw Exception("Upload failed (${uploadResponse.statusCode})");
      }

      final List<dynamic> uploadList = json.decode(utf8.decode(uploadResponse.bodyBytes));
      final String remoteUploadedPath = uploadList[0].toString();

      // 2. Trigger Model Prediction
      final predictUri = Uri.parse('$_hfBaseUrl/gradio_api/call/predict');
      final predictResponse = await http.post(
        predictUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'data': [
            {
              'path': remoteUploadedPath,
              'meta': {'_type': 'gradio.FileData'}
            }
          ]
        }),
      ).timeout(const Duration(seconds: 25));

      if (predictResponse.statusCode != 200) {
        throw Exception("Inference failed (${predictResponse.statusCode})");
      }

      final String eventId = json.decode(predictResponse.body)['event_id'];

      // 3. Fetch Final Prediction & Advice
      final resultUri = Uri.parse('$_hfBaseUrl/gradio_api/call/predict/$eventId');
      final resultResponse = await http.get(resultUri).timeout(const Duration(seconds: 30));

      if (resultResponse.statusCode == 200) {
        final bodyText = utf8.decode(resultResponse.bodyBytes);
        final lines = bodyText.split('\n');
        Map<String, dynamic>? parsedJson;

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            final dynamic decoded = json.decode(dataStr);
            if (decoded is List && decoded.length >= 3) {
              parsedJson = decoded[2] as Map<String, dynamic>;
              break;
            }
          }
        }

        if (parsedJson != null && parsedJson['status'] == 'success') {
          setState(() {
            _analysisResult = parsedJson;
            _isAnalyzing = false;
          });
        } else {
          throw Exception("ප්‍රතිඵලය සකස් කරගත නොහැකි විය.");
        }
      } else {
        throw Exception("Result error (${resultResponse.statusCode})");
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage = "සර්වර් එක සම්බන්ධ කරගත නොහැක ($e). අන්තර්ජාලය පරීක්ෂා කරන්න.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F9),
      appBar: AppBar(
        title: const Text(
          "මාතා - බිළිඳු හඬ විශ්ලේෂකය",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFE91E63),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 24),

              // Recording / Interaction Area
              _buildRecordingSection(),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null) _buildErrorCard(_errorMessage!),

              // Analysis Results
              if (_analysisResult != null) _buildResultSection(_analysisResult!),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text("🍼", style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI බිළිඳු හඬ හඳුනාගැනීම",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "දරුවා අඬන විට මයික්‍රෆෝනය ළං කර තත්පර 5ක් පටිගත කරන්න.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isRecording ? const Color(0xFFE91E63) : Colors.pink.shade50,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isAnalyzing)
            Column(
              children: [
                const CircularProgressIndicator(color: Color(0xFFE91E63)),
                const SizedBox(height: 16),
                const Text(
                  "AI විශ්ලේෂණය වෙමින් පවතී...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "කරුණාකර මොහොතක් රැඳී සිටින්න",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            )
          else if (_isRecording)
            Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.15),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE91E63).withOpacity(0.15),
                        ),
                        child: Center(
                          child: Container(
                            width: 65,
                            height: 65,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE91E63),
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  "හඬ පටිගත වෙමින් පවතී... ($_recordSecondsRemaining s)",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "දරුවාගේ ශබ්දය පැහැදිලිව ලබා දෙන්න",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            )
          else
            Column(
              children: [
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 85,
                    height: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC407A), Color(0xFFE91E63)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "හඬ පටිගත කිරීමට ඔබන්න",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "තත්පර 5ක ශබ්දය ස්වයංක්‍රීයව විශ්ලේෂණය වේ",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(Map<String, dynamic> data) {
    final pred = data['prediction'];
    final breakdown = data['breakdown'] as Map<String, dynamic>?;

    final String icon = pred['icon'] ?? '👶';
    final String titleSi = pred['title_si'] ?? '';
    final String titleEn = pred['title_en'] ?? '';
    final double confidence = (pred['confidence_pct'] as num?)?.toDouble() ?? 0.0;
    final String summarySi = pred['summary_si'] ?? '';
    final String adviceSi = pred['advice_si'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Diagnosis Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
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
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 32)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleSi,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$titleEn • විශ්වාසනීයත්වය: ${confidence.toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),

              // Summary
              const Text(
                "හේතුව:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF37474F)),
              ),
              const SizedBox(height: 4),
              Text(
                summarySi,
                style: const TextStyle(fontSize: 14, color: Color(0xFF455A64), height: 1.4),
              ),
              const SizedBox(height: 16),

              // Maternal Advice Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Color(0xFFF57F17), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "අම්මාට උපදෙස් (Maternal Advice):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFFF57F17),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      adviceSi,
                      style: const TextStyle(fontSize: 13.5, color: Color(0xFF4E342E), height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Probability Breakdown
        if (breakdown != null) ...[
          const Text(
            "සම්භාවිතා ප්‍රතිශත (Probabilities)",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          ...breakdown.entries.map((entry) {
            final val = entry.value;
            final double pct = (val['percentage'] as num?)?.toDouble() ?? 0.0;
            final String nameSi = val['name_si'] ?? entry.key;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nameSi,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "${pct.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct > 50 ? const Color(0xFFE91E63) : const Color(0xFFF48FB1),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }
}
