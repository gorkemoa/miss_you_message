import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../model/chat_list_model.dart';
import '../viewmodel/chat_list_viewmodel.dart';

class ImportDialog extends StatefulWidget {
  final ChatListViewModel viewModel;

  const ImportDialog({
    Key? key, 
    required this.viewModel,
  }) : super(key: key);

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final TextEditingController personaNameController = TextEditingController();
  String chatContent = '';
  late AIProvider selectedProvider;

  @override
  void initState() {
    super.initState();
    // Varsayılan servis olarak Gemini kullan
    selectedProvider = AIProvider.gemini;
  }

  // Hazır kişilikleri ekleme fonksiyonu
  void _addPredefinedPersona(PredefinedPersona personaType) async {
    try {
      await widget.viewModel.addPredefinedPersona(personaType, selectedProvider);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF075E54),
                    child: Icon(
                      Icons.person_add,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Yeni WhatsApp Sohbeti',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF075E54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber[800]),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Çok uzun sohbet geçmişleri otomatik olarak kısaltılacaktır. '
                        'Daha iyi sonuçlar için 15.000 karakterden kısa sohbetler yükleyin.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: personaNameController,
                decoration: InputDecoration(
                  labelText: 'Taklit Edilecek Kişinin Adı',
                  hintText: 'Örn: Ahmet, Ayşe',
                  prefixIcon: Icon(Icons.person, color: Color(0xFF075E54)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF075E54), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'AI Modelini Seçin:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildProviderOption(
                        AIProvider.openai,
                        'OpenAI (GPT-4)',
                        '🧠',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildProviderOption(
                        AIProvider.gemini,
                        'Google Gemini',
                        '🤖',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text(
                      'WhatsApp Sohbeti Seç',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              if (chatContent.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16.0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF25D366)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF25D366)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dosya yüklendi (${chatContent.length} karakter)',
                          style: TextStyle(color: Color(0xFF075E54)),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF075E54),
                      side: BorderSide(color: Color(0xFF075E54)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('İptal'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _createContact,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Analiz Et'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Hazır Kişilik Seçenekleri
              Text(
                'Hazır Kişilik Seçenekleri:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              
              // Bilge Demir
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                child: InkWell(
                  onTap: () => _addPredefinedPersona(PredefinedPersona.bilgeDemir),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.orange.shade700,
                          child: const Icon(Icons.lightbulb, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bilge Demir',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Her konuda bilgili, şaşırtıcı gerçekleri paylaşan bir uzman',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Psikolog Emre
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade300),
                ),
                child: InkWell(
                  onTap: () => _addPredefinedPersona(PredefinedPersona.psikologEmre),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade700,
                          child: const Icon(Icons.psychology, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Psikolog Emre',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Anlayışlı, sabırlı, yargılamayan erkek psikolog',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Psikolog Emel
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.purple.shade300),
                ),
                child: InkWell(
                  onTap: () => _addPredefinedPersona(PredefinedPersona.psikologEmel),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.shade700,
                          child: const Icon(Icons.psychology, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Psikolog Emel',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Empatik, destekleyici, içten kadın psikolog',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 16),
              Text(
                'veya WhatsApp Sohbetinden Kişilik Oluştur:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderOption(
    AIProvider provider,
    String label,
    String emoji,
    Color color,
  ) {
    final isSelected = selectedProvider == provider;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedProvider = provider;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      
      if (result == null || result.files.isEmpty) {
        // Kullanıcı dosya seçmedi veya iptal etti
        return;
      }
      
      final platformFile = result.files.first;
      
      // Dosya adını ve boyutunu göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya seçildi: ${platformFile.name}, Boyut: ${platformFile.size} bytes'),
          backgroundColor: Color(0xFF075E54),
        ),
      );
      
      if (platformFile.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya verisi okunamadı (bytes null)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (platformFile.bytes!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya boş (0 byte)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Dosyayı Utf8 olarak çözümle
      setState(() {
        chatContent = String.fromCharCodes(platformFile.bytes!);
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya yükleme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createContact() {
    if (personaNameController.text.isNotEmpty && chatContent.isNotEmpty) {
      widget.viewModel.analyzePersona(
        chatContent, 
        personaNameController.text,
        selectedProvider,
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir isim girin ve dosya yükleyin'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 