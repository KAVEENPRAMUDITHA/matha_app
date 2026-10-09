import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/matha_background.dart';

class PostpartumRecordsScreen extends StatefulWidget {
  final String motherId;

  const PostpartumRecordsScreen({super.key, required this.motherId});

  @override
  State<PostpartumRecordsScreen> createState() => _PostpartumRecordsScreenState();
}

class _PostpartumRecordsScreenState extends State<PostpartumRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  Map<String, dynamic>? _deliverySummary;
  Map<int, Map<String, dynamic>> _homeVisits = {};
  
  final List<int> _visitDays = [1, 3, 5, 10, 14, 28, 42];

  List<Map<String, dynamic>> _pregnanciesList = [];
  String? _selectedPregnancyId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load all pregnancies
      QuerySnapshot pregSnap = await FirebaseFirestore.instance
          .collection('mothers')
          .doc(widget.motherId)
          .collection('pregnancies')
          .get();
          
      _pregnanciesList = pregSnap.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      }).toList();
      
      // Sort pregnancies descending by date
      _pregnanciesList.sort((a, b) {
        Timestamp? tA = a['createdAt'] ?? a['registeredDate'] ?? a['lmp'];
        Timestamp? tB = b['createdAt'] ?? b['registeredDate'] ?? b['lmp'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      if (_pregnanciesList.isNotEmpty && _selectedPregnancyId == null) {
        _selectedPregnancyId = _pregnanciesList.first['id'];
      }
      
      await _loadPregnancyData(_selectedPregnancyId);

    } catch (e) {
      debugPrint("Error loading records: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPregnancyData(String? pregId) async {
    _deliverySummary = null;
    _homeVisits = {};

    try {
      DocumentSnapshot mDoc = await FirebaseFirestore.instance.collection('mothers').doc(widget.motherId).get();

      if (pregId != null) {
        // Try new path
        DocumentSnapshot delDoc = await FirebaseFirestore.instance
            .collection('mothers')
            .doc(widget.motherId)
            .collection('pregnancies')
            .doc(pregId)
            .collection('postpartum')
            .doc('delivery_summary')
            .get();
        if (delDoc.exists) {
          _deliverySummary = delDoc.data() as Map<String, dynamic>?;
        }
        
        QuerySnapshot visitsSnap = await FirebaseFirestore.instance
            .collection('mothers')
            .doc(widget.motherId)
            .collection('pregnancies')
            .doc(pregId)
            .collection('phm_home_visits')
            .get();
            
        Map<int, Map<String, dynamic>> loadedVisits = {};
        for (var doc in visitsSnap.docs) {
          final vData = doc.data() as Map<String, dynamic>;
          int day = int.tryParse(vData['visitDay']?.toString() ?? '') ?? 0;
          if (day > 0) loadedVisits[day] = vData;
        }
        _homeVisits = loadedVisits;
      }

      // Fallbacks for legacy structure if not found in new path
      if (_deliverySummary == null) {
        DocumentSnapshot delDoc = await FirebaseFirestore.instance
            .collection('mothers')
            .doc(widget.motherId)
            .collection('postpartum')
            .doc('delivery_summary')
            .get();
        if (delDoc.exists) {
          _deliverySummary = delDoc.data() as Map<String, dynamic>?;
        } else if (mDoc.exists) {
          final mData = mDoc.data() as Map<String, dynamic>?;
          _deliverySummary = mData?['deliverySummary'] as Map<String, dynamic>?;
        }
      }

      if (_homeVisits.isEmpty) {
        QuerySnapshot visitsSnap = await FirebaseFirestore.instance
            .collection('mothers')
            .doc(widget.motherId)
            .collection('phm_home_visits')
            .get();
        Map<int, Map<String, dynamic>> loadedVisits = {};
        for (var doc in visitsSnap.docs) {
          final vData = doc.data() as Map<String, dynamic>;
          int day = int.tryParse(vData['visitDay']?.toString() ?? '') ?? 0;
          if (day > 0) loadedVisits[day] = vData;
        }
        _homeVisits = loadedVisits;
      }
    } catch (e) {
      debugPrint("Error loading pregnancy data: $e");
    }
  }

  String _getPregnancyLabel(Map<String, dynamic> p, int index) {
    String dateStr = '';
    if (p['lmp'] != null) {
      DateTime lmp = (p['lmp'] as Timestamp).toDate();
      dateStr = 'LMP: ${DateFormat('yyyy-MM-dd').format(lmp)}';
    } else if (p['registeredDate'] != null) {
      DateTime reg = (p['registeredDate'] as Timestamp).toDate();
      dateStr = 'Reg: ${DateFormat('yyyy-MM-dd').format(reg)}';
    } else {
      dateStr = 'Unknown Date';
    }
    return "ගර්භණී වාර්තාව ${_pregnanciesList.length - index} ($dateStr)";
  }

  @override
  Widget build(BuildContext context) {
    return MathaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'ප්‍රසූත සහ පසුප්‍රසව වාර්තා',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.w900,
              color: Color(0xFF1565C0),
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1565C0)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
            : Column(
                children: [
                  if (_pregnanciesList.length > 1)
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPregnancyId,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down_circle, color: Color(0xFFE65100)),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                          items: _pregnanciesList.asMap().entries.map((entry) {
                            int idx = entry.key;
                            var p = entry.value;
                            return DropdownMenuItem<String>(
                              value: p['id'],
                              child: Text(_getPregnancyLabel(p, idx)),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null && val != _selectedPregnancyId) {
                              setState(() {
                                _selectedPregnancyId = val;
                                _isLoading = true;
                              });
                              await _loadPregnancyData(val);
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  Container(
                    color: Colors.white.withValues(alpha: 0.9),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFFE65100),
                      indicatorWeight: 3.5,
                      labelColor: const Color(0xFFBF360C),
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      tabs: const [
                        Tab(icon: Icon(Icons.child_care_rounded, size: 20), text: 'ප්‍රසූත සාරාංශය'),
                        Tab(icon: Icon(Icons.home_work_outlined, size: 20), text: 'PHM නිවාස පරීක්ෂණ'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDeliveryTab(),
                        _buildVisitsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDeliveryTab() {
    if (_deliverySummary == null || _deliverySummary!.isEmpty) {
      return const Center(
        child: Text(
          "ප්‍රසූත වාර්තා තවමත් ඇතුළත් කර නොමැත.",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    final data = _deliverySummary!;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildInfoCard(
          "මූලික තොරතුරු (Baseline)",
          Icons.info_outline_rounded,
          [
            _buildDetailRow("ප්‍රසූත දිනය", data['deliveryDate']?.toString() ?? '-'),
            _buildDetailRow("උපත් බර", "${data['birthWeight']?.toString() ?? '-'} g"),
            _buildDetailRow("ප්‍රසූතියේදී ගර්භණී කාලය (POA)", "${data['poa']?.toString() ?? '-'} සති"),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          "ප්‍රසූත තොරතුරු (Delivery Details)",
          Icons.local_hospital_rounded,
          [
            _buildDetailRow("ප්‍රසූත ක්‍රමය", data['modeOfDelivery']?.toString() ?? '-'),
            _buildDetailRow("ළදරුවාගේ ස්ත්‍රී/පුරුෂ භාවය", data['babySex']?.toString() ?? '-'),
            _buildDetailRow("ප්‍රතිඵලය", data['birthOutcome']?.toString() ?? '-'),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          "සායනික මැදිහත්වීම් (Interventions)",
          Icons.medical_services_outlined,
          [
            _buildDetailRow("Episiotomy/Tear", data['episiotomy'] == true ? "ඔව්" : "නැත"),
            _buildDetailRow("Vitamin A Megadose", data['vitAMegadose'] == true ? "ලබා දී ඇත" : "නැත"),
            _buildDetailRow("Anti-D එන්නත", data['antiDGiven'] == true ? "ලබා දී ඇත" : "නැත"),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitsTab() {
    if (_homeVisits.isEmpty) {
      return const Center(
        child: Text(
          "නිවාස පරීක්ෂණ වාර්තා තවමත් නොමැත.",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: _visitDays.map((day) {
        final visitData = _homeVisits[day];
        final bool isDone = visitData != null;
        final bool hasIssue = isDone &&
            (visitData['breastProblems'] == 'Abnormal' ||
                visitData['abnormalDischarge'] == 'Abnormal' ||
                visitData['excessBleeding'] == 'Abnormal');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasIssue ? Colors.red.shade300 : (isDone ? Colors.orange.shade300 : Colors.grey.shade200),
              width: isDone ? 1.5 : 1.0,
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: ExpansionTile(
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDone ? (hasIssue ? Colors.red.shade50 : Colors.orange.shade50) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDone ? (hasIssue ? Colors.red.shade300 : const Color(0xFFE65100)) : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      "D$day",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDone ? (hasIssue ? Colors.red.shade800 : const Color(0xFFE65100)) : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'දින $day නිවාස පරීක්ෂාව',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (isDone)
                        Text(
                          'දිනය: ${visitData['visitDateStr'] ?? '-'} ${hasIssue ? '• ⚠️ අසාමාන්‍යයි' : '• සාමාන්‍යයි'}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: hasIssue ? Colors.red.shade700 : Colors.green.shade700),
                        )
                      else
                        Text(
                          'තවමත් පරීක්ෂාව සිදුකර නැත',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            children: isDone
                ? [
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildDetailRow("තනපුඩු / ළැම ගැටලු", visitData['breastProblems'] == 'Abnormal' ? "⚠️ අසාමාන්‍යයි" : "✅ සාමාන්‍යයි"),
                          _buildDetailRow("යෝනි ශ්‍රාවයන්", visitData['abnormalDischarge'] == 'Abnormal' ? "⚠️ අසාමාන්‍යයි" : "✅ සාමාන්‍යයි"),
                          _buildDetailRow("රුධිරය පිටවීම", visitData['excessBleeding'] == 'Abnormal' ? "⚠️ අධිකයි" : "✅ සාමාන්‍යයි"),
                          if (visitData['notes'] != null && visitData['notes'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("සටහන: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                  Expanded(
                                    child: Text(visitData['notes'].toString(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ),
                                ],
                              ),
                            )
                        ],
                      ),
                    )
                  ]
                : [],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE65100), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFBF360C)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
