import 'dart:io';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:mydukaan_records/models/customer.dart';
import 'package:mydukaan_records/models/record.dart';
import 'package:mydukaan_records/screens/record_detail_screen.dart';

// Assuming your models are imported
// import 'customer.dart';
// import 'record.dart';

enum RecordFilter { all, paid, pending, overdue }
enum SortBy { dateDesc, dateAsc, amountDesc, amountAsc }

class CustomerRecordsScreen extends StatefulWidget {
  final Isar isar;
  final int customerId; // Optional - if provided, show only records for this customer

  const CustomerRecordsScreen({
    super.key,
    required this.isar,
    required this.customerId,
  });

  @override
  State<CustomerRecordsScreen> createState() => _CustomerRecordsScreenState();
}

class _CustomerRecordsScreenState extends State<CustomerRecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Record> allRecords = [];
  List<Record> filteredRecords = [];
  Map<int, Customer> customerMap = {};

  bool isLoading = true;
  String searchQuery = '';
  RecordFilter currentFilter = RecordFilter.all;
  SortBy currentSort = SortBy.dateDesc;

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      _applyFiltersAndSearch();
    });
  }

  Future<void> _loadRecords() async {
    try {
      List<Record> records;

      if (widget.customerId != null) {
        // Load records for specific customer
         records = await widget.isar.records
            .where()
            .filter()
            .customerIdEqualTo(widget.customerId)
            .sortByDateDesc()
            .limit(5)
            .findAll();
      } else {
        // Load all records
        records = await widget.isar.records.where().findAll();
      }

      // Load all customers for mapping
      final customers = await widget.isar.customers.where().findAll();
      final Map<int, Customer> custMap = {};
      for (final customer in customers) {
        custMap[customer.id] = customer;
      }

      setState(() {
        allRecords = records;
        customerMap = custMap;
        isLoading = false;
        _applyFiltersAndSearch();
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applyFiltersAndSearch() {
    List<Record> filtered = List.from(allRecords);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((record) {
        final customer = customerMap[record.customerId];
        final customerName = customer?.name.toLowerCase() ?? '';
        final description = record.description.toLowerCase();

        return customerName.contains(searchQuery) ||
            description.contains(searchQuery);
      }).toList();
    }

    // Apply status filter
    switch (currentFilter) {
      case RecordFilter.paid:
        filtered = filtered.where((record) => record.isPaid).toList();
        break;
      case RecordFilter.pending:
        filtered = filtered.where((record) => !record.isPaid &&
            !_isOverdue(record)).toList();
        break;
      case RecordFilter.overdue:
        filtered = filtered.where((record) => !record.isPaid &&
            _isOverdue(record)).toList();
        break;
      case RecordFilter.all:
        break;
    }

    // Apply sorting
    switch (currentSort) {
      case SortBy.dateDesc:
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortBy.dateAsc:
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortBy.amountDesc:
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case SortBy.amountAsc:
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }

    setState(() {
      filteredRecords = filtered;
    });
  }

  bool _isOverdue(Record record) {
    return !record.isPaid &&
        record.date.isBefore(DateTime.now().subtract(const Duration(days: 30)));
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Filter Options
            const Text(
              'Filter by Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: RecordFilter.values.map((filter) {
                return FilterChip(
                  label: Text(_getFilterLabel(filter)),
                  selected: currentFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      currentFilter = filter;
                      _applyFiltersAndSearch();
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF2E7D32),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Sort Options
            const Text(
              'Sort by',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: SortBy.values.map((sort) {
                return FilterChip(
                  label: Text(_getSortLabel(sort)),
                  selected: currentSort == sort,
                  onSelected: (selected) {
                    setState(() {
                      currentSort = sort;
                      _applyFiltersAndSearch();
                    });
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFF43A047).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF43A047),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(RecordFilter filter) {
    switch (filter) {
      case RecordFilter.all:
        return 'All Records';
      case RecordFilter.paid:
        return 'Paid';
      case RecordFilter.pending:
        return 'Pending';
      case RecordFilter.overdue:
        return 'Overdue';
    }
  }

  String _getSortLabel(SortBy sort) {
    switch (sort) {
      case SortBy.dateDesc:
        return 'Newest First';
      case SortBy.dateAsc:
        return 'Oldest First';
      case SortBy.amountDesc:
        return 'Highest Amount';
      case SortBy.amountAsc:
        return 'Lowest Amount';
    }
  }

  void _navigateToRecordDetail(Record record) {
    // Navigate to record detail screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => RecordDetailScreen(isar: widget.isar, recordId: record.id)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to ${record.description} details')),
    );
  }

  void _navigateToCustomerDetail(int customerId) {
    // Navigate to customer detail screen
    // Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerDetailScreen(isar: widget.isar, customerId: customerId)));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to customer $customerId details')),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            'All Records',
            selectedFilter == 'all',
                () => _updateFilter('all'),
            const Color(0xFF1976D2),
            Icons.receipt_long,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Paid',
            selectedFilter == 'paid',
                () => _updateFilter('paid'),
            const Color(0xFF388E3C),
            Icons.check_circle,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Pending',
            selectedFilter == 'pending',
                () => _updateFilter('pending'),
            Colors.orange,
            Icons.schedule,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Overdue',
            selectedFilter == 'overdue',
                () => _updateFilter('overdue'),
            Colors.red,
            Icons.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap, Color color, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Add these variables to your class
  String selectedFilter = 'all';

// Add this method to handle filter updates
  void _updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    _applyFilter();
  }

// Add this method to apply the filter logic
  void _applyFilter() {
    setState(() {
      switch (selectedFilter) {
        case 'paid':
          filteredRecords = allRecords.where((r) => r.isPaid).toList();
          break;
        case 'pending':
          filteredRecords = allRecords.where((r) => !r.isPaid && !_isOverdue(r)).toList();
          break;
        case 'overdue':
          filteredRecords = allRecords.where((r) => _isOverdue(r)).toList();
          break;
        case 'all':
        default:
          filteredRecords = List.from(allRecords);
          break;
      }
    });
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.customerId != null ? 'Customer Records' : 'All Records'),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (currentFilter != RecordFilter.all || currentSort != SortBy.dateDesc)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          // Container(
          //   color: const Color(0xFF2E7D32),
          //   padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          //   child: TextField(
          //     controller: _searchController,
          //     decoration: InputDecoration(
          //       hintText: 'Search by customer name or description...',
          //       prefixIcon: const Icon(Icons.search, color: Colors.grey),
          //       suffixIcon: searchQuery.isNotEmpty
          //           ? IconButton(
          //         onPressed: () {
          //           _searchController.clear();
          //         },
          //         icon: const Icon(Icons.clear, color: Colors.grey),
          //       )
          //           : null,
          //       filled: true,
          //       fillColor: Colors.white,
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(25),
          //         borderSide: BorderSide.none,
          //       ),
          //       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          //     ),
          //   ),
          // ),

          // Summary Cards
          // const SizedBox(height: 16),
          _buildFilterButton(),
          const SizedBox(height: 16),

          // Active Filters Display
          if (currentFilter != RecordFilter.all || searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (currentFilter != RecordFilter.all)
                    Chip(
                      label: Text(_getFilterLabel(currentFilter)),
                      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          currentFilter = RecordFilter.all;
                          _applyFiltersAndSearch();
                        });
                      },
                    ),
                  if (searchQuery.isNotEmpty)
                    Chip(
                      label: Text('Search: "$searchQuery"'),
                      backgroundColor: const Color(0xFF43A047).withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        _searchController.clear();
                      },
                    ),
                ],
              ),
            ),

          // Records List
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
                : filteredRecords.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: filteredRecords.length,
              itemBuilder: (context, index) {
                final record = filteredRecords[index];
                final customer = customerMap[record.customerId];
                return _buildRecordItem(record, customer);
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFilterButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // Your filter logic here
            _showFilterOptions();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1976D2),
                  const Color(0xFF1565C0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Records',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? 'No records found for "$searchQuery"'
                : 'No records available',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty
                ? 'Try different search terms or clear filters'
                : 'Records will appear here once you add them',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (searchQuery.isNotEmpty || currentFilter != RecordFilter.all)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    currentFilter = RecordFilter.all;
                    _applyFiltersAndSearch();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text(
                  'Clear All Filters',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(Record record, Customer? customer) {
    final isOverdue = !record.isPaid &&
        record.date.isBefore(DateTime.now().subtract(const Duration(days: 30)));

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => RecordDetailScreen(isar: widget.isar, recordId: record.id),)).then((value) {
          _loadRecords();
        },);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Record Status Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: record.isPaid ? const Color(0xFF388E3C) :
                      isOverdue ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      record.isPaid ? Icons.check_circle : Icons.receipt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Record Date & Time
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(record.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('hh:mm a').format(record.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // View Image Button (only if image exists)
                  // if (record.imagePath != null)
                  //   Container(
                  //     margin: const EdgeInsets.only(right: 8),
                  //     child: InkWell(
                  //       onTap: () {
                  //         // Show full image in dialog or navigate to image viewer
                  //         _showImageDialog(record.imagePath!);
                  //       },
                  //       borderRadius: BorderRadius.circular(8),
                  //       child: Container(
                  //         padding: const EdgeInsets.all(8),
                  //         decoration: BoxDecoration(
                  //           color: Colors.grey[100],
                  //           borderRadius: BorderRadius.circular(8),
                  //           border: Border.all(color: Colors.grey[300]!),
                  //         ),
                  //         child: Row(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             Icon(
                  //               Icons.image,
                  //               size: 16,
                  //               color: Colors.grey[700],
                  //             ),
                  //             const SizedBox(width: 4),
                  //             Text(
                  //               'View',
                  //               style: TextStyle(
                  //                 fontSize: 12,
                  //                 color: Colors.grey[700],
                  //                 fontWeight: FontWeight.w500,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: record.isPaid ? const Color(0xFF388E3C) :
                      isOverdue ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.isPaid ? 'PAID' :
                      isOverdue ? 'OVERDUE' : 'PENDING',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              // Text(
              //   record.description,
              //   style: const TextStyle(
              //     fontSize: 16,
              //     fontWeight: FontWeight.w600,
              //     color: Colors.black87,
              //   ),
              //   maxLines: 2,
              //   overflow: TextOverflow.ellipsis,
              // ),
              //
              // const SizedBox(height: 12),

              // Amount Details - Horizontal Layout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Total Amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,###').format(record.totalAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),

                    // Paid Amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Paid',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,###').format(record.paidAmount)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF388E3C),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),

                    // Due Amount
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Due',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${NumberFormat('#,##,###').format(record.leftAmount)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: record.leftAmount > 0 ?
                              (isOverdue ? Colors.red : Colors.orange) :
                              const Color(0xFF388E3C),
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
        ),
      ),
    );
  }

// Helper method to show image dialog
  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Image
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Image not found',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}