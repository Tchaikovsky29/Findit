import 'package:flutter/material.dart';
import '../models/supabase_service.dart';
import '../services/found_items_service.dart';
import '../services/auth_service.dart';
import '../models/found_item_model.dart';
import '../utils/constants.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';

/// Home Screen
/// Main screen showing all found items from database
/// Allows searching, filtering, and adding new items
/// Route: /home (after successful login)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ===== SERVICES =====
  final _foundItemsService = FoundItemsService();
  final _authService = AuthService();
  final _supabaseService = SupabaseService();
  
  // ===== STATE VARIABLES =====
  List<FoundItemModel> _allItems = [];
  List<FoundItemModel> _displayItems = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  int _activeFilter = 0; // 0=All, 1=My Items, 2=Recent
  
  // ===== LIFECYCLE =====
  @override
  void initState() {
    super.initState();
    _loadItems();
    _searchController.addListener(_filterItems);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // ===== DATA LOADING METHODS =====
  
  /// Load all found items from database
  /// Fetches from Supabase with user details (join)
  /// Updates UI state when complete
  Future<void> _loadItems() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final items = await _foundItemsService.getAllFoundItems();
      
      if (mounted) {
        setState(() {
          _allItems = items;
          _displayItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error loading items: $e', isError: true);
      }
    }
  }
  
  /// Filter items based on search query and active filter
  /// Called whenever search text changes or filter changes
  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    
    List<FoundItemModel> filtered = _allItems;
    
    // Apply active filter
    if (_activeFilter == 1) {
      // My Items
      filtered = filtered
          .where((item) => item.addedBy == _supabaseService.currentUserPRN)
          .toList();
    } else if (_activeFilter == 2) {
      // Recent (last 7 days)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      filtered = filtered
          .where((item) => item.createdAt.isAfter(sevenDaysAgo))
          .toList();
    }
    
    // Apply search query
    if (query.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query) ||
            item.userTags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }
    
    setState(() => _displayItems = filtered);
  }
  
  // ===== ACTION METHODS =====
  
  /// Delete found item with confirmation
  /// Only shows for current user's items
  /// Removes from database and local list
  Future<void> _deleteItem(FoundItemModel item) async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final result = await _foundItemsService.deleteFoundItem(
        item.id,
        imageUrl: item.imageUrl,
      );
      
      if (mounted) {
        if (result['success']) {
          _showSnackBar('Item deleted successfully');
          _loadItems(); // Refresh list
        } else {
          _showSnackBar(result['message'], isError: true);
        }
      }
    }
  }
  
  /// Logout user and navigate to login screen
  Future<void> _logout() async {
    await _authService.logout();
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
  
  /// Refresh items list
  /// Called when user pulls to refresh
  Future<void> _onRefresh() async {
    await _loadItems();
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
  
  // ===== BUILD METHODS =====
  
  /// Build item card widget
  /// Shows item details, image, and user info with dark theme design
  Widget _buildItemCard(FoundItemModel item) {
    final isOwnItem = item.addedBy == _supabaseService.currentUserPRN;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailsScreen(item: item),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AppConstants.surfaceColor,
                  AppConstants.surfaceColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== TOP ROW: TITLE + DELETE BUTTON =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwnItem)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteItem(item),
                            tooltip: 'Delete item',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ===== LOCATION CHIP =====
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.secondaryColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.secondaryColor.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          item.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== IMAGE + DESCRIPTION =====
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image thumbnail with dark styling
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl != null
                              ? Image.network(
                                  item.imageUrl!,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) {
                                    return Container(
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        color: AppConstants.secondaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white38,
                                        size: 30,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: AppConstants.secondaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2,
                                    color: Colors.white38,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Description and user info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppConstants.secondaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppConstants.secondaryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.white60,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.userDetails?['full_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // ===== TAGS =====
                  if (item.userTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.userTags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  /// Build filter chips
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 0),
          const SizedBox(width: 8),
          _buildFilterChip('My Items', 1),
          const SizedBox(width: 8),
          _buildFilterChip('Recent', 2),
        ],
      ),
    );
  }
  
  /// Build single filter chip
  Widget _buildFilterChip(String label, int filterIndex) {
    final isActive = _activeFilter == filterIndex;

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        setState(() => _activeFilter = filterIndex);
        _filterItems();
      },
      backgroundColor: isActive ? AppConstants.primaryColor : AppConstants.surfaceColor,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.white70,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isActive ? AppConstants.primaryColor : AppConstants.secondaryColor.withOpacity(0.3),
      ),
    );
  }
  
  // ===== MAIN BUILD =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Find it'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // ===== SEARCH BAR =====
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
                filled: true,
                fillColor: AppConstants.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          
          // ===== FILTER CHIPS =====
          _buildFilterChips(),
          
          // ===== ITEMS LIST =====
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _displayItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.white38,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No items found',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              TextButton(
                                onPressed: () => _searchController.clear(),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                ),
                                child: const Text('Clear search'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          itemCount: _displayItems.length,
                          itemBuilder: (context, index) {
                            return _buildItemCard(_displayItems[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          ).then((_) => _loadItems());
        },
        backgroundColor: AppConstants.primaryColor,
        tooltip: 'Add found item',
        child: const Icon(Icons.add),
      ),
    );
  }
}