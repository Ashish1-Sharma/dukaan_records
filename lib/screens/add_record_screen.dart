import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mydukaan_records/models/record.dart';
import 'dart:io';

import '../models/customer.dart';
import 'add_customer_screen.dart';

// Design System Constants
class AppTheme {
  static const primaryGreen = Color(0xFF2E7D32);
  static const lightGreen = Color(0xFF43A047);
  static const accentGreen = Color(0xFF66BB6A);
  static const backgroundColor = Color(0xFFF5F7FA);
  static const cardBackground = Colors.white;
  static const errorRed = Color(0xFFE53935);
  static const warningOrange = Color(0xFFFB8C00);
  static const successGreen = Color(0xFF43A047);
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

  static BoxShadow get primaryShadow => BoxShadow(
    color: primaryGreen.withOpacity(0.2),
    blurRadius: 16,
    offset: const Offset(0, 6),
  );
}

class AddRecordScreen extends StatefulWidget {
  final Isar isar;
  final Record? record;
  final Customer? preSelectedCustomer;

  const AddRecordScreen({
    Key? key,
    required this.isar,
    this.record,
    this.preSelectedCustomer,
  }) : super(key: key);

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _searchController = TextEditingController();

  Customer? _selectedCustomer;
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  DateTime _selectedDate = DateTime.now();
  String? _selectedImagePath;
  bool _isLoading = false;
  bool _isLoadingCustomers = true;
  bool _showCustomerSearch = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isEditing => widget.record != null;

  double get _totalAmount => double.tryParse(_totalAmountController.text) ?? 0.0;
  double get _paidAmount => double.tryParse(_paidAmountController.text) ?? 0.0;
  double get _leftAmount => _totalAmount - _paidAmount;
  bool get _isPaid => _leftAmount <= 0;

  @override
  void initState() {
    super.initState();
    _loadCustomers();

    if (_isEditing) {
      _populateFields();
    } else if (widget.preSelectedCustomer != null) {
      _selectedCustomer = widget.preSelectedCustomer;
    }

    _totalAmountController.addListener(_updateCalculations);
    _paidAmountController.addListener(_updateCalculations);
    _searchController.addListener(_filterCustomers);
  }

