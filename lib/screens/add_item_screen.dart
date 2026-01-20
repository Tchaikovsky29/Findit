import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/found_items_service.dart';
import '../utils/constants.dart';
import '../env.dart';

/// Add Item Screen
/// Allows user to report a new found item
/// Supports image upload from gallery or camera

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});
  
  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  // ===== CONTROLLERS =====
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _tagsController = TextEditingController();
  final _foundItemsService = FoundItemsService();
  
  // ===== STATE VARIABLES =====
  File? _selectedImage;
  bool _isLoading = false;
  bool _isAnalyzingImage = false;
  Map<String, dynamic>? _llmResult;
  String? _analysisError;
  
  // ===== LIFECYCLE =====
  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
  
  // ===== IMAGE METHODS =====
  
  /// Show dialog to choose image source
  /// Options: Gallery or Camera
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Pick image from device gallery
  Future<void> _pickImageFromGallery() async {
    final imageFile = await _foundItemsService.pickImageFromGallery();
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        _isAnalyzingImage = true;
        _analysisError = null;
        _llmResult = null;
      });
      await _analyzeImageWithFlask(imageFile);
    }
  }
  
  /// Take photo with camera
  Future<void> _pickImageFromCamera() async {
    final imageFile = await _foundItemsService.pickImageFromCamera();
    if (imageFile != null) {
      setState(() {
        _selectedImage = imageFile;
        _isAnalyzingImage = true;
        _analysisError = null;
        _llmResult = null;
      });
      await _analyzeImageWithFlask(imageFile);
    }
  }
  
  /// Analyze image using Flask API
  /// Sends base64-encoded image to LLM for analysis
  Future<void> _analyzeImageWithFlask(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final response = await http.post(
        Uri.parse(EnvironmentConfig.imageAnalysisEndpoint),
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
        _showSnackBar('Image analyzed successfully!');
      } else {
        final errorMsg = 'API returned ${response.statusCode}: ${response.body}';
        setState(() {
          _isAnalyzingImage = false;
          _analysisError = errorMsg;
        });
        _showSnackBar('Analysis failed: $errorMsg', isError: true);
      }
    } on http.ClientException catch (e) {
      setState(() {
        _isAnalyzingImage = false;
        _analysisError = 'Network error: ${e.toString()}';
      });
      _showSnackBar('Network error: ${e.toString()}', isError: true);
    } on TimeoutException catch (e) {
      setState(() {
        _isAnalyzingImage = false;
        _analysisError = 'Request timeout: ${e.toString()}';
      });
      _showSnackBar('Request timeout: ${e.toString()}', isError: true);
    } catch (e) {
      setState(() {
        _isAnalyzingImage = false;
        _analysisError = e.toString();
      });
      _showSnackBar('Error analyzing image: $e', isError: true);
    }
  }
  
  /// Remove selected image
  void _removeImage() {
    setState(() => _selectedImage = null);
  }
  
  // ===== VALIDATION & SUBMISSION =====
  
  /// Validate all inputs before submission
  /// Returns error message if validation fails, null if valid
  String? _validateInputs() {
    if (_titleController.text.trim().isEmpty) {
      return 'Please enter item title';
    }

    if (_titleController.text.trim().length < 3) {
      return 'Title must be at least 3 characters';
    }

    if (_locationController.text.trim().isEmpty) {
      return 'Please enter location where item was found';
    }

    if (_selectedImage == null) {
      return 'Please select an item image';
    }

    return null; // Valid
  }
  
  /// Add found item to database
  /// Validates, uploads image, and saves to database with AI analysis
  Future<void> _addItem() async {
    // Validation
    final validationError = _validateInputs();
    if (validationError != null) {
      _showSnackBar(validationError, isError: true);
      return;
    }
    
    // Check if image analysis is complete
    if (_llmResult == null) {
      _showSnackBar(
        _analysisError ?? 'Please wait for image analysis to complete',
        isError: true,
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Parse tags (comma-separated string to list)
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      
      // Call service to add item
      final result = await _foundItemsService.addFoundItemWithAnalysis(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        userTags: tags,
        imageFile: _selectedImage!,
        aiObject: _llmResult!['object'] ?? '',
        aiAdjectives: List<String>.from(_llmResult!['adjectives'] ?? []),
        aiDescription: _llmResult!['description'] ?? '',
      );
      
      setState(() => _isLoading = false);
      
      if (!mounted) return;
      
      if (result['success']) {
        _showSnackBar('Item added successfully!');
        
        // Wait 1 second then navigate back
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context);
      } else {
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: ${e.toString()}', isError: true);
    }
  }
  
  /// Show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
  
  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Found Item'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== TITLE =====
            TextField(
              controller: _titleController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Item Title *',
                hintText: 'e.g., Blue Backpack, Red Umbrella',
                prefixIcon: const Icon(Icons.label),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ===== DESCRIPTION =====
            TextField(
              controller: _descController,
              enabled: !_isLoading,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the item (color, size, condition, etc.)',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ===== LOCATION =====
            TextField(
              controller: _locationController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Location Found *',
                hintText: 'e.g., Library 3rd Floor, Main Gate',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ===== TAGS =====
            TextField(
              controller: _tagsController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Tags (optional)',
                hintText: 'e.g., blue,leather,backpack (comma-separated)',
                prefixIcon: const Icon(Icons.tag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // ===== IMAGE SECTION =====
            Text(
              'Item Image *',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Image preview or placeholder
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeImage,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // ===== IMAGE BUTTONS =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _showImageSourceDialog,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // ===== SUBMIT BUTTON =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppConstants.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Report Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}