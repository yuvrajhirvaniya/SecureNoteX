import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/secure_entry.dart';
import '../theme/app_theme.dart';
import 'add_entry_screen.dart';

/// Screen for viewing detailed information about a secure entry
/// Includes copy functionality and edit/delete options
class EntryDetailScreen extends StatefulWidget {
  final SecureEntry entry;

  const EntryDetailScreen({Key? key, required this.entry}) : super(key: key);

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _obscureContent = false;

  @override
  void initState() {
    super.initState();
    // Obscure content by default for credential entries
    _obscureContent = widget.entry.type == SecureEntryType.loginCredentials ||
                      widget.entry.type == SecureEntryType.workCredentials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                widget.entry.type.icon,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entry.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.entry.type.fullDisplayName,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 20,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_title',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 16),
                    SizedBox(width: 8),
                    Text('Copy Title', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy_content',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_all, size: 16),
                    SizedBox(width: 8),
                    Text('Copy Content', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 16),
                    SizedBox(width: 8),
                    Text('Edit', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share, size: 16),
                    SizedBox(width: 8),
                    Text('Share', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildContentCard(),
          const SizedBox(height: 24),
          _buildMetadataCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }



  Widget _buildContentCard() {
    final color = Color(int.parse(widget.entry.type.colorHex.substring(1), radix: 16) + 0xFF000000);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getContentLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.entry.type == SecureEntryType.loginCredentials ||
                    widget.entry.type == SecureEntryType.workCredentials)
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        _obscureContent ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: AppTheme.mediumGray,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureContent = !_obscureContent;
                        });
                      },
                      tooltip: _obscureContent ? 'Show' : 'Hide',
                    ),
                  ),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.copy_rounded,
                      color: AppTheme.mediumGray,
                      size: 16,
                    ),
                    onPressed: () => _copyToClipboard(widget.entry.content, 'Content'),
                    tooltip: 'Copy',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _obscureContent ? _obscureText(widget.entry.content) : widget.entry.content,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.darkGray,
                  height: 1.5,
                  fontFamily: (widget.entry.type == SecureEntryType.loginCredentials ||
                              widget.entry.type == SecureEntryType.workCredentials) ? 'monospace' : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetadataRow('Created', _formatDateTime(widget.entry.createdAt)),
            const SizedBox(height: 8),
            _buildMetadataRow('Last Updated', _formatDateTime(widget.entry.updatedAt)),
            if (widget.entry.id != null) ...[
              const SizedBox(height: 8),
              _buildMetadataRow('Entry ID', widget.entry.id.toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _getContentLabel() {
    return widget.entry.type.fullDisplayName;
  }

  String _obscureText(String text) {
    return '•' * text.length;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'copy_title':
        _copyToClipboard(widget.entry.title, 'Title');
        break;
      case 'copy_content':
        _copyToClipboard(widget.entry.content, 'Content');
        break;
      case 'edit':
        _editEntry();
        break;
      case 'share':
        _shareEntry();
        break;
    }
  }

  void _shareEntry() {
    // Note: In a real app, you might want to be more careful about sharing sensitive data
    final shareText = '''
${widget.entry.title}

Type: ${widget.entry.type.displayName}
Content: ${(widget.entry.type == SecureEntryType.loginCredentials ||
           widget.entry.type == SecureEntryType.workCredentials) ? '[Hidden for security]' : widget.entry.content}

Created: ${_formatDateTime(widget.entry.createdAt)}
''';

    // For now, just copy to clipboard as sharing sensitive data should be done carefully
    _copyToClipboard(shareText, 'Entry details');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Entry'),
        content: const Text(
          'Entry details have been copied to clipboard. Please be careful when sharing sensitive information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _editEntry() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(entryToEdit: widget.entry),
      ),
    ).then((result) {
      // Refresh the screen if entry was updated
      if (result == true) {
        // In a real app, you might want to refresh the entry data
        setState(() {});
      }
    });
  }
}
