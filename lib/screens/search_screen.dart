import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/found_items_service.dart';
import '../models/found_item_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _foundItemsService = FoundItemsService();
  bool _isSearching = false;
  List<FoundItemModel> _searchResults = [];

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Use full-text search for better results
      final results = await _foundItemsService.searchFoundItemsFullText(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                      debugPrint('=== onChanged triggered: "$value" (length: ${value.length}) ===');
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
                                              item.location,
                                              style: AppConstants.labelText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        'Found by: ${item.userDetails?['full_name'] ?? 'Unknown'}',
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
                                          // User tags
                                          if (item.userTags.isNotEmpty)
                                            ...item.userTags.map((tag) => Chip(
                                              label: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppConstants
                                                      .primaryColor
                                                      .withValues(alpha: 0.2),
                                            )),
                                          // AI adjectives
                                          if (item.aiAdjectives != null && item.aiAdjectives!.isNotEmpty)
                                            ...item.aiAdjectives!.map((adj) => Chip(
                                              label: Text(
                                                adj,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                              backgroundColor:
                                                  AppConstants
                                                      .accentColor
                                                      .withValues(alpha: 0.2),
                                            )),
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
                                                  'Contact: ${item.userDetails?['phone_number'] ?? 'Unknown'}',
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