  void _updateCalculations() {
    setState(() {});
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = List.from(_allCustomers);
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              customer.phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      final customers = await widget.isar.customers.where().findAll();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _filteredCustomers = List.from(customers);
          _isLoadingCustomers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCustomers = false;
        });
        _showSnackBar('add_record_screen.customer_load_error'.tr() + ': $e', isError: true);
      }
    }
  }

  void _populateFields() async {
    final record = widget.record!;
    _descriptionController.text = record.description;
    _totalAmountController.text = record.totalAmount.toString();
    _paidAmountController.text = record.paidAmount.toString();
    _selectedDate = record.date;
    _selectedImagePath = record.imagePath;

    final customer = await widget.isar.customers.get(record.customerId);
    if (mounted) {
      setState(() {
        _selectedCustomer = customer;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _buildHeaderCard(),
              // const SizedBox(height: 20),
              _buildCustomerSection(),
              const SizedBox(height: 20),
              _buildTransactionForm(),
              const SizedBox(height: 20),
              _buildAmountSummaryCard(),
              const SizedBox(height: 20),
              _buildDateImageSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
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
      title: Text(
        _isEditing ? 'add_record_screen.edit_title'.tr() : 'add_record_screen.add_title'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      actions: [
        if (_isEditing)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _showDeleteDialog,
            tooltip: 'Delete Record',
          ),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.primaryShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'add_record_screen.edit_info'.tr()
                      : 'add_record_screen.fill_details'.tr(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'add_record_screen.select_customer_label'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              if (!_isLoadingCustomers && _allCustomers.isNotEmpty)
                IconButton(
                  icon: Icon(
                    _showCustomerSearch ? Icons.close : Icons.search,
                    color: AppTheme.primaryGreen,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCustomerSearch = !_showCustomerSearch;
                      if (!_showCustomerSearch) {
                        _searchController.clear();
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingCustomers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (_allCustomers.isEmpty)
            _buildNoCustomersWidget()
          else ...[
              if (_showCustomerSearch) ...[
                _buildSearchField(),
                const SizedBox(height: 16),
              ],
              _buildCustomerSelection(),
            ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: TextStyle(
            color: AppTheme.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSelection() {
    if (_selectedCustomer != null && !_showCustomerSearch) {
      return _buildSelectedCustomerCard();
    }

    return Column(
      children: [
        if (_filteredCustomers.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.person_search,
                  size: 48,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'No customers found',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _filteredCustomers.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.dividerColor,
              ),
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  title: Text(
                    customer.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    customer.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _showCustomerSearch = false;
                      _searchController.clear();
                    });
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        _buildAddCustomerButton(),
      ],
    );
  }

  Widget _buildSelectedCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.15),
            child: Text(
              _selectedCustomer!.name.isNotEmpty
                  ? _selectedCustomer!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedCustomer!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedCustomer!.phone,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppTheme.primaryGreen,
            onPressed: () {
              setState(() {
                _showCustomerSearch = true;
              });
            },
            tooltip: 'Change customer',
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomerButton() {
    return OutlinedButton.icon(
      onPressed: _addNewCustomer,
      icon: const Icon(Icons.person_add_outlined, size: 18),
      label: Text('add_record_screen.add_new_customer_btn'.tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryGreen,
        side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildNoCustomersWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningOrange.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_add_outlined,
            size: 48,
            color: AppTheme.warningOrange.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'add_record_screen.no_customer_found'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.warningOrange.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'add_record_screen.add_customer_first_hint'.tr(),
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _addNewCustomer,
            icon: const Icon(Icons.add, size: 18),
            label: Text('add_record_screen.add_new_customer_btn'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'add_record_screen.transaction_details'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildFormField(
            controller: _descriptionController,
            label: 'add_record_screen.description_label'.tr(),
            hint: 'add_record_screen.description_hint'.tr(),
            icon: Icons.notes_rounded,
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  controller: _totalAmountController,
                  label: 'add_record_screen.total_amount_label'.tr(),
                  hint: '0.00',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'add_record_screen.total_amount_required'.tr();
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'add_record_screen.invalid_amount'.tr();
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  controller: _paidAmountController,
                  label: 'add_record_screen.paid_amount_label'.tr(),
                  hint: '0.00',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    final paidAmount = double.tryParse(value ?? '0') ?? 0;
                    final totalAmount = double.tryParse(_totalAmountController.text) ?? 0;

                    if (paidAmount < 0) {
                      return 'add_record_screen.invalid_paid_amount'.tr();
                    }
                    if (paidAmount > totalAmount) {
                      return 'add_record_screen.paid_exceeds_total'.tr();
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isPaid
              ? [AppTheme.successGreen.withOpacity(0.1), AppTheme.successGreen.withOpacity(0.05)]
              : [AppTheme.warningOrange.withOpacity(0.1), AppTheme.warningOrange.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: _isPaid
              ? AppTheme.successGreen.withOpacity(0.3)
              : AppTheme.warningOrange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isPaid
                      ? AppTheme.successGreen.withOpacity(0.15)
                      : AppTheme.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isPaid ? Icons.check_circle_outline : Icons.schedule_rounded,
                  color: _isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'add_record_screen.payment_status'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildAmountDisplay(
                  'add_record_screen.total_label'.tr(),
                  _totalAmount,
                  Icons.account_balance_wallet_outlined,
                  const Color(0xFF1976D2),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.dividerColor,
              ),
              Expanded(
                child: _buildAmountDisplay(
                  'add_record_screen.paid_label'.tr(),
                  _paidAmount,
                  Icons.payments_outlined,
                  AppTheme.successGreen,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.dividerColor,
              ),
              Expanded(
                child: _buildAmountDisplay(
                  'add_record_screen.due_label'.tr(),
                  _leftAmount > 0 ? _leftAmount : 0,
                  Icons.pending_outlined,
                  _leftAmount > 0 ? AppTheme.errorRed : AppTheme.successGreen,
                ),
              ),
            ],
          ),

          if (_totalAmount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isPaid
                    ? AppTheme.successGreen.withOpacity(0.15)
                    : AppTheme.warningOrange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPaid ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: _isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPaid
                        ? 'add_record_screen.fully_paid'.tr()
                        : 'add_record_screen.amount_due_fmt'.tr(args: [_leftAmount.toStringAsFixed(2)]),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _isPaid ? AppTheme.successGreen : AppTheme.warningOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.7)),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildDateImageSection() {
    return Row(
      children: [
        Expanded(
          child: _buildDateCard(),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildImageCard(),
        ),
      ],
    );
  }

  Widget _buildDateCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'add_record_screen.date_label'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border.all(color: AppTheme.dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'add_record_screen.bill_photo_label'.tr(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _showImageOptions,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border.all(
                  color: _selectedImagePath != null
                      ? AppTheme.primaryGreen.withOpacity(0.3)
                      : AppTheme.dividerColor,
                  width: _selectedImagePath != null ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _selectedImagePath != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.file(
                      File(_selectedImagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppTheme.textSecondary,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add Photo',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.dividerColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),
        Expanded(
          child: SizedBox(

            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEditing ? Icons.update_rounded : Icons.save_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isEditing ? 'Update Record' : 'Save Record',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Bill Photo',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildImageOption(
                    'Camera',
                    Icons.camera_alt_outlined,
                        () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageOption(
                    'Gallery',
                    Icons.photo_library_outlined,
                        () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildImageOption(
                  'Remove Photo',
                  Icons.delete_outline,
                  _removeImage,
                  color: AppTheme.errorRed,
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(
      String title,
      IconData icon,
      VoidCallback onTap, {
        Color? color,
      }) {
    final optionColor = color ?? AppTheme.primaryGreen;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: optionColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: optionColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: optionColor,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: optionColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', isError: true);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCustomer == null) {
        _showSnackBar('Please select a customer', isError: true);
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final description = _descriptionController.text.trim();
        final totalAmount = double.parse(_totalAmountController.text.trim());
        final paidAmount = double.parse(_paidAmountController.text.trim());
        final leftAmount = totalAmount - paidAmount;
        final customer = widget.preSelectedCustomer;

        if (_isEditing) {
          final record = widget.record!;
          record.description = description;
          record.totalAmount = totalAmount;
          record.paidAmount = paidAmount;
          record.leftAmount = leftAmount;
          record.date = _selectedDate;
          record.isPaid = leftAmount <= 0;
          record.imagePath = _selectedImagePath;
          record.customerId = _selectedCustomer!.id;

          await widget.isar.writeTxn(() async {
            await widget.isar.records.put(record);
          });

          customer?.totalPaid = record.paidAmount;
          customer?.totalDue = record.leftAmount;

          _showSnackBar('Record updated successfully');
        } else {
          final newRecord = Record()
            ..description = description
            ..totalAmount = totalAmount
            ..paidAmount = paidAmount
            ..leftAmount = leftAmount
            ..date = _selectedDate
            ..isPaid = leftAmount <= 0
            ..imagePath = _selectedImagePath
            ..customerId = _selectedCustomer!.id;

          customer?.totalPaid += paidAmount;
          customer?.totalDue += leftAmount;

          await widget.isar.writeTxn(() async {
            await widget.isar.records.put(newRecord);
          });

          _showSnackBar('Record saved successfully');
        }

        await widget.isar.writeTxn(() async {
          await widget.isar.customers.put(customer!);
        });

        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        _showSnackBar('Error saving record: $e', isError: true);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
              const SizedBox(width: 12),
              const Text(
                'Delete Record',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this record? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _deleteRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRecord() async {
    Navigator.of(context).pop();

    setState(() {
      _isLoading = true;
    });

    try {
      final record = widget.record!;
      await widget.isar.writeTxn(() async {
        await widget.isar.records.delete(record.id);
      });

      _showSnackBar('Record deleted successfully');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Error deleting record: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNewCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(isar: widget.isar),
      ),
    );

    if (result == true) {
      await _loadCustomers();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
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