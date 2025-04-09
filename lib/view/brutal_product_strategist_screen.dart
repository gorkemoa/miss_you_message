import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../model/product_idea_model.dart';
import '../service/brutal_product_strategist_service.dart';

class BrutalProductStrategistScreen extends StatefulWidget {
  const BrutalProductStrategistScreen({super.key});

  @override
  _BrutalProductStrategistScreenState createState() => _BrutalProductStrategistScreenState();
}

class _BrutalProductStrategistScreenState extends State<BrutalProductStrategistScreen> {
  final BrutalProductStrategistService _strategistService = BrutalProductStrategistService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _usersController = TextEditingController();
  final TextEditingController _monetizationController = TextEditingController();
  
  bool _isLoading = false;
  String _initialPrompt = "Ürünün ne? Bana tek satırlık tanıtımı, kullanıcıyı ve nasıl para kazandığını ver. Romantikleştirme.";
  ProductIdea? _evaluationResult;
  final Uuid _uuid = Uuid();
  List<ProductIdea> _evaluationHistory = [];

  @override
  void initState() {
    super.initState();
    _loadInitialPrompt();
  }

  Future<void> _loadInitialPrompt() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final prompt = await _strategistService.getInitialPrompt();
      setState(() {
        _initialPrompt = prompt;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _evaluateIdea() async {
    if (_descriptionController.text.isEmpty ||
        _problemController.text.isEmpty ||
        _usersController.text.isEmpty ||
        _monetizationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _strategistService.evaluateProductIdea(
        _descriptionController.text,
        _problemController.text,
        _usersController.text,
        _monetizationController.text,
      );

      setState(() {
        _evaluationResult = result;
        _evaluationHistory.add(result);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Değerlendirme hatası: $e')),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _descriptionController.clear();
      _problemController.clear();
      _usersController.clear();
      _monetizationController.clear();
      _evaluationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acımasız Ürün Stratejisti'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.red,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İlk mesaj
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BRUTAL PRODUCT STRATEGIST',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          _initialPrompt,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Form
                  Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FİKRİNİ AÇIMASIZCA DEĞERLENELENDİR',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Ürün Açıklaması',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                            ),
                            minLines: 2,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _problemController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Çözdüğü Problem',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                            ),
                            minLines: 2,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _usersController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Hedef Kullanıcılar',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          TextField(
                            controller: _monetizationController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Gelir Modeli',
                              labelStyle: TextStyle(color: Colors.grey[400]),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey[700]!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              OutlinedButton(
                                onPressed: _clearForm,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey[600]!),
                                  foregroundColor: Colors.grey[400],
                                ),
                                child: const Text('Temizle'),
                              ),
                              ElevatedButton(
                                onPressed: _evaluateIdea,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Değerlendir'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  
                  // Değerlendirme sonucu
                  if (_evaluationResult != null)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: _evaluationResult!.judgment == "DEVAM"
                            ? Colors.green[900]
                            : _evaluationResult!.judgment == "PİVOT"
                                ? Colors.amber[900]
                                : Colors.red[900],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _evaluationResult!.judgment,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.0,
                            ),
                          ),
                          const Divider(color: Colors.white30),
                          const Text(
                            'NEDEN:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _evaluationResult!.reason,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          const Text(
                            'SONRAKİ ADIM:',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            _evaluationResult!.nextStep,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Değerlendirme geçmişi
                  if (_evaluationHistory.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32.0),
                        const Text(
                          'ÖNCEKİ DEĞERLENDİRMELER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        ..._evaluationHistory.reversed.map((idea) => 
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              color: Colors.grey[850],
                              child: ListTile(
                                title: Text(
                                  idea.description.length > 50 
                                      ? '${idea.description.substring(0, 50)}...' 
                                      : idea.description,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  'Karar: ${idea.judgment}',
                                  style: TextStyle(
                                    color: idea.judgment == "DEVAM"
                                        ? Colors.green
                                        : idea.judgment == "PİVOT"
                                            ? Colors.amber
                                            : Colors.red,
                                  ),
                                ),
                                trailing: Text(
                                  '${idea.createdAt.day}/${idea.createdAt.month}/${idea.createdAt.year}',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _problemController.dispose();
    _usersController.dispose();
    _monetizationController.dispose();
    super.dispose();
  }
} 