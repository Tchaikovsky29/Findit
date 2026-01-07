import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'utils/constants.dart';
import 'utils/validators.dart';

class FoundItemsScreen extends StatefulWidget {
  const FoundItemsScreen({Key? key}) : super(key: key);

  @override
  State<FoundItemsScreen> createState() => _FoundItemsScreenState();
}

class _FoundItemsScreenState extends State<FoundItemsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _tagsController;

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isAddingItem = false;
  bool _showAddForm = false;

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
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _submitItem() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select an image'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        return;
      }

      setState(() => _isAddingItem = true);

      Future.delayed(const Duration(seconds: 2), () {
        final newItem = FoundItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          tags: _tagsController.text
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList(),
          imageUrl: _selectedImage!.path,
          dateFound: DateTime.now(),
        );

        setState(() {
          _postedItems.insert(0, newItem);
          _isAddingItem = false;
          _showAddForm = false;
          _selectedImage = null;
        });

        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        _tagsController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item posted successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      });
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
      body: Padding(
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

            Expanded(
              child: _postedItems.isEmpty
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
                                    child: Image.file(
                                      File(item.imageUrl!),
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