/// Model class for secure entries that will be stored in the database
/// All sensitive data is encrypted before storage
class SecureEntry {
  final int? id;
  final String title;
  final String content;
  final SecureEntryType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  SecureEntry({
    this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Convert SecureEntry to Map for database storage
  /// Note: content will be encrypted before calling this method
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content, // This should be encrypted content
      'type': type.toString(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create SecureEntry from Map (database row)
  /// Note: content will be decrypted after calling this method
  factory SecureEntry.fromMap(Map<String, dynamic> map) {
    return SecureEntry(
      id: map['id']?.toInt(),
      title: map['title'] ?? '',
      content: map['content'] ?? '', // This is encrypted content
      type: SecureEntryType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SecureEntryType.personalNote,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }

  /// Create a copy of SecureEntry with updated fields
  SecureEntry copyWith({
    int? id,
    String? title,
    String? content,
    SecureEntryType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecureEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SecureEntry{id: $id, title: $title, type: $type, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecureEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          type == other.type;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      content.hashCode ^
      type.hashCode;
}

/// Enum for different types of secure entries
enum SecureEntryType {
  personalNote,
  loginCredentials,
  paymentCard,
  identityDocument,
  secureNote,
  bankAccount,
  socialMedia,
  workCredentials,
  personalInfo,
  other,
}

/// Extension to get display names for SecureEntryType
extension SecureEntryTypeExtension on SecureEntryType {
  String get displayName {
    switch (this) {
      case SecureEntryType.personalNote:
        return 'Note';
      case SecureEntryType.loginCredentials:
        return 'Login';
      case SecureEntryType.paymentCard:
        return 'Card';
      case SecureEntryType.identityDocument:
        return 'ID';
      case SecureEntryType.secureNote:
        return 'Safe';
      case SecureEntryType.bankAccount:
        return 'Bank';
      case SecureEntryType.socialMedia:
        return 'Social';
      case SecureEntryType.workCredentials:
        return 'Work';
      case SecureEntryType.personalInfo:
        return 'Info';
      case SecureEntryType.other:
        return 'Other';
    }
  }

  /// Get full display name for detailed views
  String get fullDisplayName {
    switch (this) {
      case SecureEntryType.personalNote:
        return 'Personal Note';
      case SecureEntryType.loginCredentials:
        return 'Login Credentials';
      case SecureEntryType.paymentCard:
        return 'Payment Card';
      case SecureEntryType.identityDocument:
        return 'Identity Document';
      case SecureEntryType.secureNote:
        return 'Secure Note';
      case SecureEntryType.bankAccount:
        return 'Bank Account';
      case SecureEntryType.socialMedia:
        return 'Social Media';
      case SecureEntryType.workCredentials:
        return 'Work Credentials';
      case SecureEntryType.personalInfo:
        return 'Personal Information';
      case SecureEntryType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case SecureEntryType.personalNote:
        return '📝';
      case SecureEntryType.loginCredentials:
        return '🔐';
      case SecureEntryType.paymentCard:
        return '💳';
      case SecureEntryType.identityDocument:
        return '🆔';
      case SecureEntryType.secureNote:
        return '🔒';
      case SecureEntryType.bankAccount:
        return '🏦';
      case SecureEntryType.socialMedia:
        return '📱';
      case SecureEntryType.workCredentials:
        return '💼';
      case SecureEntryType.personalInfo:
        return '👤';
      case SecureEntryType.other:
        return '📦';
    }
  }

  /// Get color for each entry type
  String get colorHex {
    switch (this) {
      case SecureEntryType.personalNote:
        return '#10B981'; // Green
      case SecureEntryType.loginCredentials:
        return '#3B82F6'; // Blue
      case SecureEntryType.paymentCard:
        return '#F59E0B'; // Orange
      case SecureEntryType.identityDocument:
        return '#8B5CF6'; // Purple
      case SecureEntryType.secureNote:
        return '#EF4444'; // Red
      case SecureEntryType.bankAccount:
        return '#06B6D4'; // Cyan
      case SecureEntryType.socialMedia:
        return '#EC4899'; // Pink
      case SecureEntryType.workCredentials:
        return '#6366F1'; // Indigo
      case SecureEntryType.personalInfo:
        return '#84CC16'; // Lime
      case SecureEntryType.other:
        return '#6B7280'; // Gray
    }
  }
}
