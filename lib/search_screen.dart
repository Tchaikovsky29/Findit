import 'package:flutter/material.dart';
import 'utils/constants.dart';
// import 'utils/supabase_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Mock data - Replace with Supabase fetch
  final List<Map<String, dynamic>> _allItems = [
    {
      'id': '1',
      'title': 'Blue Leather Wallet',
      'description': 'Lost blue leather bifold wallet with credit cards inside',
      'location': 'Science Building, 2nd Floor',
      'finder_name': 'Raj Kumar',
      'finder_phone': '+91 98765 43210',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'user_tags': ['wallet', 'leather', 'blue'],
      'ai_tags': ['wallet', 'leather', 'bifold'],
      'image_url': null,
    },
    {
      'id': '2',
      'title': 'Black iPhone 14',
      'description': 'Black iPhone with cracked screen protector',
      'location': 'Library Study Area',
      'finder_name': 'Sarah Ahmed',
      'finder_phone': '+91 97654 32109',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'user_tags': ['phone', 'iphone', 'black'],
      'ai_tags': ['phone', 'mobile', 'samsung'],
      'image_url': null,
    },
  ];

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      final filtered = _allItems.where((item) {
        final title = item['title'].toString().toLowerCase();
        final description = item['description'].toString().toLowerCase();
        final userTags = item['user_tags'] as List<dynamic>;
        final aiTags = item['ai_tags'] as List<dynamic>;
        final queryLower = query.toLowerCase();

        return title.contains(queryLower) ||
            description.contains(queryLower) ||
            userTags.any((tag) => tag.toString().toLowerCase().contains(queryLower)) ||
            aiTags.any((tag) => tag.toString().toLowerCase().contains(queryLower));
      }).toList();

      setState(() {
        _searchResults = filtered;
        _isSearching = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withValues(alpha: 0.1),
              AppConstants.accentColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search lost items',
                      hintText: 'Search by title, tag, or description...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      if (value.length > 2) {
                        _performSearch(value);
                      }
                    },
                  ),
                ),
              ),
            ),

          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(
                        child: Text(
                          'No items found. Try different keywords.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Search for lost items by title, description, or tags',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            padding: const EdgeInsets.all(
                                AppConstants.paddingMedium),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
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
                                      AppConstants.paddingMedium),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: AppConstants.heading2,
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        item['description'],
                                        style: AppConstants.labelText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(
                                          height: AppConstants.paddingMedium),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item['location'],
                                              style: AppConstants.labelText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        'Found by: ${item['finder_name']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(
                                          height: AppConstants.paddingMedium),

                                      // Tags display
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          ...((item['user_tags'] as List)
                                              .map((tag) => Chip(
                                                    label: Text(
                                                      tag,
                                                      style:
                                                          const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        AppConstants
                                                            .primaryColor
                                                            .withValues(alpha: 0.2),
                                                  ))),
                                          ...((item['ai_tags'] as List)
                                              .map((tag) => Chip(
                                                    label: Text(
                                                      tag,
                                                      style:
                                                          const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        AppConstants
                                                            .accentColor
                                                            .withValues(alpha: 0.2),
                                                  ))),
                                        ],
                                      ),
                                      const SizedBox(
                                          height: AppConstants.paddingMedium),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Contact: ${item['finder_phone']}',
                                                ),
                                                backgroundColor:
                                                    AppConstants.successColor,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.phone,
                                              size: 18),
                                          label: const Text(
                                              'Contact Finder'),
                                          style:
                                              ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
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