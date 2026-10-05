import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:mydukaan_records/models/customer.dart';
import 'package:mydukaan_records/screens/add_record_screen.dart';
import 'package:mydukaan_records/screens/customer_detail_screen.dart';
import 'dart:io';
import 'add_customer_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class AllCustomersScreen extends StatefulWidget {
  final Isar isar;

  const AllCustomersScreen({
    Key? key,
    required this.isar,
  }) : super(key: key);

  @override
  State<AllCustomersScreen> createState() => _AllCustomersScreenState();
}

class _AllCustomersScreenState extends State<AllCustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  CustomerSortType _sortType = CustomerSortType.name;
  bool _isAscending = true;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _filterAndSortCustomers();
    });
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await widget.isar.customers.where().findAll();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _filterAndSortCustomers();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('all_customers_screen.load_error'.tr() + ': $e', isError: true);
      }
    }
  }

  void _filterAndSortCustomers() {
    List<Customer> filtered = _allCustomers;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((customer) {
        return customer.name.toLowerCase().contains(_searchQuery) ||
            customer.phone.contains(_searchQuery) ||
            (customer.address?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      switch (_sortType) {
        case CustomerSortType.name:
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case CustomerSortType.totalDue:
          comparison = a.totalDue.compareTo(b.totalDue);
          break;
        case CustomerSortType.totalPaid:
          comparison = a.totalPaid.compareTo(b.totalPaid);
          break;
        case CustomerSortType.recentActivity:
        // Assuming you have a lastModified or createdAt field
          comparison = 0; // Implement based on your Customer model
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredCustomers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadCustomers,
        color: const Color(0xFF2E7D32),
        child: Column(
          children: [
            // if (_allCustomers.isNotEmpty) _buildStatsHeader(),
            if (_showSearchBar) _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredCustomers.isEmpty
                  ? _buildEmptyState()
                  : _buildCustomerList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1A), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'all_customers_screen.title'.tr(),
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(
            _showSearchBar ? Icons.search_off : Icons.search,
            color: const Color(0xFF1A1A1A),
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) {
                _searchController.clear();
              }
            });
          },
          tooltip: 'all_customers_screen.search_hint'.tr(),
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: Color(0xFF1A1A1A), size: 22),
          onPressed: _showSortOptions,
          tooltip: 'all_customers_screen.sort_by'.tr(),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE0E0E0),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalCustomers = _allCustomers.length;
    final totalDue = _allCustomers.fold<double>(0, (sum, customer) => sum + customer.totalDue);
    final totalPaid = _allCustomers.fold<double>(0, (sum, customer) => sum + customer.totalPaid);
    final customersWithDue = _allCustomers.where((c) => c.totalDue > 0).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'all_customers_screen.total_customers'.tr(),
                  totalCustomers.toString(),
                  Icons.people_outline,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  'all_customers_screen.debtors'.tr(),
                  customersWithDue.toString(),
                  Icons.schedule_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'all_customers_screen.total_due'.tr(),
                  '₹${_formatNumber(totalDue)}',
                  Icons.trending_up,
                  valueColor: Colors.orange.shade100,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  'all_customers_screen.total_received'.tr(),
                  '₹${_formatNumber(totalPaid)}',
                  Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
      }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: valueColor != null
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
              : EdgeInsets.zero,
          decoration: valueColor != null
              ? BoxDecoration(
            color: valueColor,
            borderRadius: BorderRadius.circular(6),
          )
              : null,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor != null ? const Color(0xFF1A1A1A) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'all_customers_screen.search_hint'.tr(),
          hintStyle: TextStyle(
            fontSize: 15,
            color: Colors.grey[400],
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCustomerList() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredCustomers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final hasOutstanding = customer.totalDue > 0;
    final hasTransactions = customer.totalPaid > 0 || customer.totalDue > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _viewCustomerDetails(customer),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasOutstanding
                  ? const Color(0xFFFF9800).withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildProfileImage(customer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasOutstanding) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'all_customers_screen.due_status'.tr(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Row(
                      //   children: [
                      //     Icon(
                      //       Icons.phone_outlined,
                      //       size: 16,
                      //       color: Colors.grey[600],
                      //     ),
                      //     const SizedBox(width: 6),
                      //     Text(
                      //       customer.phone,
                      //       style: TextStyle(
                      //         fontSize: 14,
                      //         color: Colors.grey[700],
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // if (customer.address != null && customer.address!.isNotEmpty) ...[
                      //   const SizedBox(height: 6),
                      //   Row(
                      //     children: [
                      //       Icon(
                      //         Icons.location_on_outlined,
                      //         size: 16,
                      //         color: Colors.grey[600],
                      //       ),
                      //       const SizedBox(width: 6),
                      //       Expanded(
                      //         child: Text(
                      //           customer.address!,
                      //           style: TextStyle(
                      //             fontSize: 13,
                      //             color: Colors.grey[600],
                      //           ),
                      //           maxLines: 1,
                      //           overflow: TextOverflow.ellipsis,
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ],
                      if (hasTransactions) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (customer.totalPaid > 0) ...[
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '₹${_formatNumber(customer.totalPaid)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (hasOutstanding) ...[
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF5350).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 12,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '₹${_formatNumber(customer.totalDue)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickActionButton(customer),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(Customer customer) {
    final hasOutstanding = customer.totalDue > 0;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hasOutstanding
              ? const Color(0xFFFF9800)
              : const Color(0xFF2E7D32),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasOutstanding
                ? const Color(0xFFFF9800)
                : const Color(0xFF2E7D32))
                .withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: customer.imagePath != null && customer.imagePath!.isNotEmpty
          ? ClipOval(
        child: Image.file(
          File(customer.imagePath!),
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(customer.name, hasOutstanding);
          },
        ),
      )
          : _buildDefaultAvatar(customer.name, hasOutstanding),
    );
  }

  Widget _buildDefaultAvatar(String name, bool hasOutstanding) {
    final color = hasOutstanding ? const Color(0xFFFF9800) : const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(Customer customer) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addRecordForCustomer(customer),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearching ? Icons.search_off : Icons.people_outline,
                  size: 60,
                  color: const Color(0xFF2E7D32).withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSearching
                    ? 'all_customers_screen.no_customer_found'.tr()
                    : 'all_customers_screen.no_customers_yet'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isSearching
                    ? 'all_customers_screen.try_different_search'.tr()
                    : 'all_customers_screen.add_first_customer_hint'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSearching) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.clear, size: 20),
                  label: Text(
                    'all_customers_screen.clear_search'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF2E7D32),
        strokeWidth: 3,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF2E7D32),
      onPressed: _addNewCustomer,
      elevation: 4,
      icon: const Icon(Icons.person_add_outlined, color: Colors.white, size: 22),
      label: Text(
        'all_customers_screen.new_customer'.tr(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF2E7D32),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'all_customers_screen.sort_by'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSortOption(
                'all_customers_screen.sort_name'.tr(),
                CustomerSortType.name,
                Icons.sort_by_alpha,
              ),
              _buildSortOption(
                'all_customers_screen.sort_due'.tr(),
                CustomerSortType.totalDue,
                Icons.trending_up,
              ),
              _buildSortOption(
                'all_customers_screen.sort_paid'.tr(),
                CustomerSortType.totalPaid,
                Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: const Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'all_customers_screen.order'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Switch(
                        value: _isAscending,
                        onChanged: (value) {
                          setState(() {
                            _isAscending = value;
                            _filterAndSortCustomers();
                          });
                          Navigator.pop(context);
                        },
                        activeColor: const Color(0xFF2E7D32),
                      ),
                      Text(
                        _isAscending
                            ? 'all_customers_screen.ascending'.tr()
                            : 'all_customers_screen.descending'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, CustomerSortType sortType, IconData icon) {
    final isSelected = _sortType == sortType;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _sortType = sortType;
            _filterAndSortCustomers();
          });
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32).withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewCustomerDetails(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(
          isar: widget.isar,
          customerId: customer.id,
        ),
      ),
    ).then((_) => _loadCustomers());
  }

  void _addRecordForCustomer(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecordScreen(
          isar: widget.isar,
          preSelectedCustomer: customer,
        ),
      ),
    ).then((_) => _loadCustomers());
  }

  void _addNewCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(isar: widget.isar),
      ),
    );

    if (result != null) {
      _loadCustomers();
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
        backgroundColor: isError ? const Color(0xFFEF5350) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(2)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}

enum CustomerSortType {
  name,
  totalDue,
  totalPaid,
  recentActivity,
}