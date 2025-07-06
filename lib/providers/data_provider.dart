import 'package:flutter/foundation.dart';
import '../models/secure_entry.dart';
import '../services/database_service.dart';

/// Provider for managing secure data throughout the app
/// Handles CRUD operations for secure entries with encrypted storage
class DataProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  
  List<SecureEntry> _entries = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<SecureEntryType, int> _entriesCountByType = {};

  DataProvider(this._databaseService) {
    _loadAllEntries();
  }

  // Getters
  List<SecureEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<SecureEntryType, int> get entriesCountByType => Map.unmodifiable(_entriesCountByType);
  int get totalEntries => _entries.length;

  // Statistics methods
  int getCategoriesUsed() {
    final usedTypes = <SecureEntryType>{};
    for (final entry in _entries) {
      usedTypes.add(entry.type);
    }
    return usedTypes.length;
  }

  SecureEntry? getLastUpdatedEntry() {
    if (_entries.isEmpty) return null;

    SecureEntry? latest = _entries.first;
    for (final entry in _entries) {
      if (entry.updatedAt.isAfter(latest!.updatedAt)) {
        latest = entry;
      }
    }
    return latest;
  }

  double getSecurityScore() {
    if (_entries.isEmpty) return 0.0;

    double score = 0.0;
    final totalEntries = _entries.length;

    // Base score for having entries
    score += 20.0;

    // Score for diversity of entry types
    final usedTypes = getCategoriesUsed();
    score += (usedTypes / SecureEntryType.values.length) * 30.0;

    // Score for number of entries
    score += (totalEntries.clamp(0, 20) / 20.0) * 30.0;

    // Score for recent activity
    final recentEntries = _entries.where((entry) {
      final now = DateTime.now();
      final entryDate = entry.updatedAt;
      return now.difference(entryDate).inDays <= 30;
    }).length;
    score += (recentEntries / totalEntries) * 20.0;

    return score.clamp(0.0, 100.0);
  }

  /// Get entries filtered by type
  List<SecureEntry> getEntriesByType(SecureEntryType type) {
    return _entries.where((entry) => entry.type == type).toList();
  }

  /// Get recent entries (last 10)
  List<SecureEntry> get recentEntries {
    final sortedEntries = List<SecureEntry>.from(_entries);
    sortedEntries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sortedEntries.take(10).toList();
  }

  /// Load all entries from database
  Future<void> loadAllEntries() async {
    await _loadAllEntries();
  }

  Future<void> _loadAllEntries() async {
    _setLoading(true);
    _clearError();

    try {
      _entries = await _databaseService.getAllSecureEntries();
      await _updateEntriesCount();
    } catch (e) {
      _setError('Failed to load entries: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new secure entry
  Future<bool> addEntry(SecureEntry entry) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _databaseService.insertSecureEntry(entry);

      // Add the entry to local list with the generated ID
      final newEntry = entry.copyWith(id: id);
      _entries.add(newEntry);

      // Sort entries by updated date (newest first)
      _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      await _updateEntriesCount();
      _setLoading(false);
      notifyListeners(); // Ensure UI updates immediately
      return true;
    } catch (e) {
      _setError('Failed to add entry: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing secure entry
  Future<bool> updateEntry(SecureEntry entry) async {
    if (entry.id == null) {
      _setError('Cannot update entry without ID');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      final count = await _databaseService.updateSecureEntry(updatedEntry);

      if (count > 0) {
        // Update the entry in local list
        final index = _entries.indexWhere((e) => e.id == entry.id);
        if (index != -1) {
          _entries[index] = updatedEntry;
          // Sort entries by updated date (newest first)
          _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        }

        await _updateEntriesCount();
        _setLoading(false);
        notifyListeners(); // Ensure UI updates immediately
        return true;
      } else {
        _setError('Entry not found or not updated');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to update entry: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a secure entry
  Future<bool> deleteEntry(int id) async {
    _setLoading(true);
    _clearError();

    try {
      final count = await _databaseService.deleteSecureEntry(id);

      if (count > 0) {
        // Remove the entry from local list
        _entries.removeWhere((entry) => entry.id == id);

        await _updateEntriesCount();
        _setLoading(false);
        notifyListeners(); // Ensure UI updates immediately
        return true;
      } else {
        _setError('Entry not found or not deleted');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete entry: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Search entries by title
  Future<List<SecureEntry>> searchEntries(String query) async {
    if (query.trim().isEmpty) {
      return _entries;
    }

    try {
      return await _databaseService.searchSecureEntries(query);
    } catch (e) {
      _setError('Failed to search entries: $e');
      return [];
    }
  }

  /// Get a specific entry by ID
  Future<SecureEntry?> getEntryById(int id) async {
    try {
      return await _databaseService.getSecureEntryById(id);
    } catch (e) {
      _setError('Failed to get entry: $e');
      return null;
    }
  }

  /// Clear all entries (for logout or reset)
  Future<bool> clearAllEntries() async {
    _setLoading(true);
    _clearError();

    try {
      await _databaseService.clearAllData();
      _entries.clear();
      _entriesCountByType.clear();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to clear all entries: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Refresh data from database
  Future<void> refresh() async {
    await _loadAllEntries();
  }

  /// Update entries count by type
  Future<void> _updateEntriesCount() async {
    try {
      _entriesCountByType = await _databaseService.getEntriesCountByType();
      notifyListeners();
    } catch (e) {
      // Don't set error for count update failure, just log it
      debugPrint('Failed to update entries count: $e');
    }
  }

  /// Get entries statistics
  Map<String, dynamic> getStatistics() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(const Duration(days: 7));
    final thisMonth = DateTime(now.year, now.month, 1);

    final todayEntries = _entries.where((e) => 
      e.createdAt.isAfter(today)).length;
    
    final weekEntries = _entries.where((e) => 
      e.createdAt.isAfter(thisWeek)).length;
    
    final monthEntries = _entries.where((e) => 
      e.createdAt.isAfter(thisMonth)).length;

    return {
      'total': _entries.length,
      'today': todayEntries,
      'thisWeek': weekEntries,
      'thisMonth': monthEntries,
      'byType': _entriesCountByType,
    };
  }

  /// Check if there are any entries
  bool get hasEntries => _entries.isNotEmpty;

  /// Check if there are entries of a specific type
  bool hasEntriesOfType(SecureEntryType type) {
    return _entries.any((entry) => entry.type == type);
  }

  /// Get the most recently updated entry
  SecureEntry? get mostRecentEntry {
    if (_entries.isEmpty) return null;
    
    return _entries.reduce((a, b) => 
      a.updatedAt.isAfter(b.updatedAt) ? a : b);
  }

  /// Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Add sample data for testing (only in debug mode)
  Future<void> addSampleData() async {
    if (kDebugMode && _entries.isEmpty) {
      final sampleEntries = [
        SecureEntry(
          title: 'Gmail Account',
          content: 'Email: john.doe@gmail.com\nPassword: MySecurePass123!',
          type: SecureEntryType.loginCredentials,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        SecureEntry(
          title: 'Important Reminder',
          content: 'Remember to backup data every Friday at 5 PM\nCheck security updates monthly',
          type: SecureEntryType.personalNote,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        SecureEntry(
          title: 'Visa Credit Card',
          content: 'Card Number: 4532 1234 5678 9012\nExpiry: 12/25\nCVV: 123\nCardholder: John Doe',
          type: SecureEntryType.paymentCard,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
      ];

      for (final entry in sampleEntries) {
        await addEntry(entry);
      }
    }
  }
}
