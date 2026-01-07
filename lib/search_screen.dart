import 'package:flutter/material.dart';
import 'utils/constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<SearchResult> _searchResults = [];

  final List<SearchResult> _allItems = [
    SearchResult(
      title: 'Blue Leather Wallet',
      description: 'Lost blue leather bifold wallet with credit cards',
      location: 'Science Building, 2nd Floor',
      finderName: 'Raj Kumar',
      finderPhone: '+91 98765 43210',
      foundDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SearchResult(
      title: 'Black iPhone 14',
      description: 'Black iPhone with cracked screen protector',
      location: 'Library Study Area',
      finderName: 'Sarah Ahmed',
      finderPhone: '+91 97654 32109',
      foundDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SearchResult(
      title: 'Red College Bag',
      description: 'Red Nike backpack with books and notebooks',
      location: 'Cafeteria',
      finderName: 'Amit Singh',
      finderPhone: '+91 96543 21098',
      foundDate: DateTime.now(),
    ),
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
      final filtered = _allItems
          .where((item) =>
              item.title.toLowerCase().contains(query.toLowerCase()) ||
              item.description.toLowerCase().contains(query.toLowerCase()))
          .toList();

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search lost items',
                hintText: 'Describe what you lost...',
                prefixIcon: const Icon(Icons.search, color: AppConstants.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length > 2) {
                  _performSearch(value);
                }
              },
            ),
          ),

          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppConstants.primaryColor,
                    ),
                  )
                : _searchResults.isEmpty && _searchController.text.isNotEmpty
                    ? const Center(
                        child: Text(
                          'No items found. Try different keywords.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppConstants.hintColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Search for lost items by describing them',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppConstants.hintColor,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
                                  padding:
                                      const EdgeInsets.all(AppConstants.paddingMedium),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                      const SizedBox(height: 8),
                                      Text(
                                        'Found by: ${item.finderName}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: AppConstants.paddingMedium),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Contact: ${item.finderPhone}',
                                                ),
                                                backgroundColor:
                                                    AppConstants.successColor,
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.phone, size: 18),
                                          label: const Text('Contact Finder'),
                                          style: ElevatedButton.styleFrom(
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
    );
  }
}

class SearchResult {
  final String title;
  final String description;
  final String location;
  final String finderName;
  final String finderPhone;
  final DateTime foundDate;

  SearchResult({
    required this.title,
    required this.description,
    required this.location,
    required this.finderName,
    required this.finderPhone,
    required this.foundDate,
  });
}