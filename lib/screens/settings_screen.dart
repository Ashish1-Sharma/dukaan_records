import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:mydukaan_records/models/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/customer.dart';

// Design System - Consistent with AddRecordScreen
class AppTheme {
  static const primaryGreen = Color(0xFF2E7D32);
  static const lightGreen = Color(0xFF43A047);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const cardBackground = Colors.white;
  static const errorRed = Color(0xFFE53935);
  static const warningOrange = Color(0xFFFB8C00);
  static const successGreen = Color(0xFF43A047);
  static const infoBlue = Color(0xFF1976D2);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const dividerColor = Color(0xFFE0E0E0);

  static const borderRadius = 16.0;
  static const cardPadding = 20.0;
  static const spacing = 16.0;

  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
}

class SettingsScreen extends StatefulWidget {
  final Isar isar;

  const SettingsScreen({
    Key? key,
    required this.isar,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBackingUp = false;
  bool _isExporting = false;
  String _appVersion = '';
  int _totalCustomers = 0;
  int _totalRecords = 0;
  double _totalAmount = 0;
  double _totalDue = 0;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _loadDataStats();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (e) {
      debugPrint('Error loading app info: $e');
    }
  }

  Future<void> _loadDataStats() async {
    try {
      final customers = await widget.isar.customers.where().findAll();
      final records = await widget.isar.records.where().findAll();

      final totalAmount = records.fold<double>(0, (sum, r) => sum + r.totalAmount);
      final totalDue = records.fold<double>(0, (sum, r) => sum + r.leftAmount);

      if (mounted) {
        setState(() {
          _totalCustomers = customers.length;
          _totalRecords = records.length;
          _totalAmount = totalAmount;
          _totalDue = totalDue;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  String get _currentLanguageName {
    final currentLocale = context.locale;
    final lang = _languages.firstWhere(
          (l) => l['code'] == currentLocale.languageCode,
      orElse: () => _languages[0],
    );
    return lang['nativeName']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing),
        child: Column(
          children: [
            // _buildDataOverviewCard(),
            // const SizedBox(height: 20),
            _buildLanguageSection(),
            const SizedBox(height: 20),
            _buildDataManagementSection(),
            const SizedBox(height: 20),
            _buildDangerZoneSection(),
            const SizedBox(height: 24),
            _buildAppInfoCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryGreen,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Settings',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildDataOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Data Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadDataStats,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Customers',
                  _totalCustomers.toString(),
                  Icons.people_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Records',
                  _totalRecords.toString(),
                  Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Business',
                  '₹${_formatAmount(_totalAmount)}',
                  Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Due',
                  '₹${_formatAmount(_totalDue)}',
                  Icons.pending_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _buildSettingsCard(
      title: 'Language',
      icon: Icons.language_rounded,
      iconColor: AppTheme.infoBlue,
      children: [
        _buildSettingsTile(
          icon: Icons.translate,
          iconColor: AppTheme.infoBlue,
          title: 'App Language',
          subtitle: _currentLanguageName,
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: _showLanguageDialog,
        ),
      ],
    );
  }

  Widget _buildDataManagementSection() {
    return _buildSettingsCard(
      title: 'Data Management',
      icon: Icons.cloud_outlined,
      iconColor: AppTheme.successGreen,
      children: [
        _buildSettingsTile(
          icon: Icons.backup_outlined,
          iconColor: AppTheme.successGreen,
          title: 'Create Backup',
          subtitle: 'Save your data to device storage',
          trailing: _isBackingUp
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.successGreen,
            ),
          )
              : const Icon(Icons.chevron_right, size: 20),
          onTap: _isBackingUp ? null : _createBackup,
        ),
        Divider(height: 1, color: AppTheme.dividerColor),
        _buildSettingsTile(
          icon: Icons.file_download_outlined,
          iconColor: AppTheme.infoBlue,
          title: 'Export as CSV',
          subtitle: 'Download records in spreadsheet format',
          trailing: _isExporting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.infoBlue,
            ),
          )
              : const Icon(Icons.chevron_right, size: 20),
          onTap: _isExporting ? null : _exportData,
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection() {
    return _buildSettingsCard(
      title: 'Danger Zone',
      icon: Icons.warning_rounded,
      iconColor: AppTheme.errorRed,
      children: [
        _buildSettingsTile(
          icon: Icons.delete_forever_outlined,
          iconColor: AppTheme.errorRed,
          title: 'Delete All Data',
          subtitle: 'Permanently remove all customers and records',
          trailing: Icon(Icons.chevron_right, size: 20, color: AppTheme.errorRed),
          onTap: _showDeleteDataDialog,
          titleColor: AppTheme.errorRed,
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.cardPadding,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.store_rounded,
            color: AppTheme.primaryGreen,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'MyDukaan Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version $_appVersion',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Manage your business records efficiently',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: AppTheme.infoBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Select Language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final currentLocale = context.locale;
              final isSelected = currentLocale.languageCode == lang['code'];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                    size: 24,
                  ),
                ),
                title: Text(
                  lang['nativeName']!,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  lang['name']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                onTap: () {
                  context.setLocale(Locale(lang['code']!));
                  Navigator.pop(context);
                  _showSnackBar(
                    'Language changed to ${lang['nativeName']}',
                    icon: Icons.check_circle,
                  );
                  setState(() {}); // Refresh to update language display
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isBackingUp = true);

    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        _showSnackBar('Unable to access storage', isError: true);
        return;
      }

      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final backupFileName = 'mydukaan_backup_$timestamp.isar';
      final backupPath = '${directory.path}/$backupFileName';

      final isarPath = widget.isar.directory;
      final isarFile = File('$isarPath/default.isar');

      if (await isarFile.exists()) {
        await isarFile.copy(backupPath);
        _showBackupSuccessDialog(backupPath, backupFileName);
      } else {
        _showSnackBar('Database file not found', isError: true);
      }
    } catch (e) {
      _showSnackBar('Backup failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final records = await widget.isar.records.where().findAll();
      final customers = await widget.isar.customers.where().findAll();

      if (records.isEmpty) {
        _showSnackBar('No records to export', isError: true);
        return;
      }

      // Create CSV with proper formatting
      final csvRows = <String>[];
      csvRows.add('Date,Customer Name,Phone,Description,Total Amount,Paid Amount,Due Amount,Status');

      for (final record in records) {
        final customer = customers.firstWhere(
              (c) => c.id == record.customerId,
          orElse: () => Customer()..name = 'Unknown'..phone = '',
        );

        final dateStr = DateFormat('dd/MM/yyyy').format(record.date);
        final description = record.description.replaceAll(',', ';').replaceAll('"', '""');
        final status = record.isPaid ? 'Paid' : 'Unpaid';

        csvRows.add(
            '$dateStr,"${customer.name}","${customer.phone}","$description",${record.totalAmount},${record.paidAmount},${record.leftAmount},$status'
        );
      }

      final csvContent = csvRows.join('\n');

      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
      final fileName = 'mydukaan_records_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MyDukaan Records Export',
        text: 'Exported ${records.length} records',
      );

      _showSnackBar(
        'Exported ${records.length} records successfully',
        icon: Icons.check_circle,
      );
    } catch (e) {
      _showSnackBar('Export failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete All Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorRed,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action will permanently delete:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildDeleteWarningItem('$_totalCustomers customers'),
            _buildDeleteWarningItem('$_totalRecords records'),
            _buildDeleteWarningItem('All transaction history'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.errorRed.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete All',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.cancel_rounded,
            color: AppTheme.errorRed,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAllData() async {
    try {
      await widget.isar.writeTxn(() async {
        await widget.isar.clear();
      });

      _showSnackBar(
        'All data has been deleted',
        icon: Icons.check_circle,
      );

      // Reload stats
      await _loadDataStats();
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
    }
  }

  void _showBackupSuccessDialog(String path, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successGreen,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Backup Created',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your data has been backed up successfully!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.file_present_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          path,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Share.shareXFiles([XFile(path)]);
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  void _showSnackBar(String message, {bool isError = false, IconData? icon}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ?? (isError ? Icons.error_outline : Icons.info_outline),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}