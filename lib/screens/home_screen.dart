import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/secure_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import 'statistics_screen.dart';

/// Home screen that displays decrypted secure entries from SQLite database
/// Includes navigation, search, and entry management functionality
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<SecureEntry> _filteredEntries = [];
  bool _isSearching = false;
  int _selectedTabIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: SecureEntryType.values.length + 1, vsync: this);
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.loadAllEntries();
      // Add sample data in debug mode if no entries exist
      if (!const bool.fromEnvironment('dart.vm.product')) {
        dataProvider.addSampleData();
      }
    });
  }

  Future<void> _refreshData() async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
      backgroundColor: AppTheme.lightGray,
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search vault...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
          isDense: true,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: _performSearch,
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return Column(
          children: [
            _buildFixedHeader(dataProvider),
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppTheme.lightGray,
                child: _buildContent(dataProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFixedHeader(DataProvider dataProvider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildAppBarHeader(),
              const SizedBox(height: 12),
              if (!_isSearching) _buildStatsRow(dataProvider),
              if (_isSearching) _buildSearchField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(DataProvider dataProvider) {
    if (dataProvider.isLoading) {
      return _buildLoadingState();
    }

    if (dataProvider.errorMessage != null) {
      return _buildErrorState(dataProvider.errorMessage!);
    }

    if (_isSearching) {
      return _buildSearchContent();
    }

    return _buildMainContent(dataProvider);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryBlue),
          SizedBox(height: 16),
          Text(
            'Loading your vault...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 30,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            GradientButton(
              text: 'Try Again',
              icon: Icons.refresh,
              onPressed: () => _refreshData(),
              width: 120,
              height: 36,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchContent() {
    if (_filteredEntries.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptySearchState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEntries.length,
      itemBuilder: (context, index) {
        return _buildEntryCard(_filteredEntries[index]);
      },
    );
  }

  Widget _buildMainContent(DataProvider dataProvider) {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(child: _buildTabView(dataProvider)),
      ],
    );
  }



  Widget _buildAppBarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VaultGuardian',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your Digital Fortress',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeaderButton(
              icon: _isSearching ? Icons.close : Icons.search,
              onPressed: _toggleSearch,
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: Icons.more_vert,
              onPressed: () => _showOptionsMenu(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStatsRow(DataProvider dataProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Entries',
            dataProvider.totalEntries.toString(),
            Icons.shield_rounded,
            Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Categories',
            SecureEntryType.values.length.toString(),
            Icons.category_rounded,
            Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction('refresh');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: AppTheme.primaryPurple),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _handleMenuAction('logout');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }



  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: SecureEntryType.values.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterChip('All', -1, Icons.apps);
                }
                final type = SecureEntryType.values[index - 1];
                return _buildFilterChip(
                  type.displayName,
                  index - 1,
                  _getIconData(type),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(SecureEntryType type) {
    switch (type) {
      case SecureEntryType.personalNote:
        return Icons.note_alt;
      case SecureEntryType.loginCredentials:
        return Icons.login;
      case SecureEntryType.paymentCard:
        return Icons.credit_card;
      case SecureEntryType.identityDocument:
        return Icons.badge;
      case SecureEntryType.secureNote:
        return Icons.lock_outline;
      case SecureEntryType.bankAccount:
        return Icons.account_balance;
      case SecureEntryType.socialMedia:
        return Icons.share;
      case SecureEntryType.workCredentials:
        return Icons.work;
      case SecureEntryType.personalInfo:
        return Icons.person;
      case SecureEntryType.other:
        return Icons.folder;
    }
  }

  Widget _buildFilterChip(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = index == -1
        ? AppTheme.primaryBlue
        : Color(int.parse(SecureEntryType.values[index].colorHex.substring(1), radix: 16) + 0xFF000000);

    return Container(
      width: 80,
      height: 70,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppTheme.lightGray,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : AppTheme.mediumGray,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? color : AppTheme.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.mediumGray.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.search_off,
                  size: 40,
                  color: AppTheme.mediumGray,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Results Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGray,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No entries match "${_searchController.text.length > 25 ? '${_searchController.text.substring(0, 25)}...' : _searchController.text}"',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mediumGray,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Clear Search',
                  icon: Icons.clear,
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildTabView(DataProvider dataProvider) {
    List<SecureEntry> entries;

    if (_selectedTabIndex == -1) {
      entries = dataProvider.entries;
    } else {
      final type = SecureEntryType.values[_selectedTabIndex];
      entries = dataProvider.getEntriesByType(type);
    }

    if (entries.isEmpty) {
      return _buildEmptyFilterState();
    }

    return Expanded(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryBlue,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _buildEntryCard(entries[index]);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    final typeName = _selectedTabIndex == -1
        ? 'entries'
        : SecureEntryType.values[_selectedTabIndex].displayName.toLowerCase();

    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 300,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    _selectedTabIndex == -1 ? Icons.folder_open : Icons.filter_list_off,
                    size: 40,
                    color: AppTheme.mediumGray,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No $typeName found',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedTabIndex == -1
                      ? 'Start by adding your first secure entry to begin protecting your digital life'
                      : 'No entries of this type have been added yet',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mediumGray,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: 'Add Entry',
                    icon: Icons.add,
                    onPressed: _addNewEntry,
                    height: 48,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildEntryCard(SecureEntry entry) {
    final color = Color(int.parse(entry.type.colorHex.substring(1), radix: 16) + 0xFF000000);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppTheme.lightGray.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewEntry(entry),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      entry.type.icon,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              entry.type.displayName,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Updated ${_formatDate(entry.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mediumGray,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PopupMenuButton<String>(
                    onSelected: (value) => _handleEntryAction(value, entry),
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.mediumGray,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, size: 16, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Text('View', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 16, color: AppTheme.primaryPurple),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, color: AppTheme.errorRed, size: 16),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppTheme.errorRed, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }





  Widget _buildFloatingActionButton() {
    return CustomFAB(
      onPressed: _addNewEntry,
      icon: Icons.add_rounded,
      tooltip: 'Add New Entry',
    );
  }



  // Helper methods
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredEntries.clear();
      }
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredEntries.clear();
      });
      return;
    }

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final results = await dataProvider.searchEntries(query);

    setState(() {
      _filteredEntries = results;
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        final dataProvider = Provider.of<DataProvider>(context, listen: false);
        dataProvider.refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refreshing vault...'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        break;
      case 'statistics':
        _showStatistics();
        break;
      case 'logout':
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _logout(authProvider);
        break;
    }
  }

  void _handleEntryAction(String action, SecureEntry entry) {
    switch (action) {
      case 'view':
        _viewEntry(entry);
        break;
      case 'edit':
        _editEntry(entry);
        break;
      case 'delete':
        _deleteEntry(entry);
        break;
    }
  }

  void _addNewEntry() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEntryScreen(),
      ),
    );

    // Refresh data if entry was added successfully
    if (result == true && mounted) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.refresh();
    }
  }

  void _viewEntry(SecureEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EntryDetailScreen(entry: entry),
      ),
    );
  }

  void _editEntry(SecureEntry entry) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(entryToEdit: entry),
      ),
    );

    // Refresh data if entry was updated successfully
    if (result == true && mounted) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.refresh();
    }
  }

  void _deleteEntry(SecureEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (!mounted) return;

              final dataProvider = Provider.of<DataProvider>(context, listen: false);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              final success = await dataProvider.deleteEntry(entry.id!);

              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Entry deleted' : 'Failed to delete entry'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showStatistics() {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final stats = dataProvider.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Entries: ${stats['total']}'),
            Text('Added Today: ${stats['today']}'),
            Text('Added This Week: ${stats['thisWeek']}'),
            Text('Added This Month: ${stats['thisMonth']}'),
            const SizedBox(height: 16),
            const Text('By Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...SecureEntryType.values.map((type) => Text(
              '${type.displayName}: ${stats['byType'][type] ?? 0}',
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _logout(AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              authProvider.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
