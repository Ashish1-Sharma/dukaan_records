import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:mydukaan_records/models/record.dart';
import 'package:mydukaan_records/models/customer.dart';

/// Clean, production-ready All Records Screen
/// Consistent with modern design system
class AllRecordsScreen extends StatefulWidget {
  final Isar isar;

  const AllRecordsScreen({
    super.key,
    required this.isar,
  });

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen> {
  // Design System Colors
  static const Color _primaryColor = Color(0xFF6C63FF);
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _cardColor = Colors.white;
  static const Color _successColor = Color(0xFF22C55E);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  // Pagination
  static const int pageSize = 20;
  int currentPage = 0;
  bool hasMoreRecords = true;
  bool isLoadingMore = false;

  // Data
  List<Record> allRecords = [];
  List<Record> displayedRecords = [];
  List<Record> filteredRecords = [];
  List<Customer> customers = [];

  // Filters
  String searchQuery = '';
  String selectedFilter = 'All';
  String selectedSort = 'Date';
  bool isLoading = true;

  // Global totals
  double globalTotalAmount = 0;
  double globalTotalPaid = 0;
  double globalTotalDue = 0;
  int globalTotalRecords = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreRecords();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      currentPage = 0;
      displayedRecords.clear();
      hasMoreRecords = true;
    });

    final customersList = await widget.isar.customers.where().findAll();
    final allRecordsList = await widget.isar.records.where().findAll();

    setState(() {
      customers = customersList;
      allRecords = allRecordsList;
      isLoading = false;
    });

    _calculateGlobalTotals();
    _applyFiltersAndResetPagination();
  }

  void _calculateGlobalTotals() {
    globalTotalRecords = allRecords.length;
    globalTotalAmount = allRecords.fold<double>(
      0,
          (sum, record) => sum + record.totalAmount,
    );
    globalTotalPaid = allRecords.fold<double>(
      0,
          (sum, record) => sum + record.paidAmount,
    );
    globalTotalDue = allRecords.fold<double>(
      0,
          (sum, record) => sum + record.leftAmount,
    );
  }

  void _applyFiltersAndResetPagination() {
    List<Record> filtered = List.from(allRecords);

    // Search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final customer = customers.firstWhere(
              (c) => c.id == record.customerId,
          orElse: () => Customer()..name = 'Unknown',
        );
        return record.description
            .toLowerCase()
            .contains(searchQuery.toLowerCase()) ||
            customer.name.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Status filter
    switch (selectedFilter) {
      case 'Paid':
        filtered = filtered.where((r) => r.isPaid).toList();
        break;
      case 'Unpaid':
        filtered = filtered.where((r) => !r.isPaid).toList();
        break;
      case 'Overdue':
        final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));
        filtered = filtered
            .where((r) => !r.isPaid && r.date.isBefore(thirtyDaysAgo))
            .toList();
        break;
    }

    // Sorting
    switch (selectedSort) {
      case 'Date':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Amount':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'Customer':
        filtered.sort((a, b) {
          final customerA = customers.firstWhere(
                (c) => c.id == a.customerId,
            orElse: () => Customer()..name = 'Unknown',
          );
          final customerB = customers.firstWhere(
                (c) => c.id == b.customerId,
            orElse: () => Customer()..name = 'Unknown',
          );
          return customerA.name.compareTo(customerB.name);
        });
        break;
    }

    setState(() {
      filteredRecords = filtered;
      currentPage = 0;
      displayedRecords.clear();
      hasMoreRecords = filtered.isNotEmpty;
    });

    _loadMoreRecords();
  }

  Future<void> _loadMoreRecords() async {
    if (isLoadingMore || !hasMoreRecords) return;

    setState(() => isLoadingMore = true);

    await Future.delayed(const Duration(milliseconds: 300));

    final startIndex = currentPage * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, filteredRecords.length);

    if (startIndex >= filteredRecords.length) {
      setState(() {
        hasMoreRecords = false;
        isLoadingMore = false;
      });
      return;
    }

    final newRecords = filteredRecords.sublist(startIndex, endIndex);

    setState(() {
      displayedRecords.addAll(newRecords);
      currentPage++;
      hasMoreRecords = endIndex < filteredRecords.length;
      isLoadingMore = false;
    });
  }

  Customer _getCustomer(int customerId) {
    return customers.firstWhere(
          (c) => c.id == customerId,
      orElse: () => Customer()..name = 'Unknown Customer',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          _buildSummaryBar(),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : displayedRecords.isEmpty && !isLoadingMore
                ? _buildEmptyState()
                : _buildRecordsList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: _textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'All Records',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined, size: 22),
          color: _primaryColor,
          onPressed: _loadInitialData,
          tooltip: 'Refresh',
        ),
        PopupMenuButton(
          icon: Icon(Icons.sort, color: _textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            _buildSortMenuItem('Date', Icons.calendar_today_outlined),
            _buildSortMenuItem('Amount', Icons.currency_rupee),
            _buildSortMenuItem('Customer', Icons.person_outline),
          ],
        ),
      ],
    );
  }

  PopupMenuItem _buildSortMenuItem(String label, IconData icon) {
    final isSelected = selectedSort == label;
    return PopupMenuItem(
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? _primaryColor : _textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            'Sort by $label',
            style: TextStyle(
              color: isSelected ? _primaryColor : _textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 18, color: _primaryColor),
          ],
        ],
      ),
      onTap: () {
        setState(() => selectedSort = label);
        _applyFiltersAndResetPagination();
      },
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: _cardColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search customer or description...',
              hintStyle: TextStyle(color: _textSecondary),
              prefixIcon: Icon(Icons.search, color: _textSecondary, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: _textSecondary, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() => searchQuery = '');
                  _applyFiltersAndResetPagination();
                },
              )
                  : null,
              filled: true,
              fillColor: _backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() => searchQuery = value);
              _applyFiltersAndResetPagination();
            },
          ),

          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', Icons.list_alt),
                _buildFilterChip('Paid', Icons.check_circle_outline),
                _buildFilterChip('Unpaid', Icons.schedule_outlined),
                _buildFilterChip('Overdue', Icons.error_outline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : _primaryColor,
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : _primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: _primaryColor.withOpacity(0.1),
        selectedColor: _primaryColor,
        side: BorderSide(
          color: isSelected ? _primaryColor : _primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: (selected) {
          setState(() => selectedFilter = label);
          _applyFiltersAndResetPagination();
        },
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: _textSecondary),
              const SizedBox(width: 8),
              Text(
                'Showing ${displayedRecords.length} of ${filteredRecords.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (filteredRecords.length != globalTotalRecords) ...[
                Text(
                  ' • Total: $globalTotalRecords',
                  style: TextStyle(
                    fontSize: 13,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: _borderColor),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total',
                  _formatCurrency(globalTotalAmount),
                  Icons.account_balance_wallet_outlined,
                  _textPrimary,
                ),
              ),
              Container(width: 1, height: 40, color: _borderColor),
              Expanded(
                child: _buildSummaryItem(
                  'Paid',
                  _formatCurrency(globalTotalPaid),
                  Icons.check_circle_outline,
                  _successColor,
                ),
              ),
              Container(width: 1, height: 40, color: _borderColor),
              Expanded(
                child: _buildSummaryItem(
                  'Due',
                  _formatCurrency(globalTotalDue),
                  Icons.schedule_outlined,
                  _dangerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: displayedRecords.length + (hasMoreRecords ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayedRecords.length) {
          return _buildLoadMoreIndicator();
        }

        final record = displayedRecords[index];
        final customer = _getCustomer(record.customerId);
        return _buildRecordCard(record, customer, index);
      },
    );
  }

  Widget _buildRecordCard(Record record, Customer customer, int index) {
    final statusColor = _getStatusColor(record);
    final statusText = _getStatusText(record);
    final statusIcon = _getStatusIcon(record);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Customer Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    child: Text(
                      customer.name.isNotEmpty
                          ? customer.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Customer Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: _textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(record.date),
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              if (record.description.isNotEmpty) ...[
                Text(
                  record.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Amount Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildAmountColumn(
                        'Total',
                        record.totalAmount,
                        Icons.account_balance_wallet_outlined,
                        _textPrimary,
                      ),
                    ),
                    Expanded(
                      child: _buildAmountColumn(
                        'Paid',
                        record.paidAmount,
                        Icons.check_circle_outline,
                        _successColor,
                      ),
                    ),
                    Expanded(
                      child: _buildAmountColumn(
                        'Due',
                        record.leftAmount,
                        Icons.schedule_outlined,
                        record.leftAmount > 0 ? _dangerColor : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              if (!record.isPaid) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markAsPaid(record, customer),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Mark Paid'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _successColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _editRecord(record),
                      icon: Icon(Icons.edit_outlined, size: 18, color: _primaryColor),
                      label: Text('Edit', style: TextStyle(color: _primaryColor)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        side: BorderSide(color: _primaryColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn(
      String label,
      double amount,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          '₹${_formatCurrency(amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLoadingMore
          ? CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
        strokeWidth: 3,
      )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading records...',
            style: TextStyle(
              fontSize: 15,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searchQuery.isNotEmpty || selectedFilter != 'All'
                  ? Icons.search_off
                  : Icons.receipt_long_outlined,
              size: 56,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            searchQuery.isNotEmpty || selectedFilter != 'All'
                ? 'No Records Found'
                : 'No Records Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              searchQuery.isNotEmpty || selectedFilter != 'All'
                  ? 'Try adjusting your filters or search'
                  : 'Start by adding your first record',
              style: TextStyle(
                fontSize: 15,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(Record record) {
    if (record.isPaid) return _successColor;

    final daysDiff = DateTime.now().difference(record.date).inDays;
    if (daysDiff > 30) return _dangerColor;
    return _warningColor;
  }

  String _getStatusText(Record record) {
    if (record.isPaid) return 'PAID';

    final daysDiff = DateTime.now().difference(record.date).inDays;
    if (daysDiff > 30) return 'OVERDUE';
    return 'PENDING';
  }

  IconData _getStatusIcon(Record record) {
    if (record.isPaid) return Icons.check_circle;

    final daysDiff = DateTime.now().difference(record.date).inDays;
    if (daysDiff > 30) return Icons.error;
    return Icons.schedule;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,##,##0').format(amount);
  }

  Future<void> _markAsPaid(Record record, Customer customer) async {
    try {
      await widget.isar.writeTxn(() async {
        record.isPaid = true;
        customer.totalPaid += record.leftAmount;
        customer.totalDue -= record.leftAmount;
        record.paidAmount = record.totalAmount;
        record.leftAmount = 0;
        await widget.isar.records.put(record);
        await widget.isar.customers.put(customer);
      });

      await _loadInitialData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Record marked as paid'),
              ],
            ),
            backgroundColor: _successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Text('Error: $e'),
              ],
            ),
            backgroundColor: _dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _editRecord(Record record) {
    // Navigate to edit record screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit functionality - integrate with your edit screen'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}