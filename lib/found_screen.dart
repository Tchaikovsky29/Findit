import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'utils/constants.dart';
import 'utils/validators.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  
import 'package:supabase_flutter/supabase_flutter.dart';

class FoundItemsScreen extends StatefulWidget {
  const FoundItemsScreen({Key? key}) : super(key: key);

  @override
  State<FoundItemsScreen> createState() => _FoundItemsScreenState();
}

class _FoundItemsScreenState extends State<FoundItemsScreen> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _llmResult;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _tagsController;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isAddingItem = false;
  bool _showAddForm = false;
  bool _isAnalyzingImage = false;
  String? _analysisError;

  List<FoundItem> _postedItems = [
    FoundItem(
      id: '1',
      title: 'Blue Leather Wallet',
      description: 'Lost blue leather bifold wallet with business cards',
      location: 'Science Building, 2nd Floor',
      tags: ['wallet', 'leather', 'blue'],
      imageUrl: null,
      dateFound: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _tagsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isAnalyzingImage = true;
          _analysisError = null;
          _llmResult = null;
        });
        
        // Convert image to base64 and send to API
        try {
          final bytes = await pickedFile.readAsBytes();
          final base64Image = base64Encode(bytes);
          
          final response = await http.post(
            Uri.parse('https://findit-api-production-1478.up.railway.app/analyze_image'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'image_base64': base64Image}),
          ).timeout(
            const Duration(seconds: 120), // 2 minute timeout for LLM
            onTimeout: () => throw TimeoutException('Image analysis took too long (>120s)'),
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            setState(() {
              _llmResult = data['result'];
              _isAnalyzingImage = false;
              _analysisError = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image analyzed successfully!')),
            );
          } else {
            final errorMsg = 'API returned ${response.statusCode}: ${response.body}';
            setState(() {
              _isAnalyzingImage = false;
              _analysisError = errorMsg;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Analysis failed: $errorMsg')),
            );
          }
        } on http.ClientException catch (e) {
          setState(() {
            _isAnalyzingImage = false;
            _analysisError = 'Network error: ${e.toString()}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Network error: ${e.toString()}')),
          );
        } on TimeoutException catch (e) {
          setState(() {
            _isAnalyzingImage = false;
            _analysisError = 'Request timeout: ${e.toString()}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request timeout: ${e.toString()}')),
          );
        } catch (e) {
          setState(() {
            _isAnalyzingImage = false;
            _analysisError = e.toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error analyzing image: $e')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String> uploadImageToSupabase(File image) async {
    final supabase = Supabase.instance.client;

    final fileName =
        'found_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final path = 'images/$fileName';

    await supabase.storage.from('Images').upload(
          path,
          image,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    final publicUrl = supabase.storage.from('Images').getPublicUrl(path);
    return publicUrl;
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing required fields')),
      );
      return;
    }

    setState(() => _isAddingItem = true);

    try {
      final supabase = Supabase.instance.client;

      // Get current user
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        setState(() => _isAddingItem = false);
        return;
      }

      // Fetch PRN from users table by email
      final userResponse = await supabase
          .from('users')
          .select('prn')
          .eq('email', user.email!)
          .single();

      final userPrn = userResponse['prn'] as String?;

      // 1️⃣ Upload image
      final imageUrl = await uploadImageToSupabase(_selectedImage!);

      if (_llmResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_analysisError ?? 'AI analysis not ready. Please wait for the image to be analyzed.')),
        );
        setState(() => _isAddingItem = false);
        return;
      }

      final aiResult = _llmResult!;

      // 2️⃣ Insert into DB with added_by
      await supabase.from('found_items').insert({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'user_tags': _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'ai_object': aiResult['object'],
        'ai_adjectives': aiResult['adjectives'],
        'ai_description': aiResult['description'],
        'image_url': imageUrl,
        'added_by': userPrn,
      });

      // Add to local list
      final newItem = FoundItem(
        id: 'id_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        imageUrl: imageUrl,
        dateFound: DateTime.now(),
      );

      // 3️⃣ Reset UI
      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();
      _tagsController.clear();

      setState(() {
        _isAddingItem = false;
        _showAddForm = false;
        _selectedImage = null;
        _postedItems.add(newItem);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item posted successfully!')),
      );
    } catch (e) {
      setState(() => _isAddingItem = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    }
  }

  Widget _buildAddItemForm() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusLarge),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera_outlined,
                            size: 48,
                            color: AppConstants.primaryColor,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tap to select image',
                            style: TextStyle(
                              color: AppConstants.hintColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                hintText: 'e.g., Blue Leather Wallet',
                prefixIcon:
                    Icon(Icons.label, color: AppConstants.primaryColor),
              ),
              validator: Validators.validateItemTitle,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the item in detail...',
                prefixIcon: Icon(Icons.description,
                    color: AppConstants.primaryColor),
              ),
              maxLines: 4,
              minLines: 3,
              validator: Validators.validateDescription,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location Found',
                hintText: 'Where did you find this item?',
                prefixIcon:
                    Icon(Icons.location_on, color: AppConstants.primaryColor),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'Location'),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g., blue, leather, wallet',
                prefixIcon: Icon(Icons.tag, color: AppConstants.primaryColor),
              ),
              validator: (value) =>
                  Validators.validateRequired(value, 'At least one tag'),
            ),
            const SizedBox(height: AppConstants.paddingXXLarge), // âœ… FIXED

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showAddForm = false;
                        _selectedImage = null;
                      });
                      _titleController.clear();
                      _descriptionController.clear();
                      _locationController.clear();
                      _tagsController.clear();
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAddingItem ? null : _submitItem,
                    child: _isAddingItem
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Post Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showAddForm = !_showAddForm);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Found Item'),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            if (_showAddForm) ...[
              _buildAddItemForm(),
              const SizedBox(height: AppConstants.paddingMedium),
            ],

            _postedItems.isEmpty
                ? const Center(
                    child: Text(
                      'No items posted yet',
                      style: TextStyle(
                        color: AppConstants.hintColor,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _postedItems.length,
                    itemBuilder: (context, index) {
                      final item = _postedItems[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: AppConstants.paddingMedium,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusLarge,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.paddingMedium,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.imageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusLarge,
                                  ),
                                  child: Image.network(
                                    item.imageUrl!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(height: AppConstants.paddingMedium),

                              Text(
                                item.title,
                                style: AppConstants.heading2,
                              ),
                              const SizedBox(height: 8),

                              Text(
                                item.description,
                                style: AppConstants.labelText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 18,
                                    color: AppConstants.hintColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.location,
                                      style: AppConstants.labelText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),

                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: item.tags
                                    .map((tag) => Chip(
                                          label: Text(
                                            tag,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppConstants.primaryColor,
                                            ),
                                          ),
                                          backgroundColor: AppConstants
                                              .primaryColor
                                              .withOpacity(0.2),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class FoundItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final List<String> tags;
  final String? imageUrl;
  final DateTime dateFound;

  FoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.tags,
    this.imageUrl,
    required this.dateFound,
  });
}