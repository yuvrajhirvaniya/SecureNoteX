import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/secure_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

/// Screen for adding new secure entries or editing existing ones
/// Includes form validation and encryption before storage
class AddEntryScreen extends StatefulWidget {
  final SecureEntry? entryToEdit;

  const AddEntryScreen({Key? key, this.entryToEdit}) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  SecureEntryType _selectedType = SecureEntryType.personalNote;
  bool _isLoading = false;
  bool _obscureContent = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.entryToEdit != null) {
      final entry = widget.entryToEdit!;
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _selectedType = entry.type;
      _obscureContent = entry.type == SecureEntryType.loginCredentials;
    } else {
      _obscureContent = _selectedType == SecureEntryType.loginCredentials;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
                  child: _buildForm(),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entryToEdit != null ? 'Edit Entry' : 'Add Entry',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.entryToEdit != null
                      ? 'Update information'
                      : 'Secure your data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            GradientButton(
              text: 'Save',
              onPressed: _saveEntry,
              width: 70,
              height: 36,
              gradient: AppTheme.goldGradient,
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 32),
            _buildTitleField(),
            const SizedBox(height: 24),
            _buildContentField(),
            const SizedBox(height: 32),
            _buildSaveButton(),
            if (widget.entryToEdit != null) ...[
              const SizedBox(height: 16),
              _buildDeleteButton(),
            ],
            const SizedBox(height: 32), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Entry Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
        const SizedBox(height: 16),
        Container(
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
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate optimal number of columns based on screen width
              final screenWidth = constraints.maxWidth;
              const minItemWidth = 70.0;
              const spacing = 8.0;
              final maxColumns = ((screenWidth + spacing) / (minItemWidth + spacing)).floor();
              final columns = maxColumns.clamp(2, 4); // Between 2-4 columns

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: SecureEntryType.values.length,
                itemBuilder: (context, index) {
                  final type = SecureEntryType.values[index];
                  final isSelected = _selectedType == type;
                  final color = Color(int.parse(type.colorHex.substring(1), radix: 16) + 0xFF000000);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = type;
                        _obscureContent = type == SecureEntryType.loginCredentials ||
                                         type == SecureEntryType.workCredentials;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.lightGray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            type.icon,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              type.displayName,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? color : AppTheme.mediumGray,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return CustomTextField(
      label: 'Entry Title',
      hint: 'Enter a descriptive title for your entry',
      controller: _titleController,
      prefixIcon: Icons.title_rounded,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        if (value.trim().length < 2) {
          return 'Title must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildContentField() {
    return CustomTextField(
      label: _getContentLabel(),
      hint: _getContentHint(),
      controller: _contentController,
      prefixIcon: _getContentIcon(),
      obscureText: _obscureContent,
      maxLines: (_selectedType == SecureEntryType.personalNote ||
                 _selectedType == SecureEntryType.secureNote) ? 5 : 1,
      suffixIcon: _selectedType == SecureEntryType.loginCredentials ||
                  _selectedType == SecureEntryType.workCredentials
          ? IconButton(
              icon: Icon(
                _obscureContent ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: AppTheme.mediumGray,
              ),
              onPressed: () {
                setState(() {
                  _obscureContent = !_obscureContent;
                });
              },
            )
          : null,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter the content';
        }
        return null;
      },
    );
  }

  Widget _buildSaveButton() {
    return GradientButton(
      text: widget.entryToEdit != null ? 'Update Entry' : 'Save Entry',
      icon: _isLoading ? null : Icons.save_rounded,
      isLoading: _isLoading,
      onPressed: _isLoading ? null : _saveEntry,
      width: double.infinity,
      height: 56,
    );
  }

  Widget _buildDeleteButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.errorRed, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _deleteEntry,
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_rounded, color: AppTheme.errorRed, size: 24),
                SizedBox(width: 12),
                Text(
                  'Delete Entry',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods
  String _getContentLabel() {
    return _selectedType.fullDisplayName;
  }

  String _getContentHint() {
    switch (_selectedType) {
      case SecureEntryType.personalNote:
        return 'Enter your personal note here...';
      case SecureEntryType.loginCredentials:
        return 'Username: example@email.com\nPassword: ********';
      case SecureEntryType.paymentCard:
        return 'Card Number: **** **** **** ****\nExpiry: MM/YY\nCVV: ***';
      case SecureEntryType.identityDocument:
        return 'Document Number: ********\nIssue Date: DD/MM/YYYY';
      case SecureEntryType.secureNote:
        return 'Enter your secure note here...';
      case SecureEntryType.bankAccount:
        return 'Account Number: ********\nRouting Number: ********';
      case SecureEntryType.socialMedia:
        return 'Platform: Instagram\nUsername: @username\nPassword: ********';
      case SecureEntryType.workCredentials:
        return 'Company: Example Corp\nEmail: work@company.com\nPassword: ********';
      case SecureEntryType.personalInfo:
        return 'Name: John Doe\nPhone: +1234567890\nAddress: 123 Main St';
      case SecureEntryType.other:
        return 'Enter content...';
    }
  }

  IconData _getContentIcon() {
    switch (_selectedType) {
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
        return Icons.text_fields;
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      
      final entry = SecureEntry(
        id: widget.entryToEdit?.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        type: _selectedType,
        createdAt: widget.entryToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (widget.entryToEdit != null) {
        success = await dataProvider.updateEntry(entry);
      } else {
        success = await dataProvider.addEntry(entry);
      }

      if (success && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entryToEdit != null
                ? 'Entry updated successfully'
                : 'Entry added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dataProvider.errorMessage ?? 'Failed to save entry'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteEntry() async {
    if (widget.entryToEdit?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${widget.entryToEdit!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final dataProvider = Provider.of<DataProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await dataProvider.deleteEntry(widget.entryToEdit!.id!);

      if (success && mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(dataProvider.errorMessage ?? 'Failed to delete entry'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
