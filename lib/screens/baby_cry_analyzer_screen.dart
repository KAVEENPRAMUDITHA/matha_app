import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/matha_background.dart';

/// =============================================================================
/// MAATHA (මාතා) - BABY CRY ANALYZER FLUTTER SCREEN (LIVE AI INTEGRATED)
/// =============================================================================

class BabyCryAnalyzerScreen extends StatefulWidget {
  const BabyCryAnalyzerScreen({super.key});

  @override
  State<BabyCryAnalyzerScreen> createState() => _BabyCryAnalyzerScreenState();
}

class _BabyCryAnalyzerScreenState extends State<BabyCryAnalyzerScreen>
    with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 1000),
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
        _recordedFilePath =
            '${dir.path}/baby_cry_${DateTime.now().millisecondsSinceEpoch}.wav';

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

      var streamedUpload =
          await uploadRequest.send().timeout(const Duration(seconds: 25));
      var uploadResponse = await http.Response.fromStream(streamedUpload);

      if (uploadResponse.statusCode != 200) {
        throw Exception("Upload failed (${uploadResponse.statusCode})");
      }

      final List<dynamic> uploadList =
          json.decode(utf8.decode(uploadResponse.bodyBytes));
      final String remoteUploadedPath = uploadList[0].toString();

      // 2. Trigger Model Prediction
      final predictUri = Uri.parse('$_hfBaseUrl/gradio_api/call/predict');
      final predictResponse = await http
          .post(
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
          )
          .timeout(const Duration(seconds: 25));

      if (predictResponse.statusCode != 200) {
        throw Exception("Inference failed (${predictResponse.statusCode})");
      }

      final String eventId = json.decode(predictResponse.body)['event_id'];

      // 3. Fetch Final Prediction & Advice
      final resultUri =
          Uri.parse('$_hfBaseUrl/gradio_api/call/predict/$eventId');
      final resultResponse =
          await http.get(resultUri).timeout(const Duration(seconds: 30));

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
        _errorMessage =
            "සර්වර් එක සම්බන්ධ කරගත නොහැක ($e). අන්තර්ජාලය පරීක්ෂා කරන්න.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MathaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            "බිළිඳු හඬ විශ්ලේෂකය / CRY AI",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Color(0xFF1565C0),
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1565C0),
                size: 16,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _buildHeaderCard(),
              const SizedBox(height: 20),

              // Recording / Interaction Area
              _buildRecordingSection(),
              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null) _buildErrorCard(_errorMessage!),

              // Analysis Results
              if (_analysisResult != null)
                _buildResultSection(_analysisResult!),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF00B0FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("🍼🎙️", style: TextStyle(fontSize: 26)),
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
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "දරුවා අඬන විට මයික්‍රෆෝනය ළං කර තත්පර 5ක් පටිගත කරන්න.",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: _isRecording ? const Color(0xFFE91E63) : Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _isRecording
                ? const Color(0xFFE91E63).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isAnalyzing)
            Column(
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: Color(0xFFE91E63),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "AI විශ්ලේෂණය වෙමින් පවතී...",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Hugging Face AI මාදිලිය ශබ්ද තරංග පරීක්ෂා කරයි",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ],
            )
          else if (_isRecording)
            Column(
              children: [
                // Live Sound Wave Visualizer
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(11, (i) {
                            final factor = (sin((_pulseController.value * 2 * 3.1415) + (i * 0.6)) + 1) / 2;
                            final height = 14.0 + (factor * 36.0);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 5,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00E5FF), Color(0xFFE91E63)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 22),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 95,
                              height: 95,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE91E63).withValues(alpha: 0.15 + (_pulseController.value * 0.15)),
                              ),
                            ),
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF4081), Color(0xFFE91E63)],
                                ),
                              ),
                              child: const Icon(Icons.mic, color: Colors.white, size: 38),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  "හඬ පටිගත වෙමින් පවතී... ($_recordSecondsRemaining s)",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "දරුවාගේ ශබ්දය මයික්‍රෆෝනයට පැහැදිලිව ලබා දෙන්න",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ],
            )
          else
            Column(
              children: [
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF80AB), Color(0xFFE91E63), Color(0xFF880E4F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "හඬ පටිගත කිරීමට ඔබන්න",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "තත්පර 5ක ශබ්දය ස්වයංක්‍රීයව විශ්ලේෂණය වේ",
                  style: TextStyle(fontSize: 12.5, color: Colors.grey),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
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
    final double confidence =
        (pred['confidence_pct'] as num?)?.toDouble() ?? 0.0;
    final String summarySi = pred['summary_si'] ?? '';
    final String adviceSi = pred['advice_si'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Diagnosis Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE91E63).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(icon, style: const TextStyle(fontSize: 34)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleSi,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$titleEn • නිවැරදිභාවය: ${confidence.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
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
                "හේතුව (Diagnosis):",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summarySi,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF455A64),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Maternal Advice Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_rounded, color: Color(0xFFF57F17), size: 20),
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
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF4E342E),
                        height: 1.5,
                      ),
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
            "සම්භාවිතා ප්‍රතිශත (AI Probability Breakdown)",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          ...breakdown.entries.map((entry) {
            final val = entry.value;
            final double pct = (val['percentage'] as num?)?.toDouble() ?? 0.0;
            final String nameSi = val['name_si'] ?? entry.key;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
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
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${pct.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct / 100.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct > 50 ? const Color(0xFFE91E63) : const Color(0xFFF48FB1),
                      ),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
