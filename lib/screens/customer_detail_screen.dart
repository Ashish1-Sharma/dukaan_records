import 'dart:io';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:mydukaan_records/models/customer.dart';
import 'package:mydukaan_records/models/record.dart';
import 'package:mydukaan_records/screens/add_record_screen.dart';
import 'package:mydukaan_records/screens/customer_records_screen.dart';
import 'package:mydukaan_records/screens/record_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Modern, production-ready customer detail screen
/// Following fintech design principles: clean, minimal, trustworthy
class CustomerDetailScreen extends StatefulWidget {
  final Isar isar;
  final int customerId;

  const CustomerDetailScreen({
    super.key,
    required this.isar,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  Customer? customer;
  List<Record> recentRecords = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Modern Design System - Color Palette
  static const Color _primaryColor = Color(0xFF6C63FF); // Modern purple-blue
  static const Color _backgroundColor = Color(0xFFF8F9FD);
  static const Color _cardColor = Colors.white;
  static const Color _successColor = Color(0xFF22C55E);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _dangerColor = Color(0xFFEF4444);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadCustomerData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    setState(() => isLoading = true);

    try {
      final customerData = await widget.isar.customers
          .where()
          .idEqualTo(widget.customerId)
          .findFirst();

      final records = await widget.isar.records
          .where()
          .filter()
          .customerIdEqualTo(widget.customerId)
          .sortByDateDesc()
          .limit(5)
          .findAll();

      setState(() {
        customer = customerData;
        recentRecords = records;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (customer == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: _buildAppBar(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 64, color: _textSecondary),
              const SizedBox(height: 16),
              Text(
                'Customer not found',
                style: TextStyle(
                  fontSize: 18,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadCustomerData,
          color: _primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: _buildProfileHeader(),
              ),

              // Financial Summary Cards
              SliverToBoxAdapter(
                child: _buildFinancialSummary(),
              ),

              // Quick Actions
              SliverToBoxAdapter(
                child: _buildQuickActions(),
              ),

              // Recent Records Section
              SliverToBoxAdapter(
                child: _buildRecentRecordsHeader(),
              ),

              // Records List
              recentRecords.isEmpty
                  ? SliverFillRemaining(
                child: _buildEmptyState(),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildModernRecordCard(
                      recentRecords[index],
                      index,
                    ),
                    childCount: recentRecords.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildModernFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _cardColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        color: _textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        customer?.name ?? 'Customer Details',
        style: TextStyle(
          color: _textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_outlined, size: 22),
          color: _primaryColor,
          onPressed: _makeCall,
        ),
        PopupMenuButton(
          icon: Icon(Icons.more_vert, color: _textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: _primaryColor),
                  const SizedBox(width: 12),
                  const Text('Edit Profile'),
                ],
              ),
              onTap: _editProfile,
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: _dangerColor),
                  const SizedBox(width: 12),
                  const Text('Delete Customer'),
                ],
              ),
              onTap: _deleteCustomer,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with status indicator
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _primaryColor.withOpacity(0.1),
                      _primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.transparent,
                  child: customer!.imagePath != null
                      ? ClipOval(
                    child: Image.file(
                      File(customer!.imagePath!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                      : _buildDefaultAvatar(),
                ),
              ),

              if (customer!.totalDue == 0)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _successColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _cardColor, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Customer info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  customer!.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Phone
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        customer!.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Address (optional)
                if (customer!.address != null &&
                    customer!.address!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: _textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          customer!.address!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFinancialSummary() {
    final totalAmount = customer!.totalPaid + customer!.totalDue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Main Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Total Business',
                //   style: TextStyle(
                //     color: Colors.white.withOpacity(0.9),
                //     fontSize: 14,
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Text(
                //   '₹${_formatCurrency(totalAmount)}',
                //   style: const TextStyle(
                //     color: Colors.white,
                //     fontSize: 36,
                //     fontWeight: FontWeight.w700,
                //     letterSpacing: -1,
                //   ),
                // ),
                // const SizedBox(height: 16),
                // Divider(color: Colors.white.withOpacity(0.2), height: 1),
                // const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceIndicator(
                        'Paid',
                        customer!.totalPaid,
                        Icons.check_circle_outline,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildBalanceIndicator(
                        'Due',
                        customer!.totalDue,
                        Icons.schedule_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Payment Status Indicator
          if (customer!.totalDue > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _warningColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _warningColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment pending: ₹${_formatCurrency(customer!.totalDue)}',
                      style: TextStyle(
                        color: _warningColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _successColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: _successColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All payments cleared',
                      style: TextStyle(
                        color: _successColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(String label, double amount, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${_formatCurrency(amount)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Call',
              icon: Icons.call_outlined,
              color: _successColor,
              onPressed: () => makePhoneCall(customer!.phone),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Message',
              icon: Icons.message_outlined,
              color: _primaryColor,
              onPressed: () {
                final message =
                    "Hi ${customer!.name}, your pending balance is ₹${customer!.totalDue}. Kindly pay soon. - My Dukaan Records";
                sendSMS(customer!.phone, message);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Payment',
              icon: Icons.payment_outlined,
              color: _warningColor,
              onPressed: _showAddPaymentDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecordsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          TextButton(
            onPressed: _viewAllRecords,
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRecordCard(Record record, int index) {
    final isOverdue = !record.isPaid &&
        record.date.isBefore(
          DateTime.now().subtract(const Duration(days: 30)),
        );

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (record.isPaid) {
      statusColor = _successColor;
      statusLabel = 'Paid';
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = _dangerColor;
      statusLabel = 'Overdue';
      statusIcon = Icons.error;
    } else {
      statusColor = _warningColor;
      statusLabel = 'Pending';
      statusIcon = Icons.schedule;
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => RecordDetailScreen(
                    isar: widget.isar,
                    recordId: record.id,
                  ),
                ),
              )
                  .then((_) => _loadCustomerData());
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor, width: 1),
              ),
              child: Row(
                children: [
                  // Icon/Image container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: record.imagePath != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        record.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(statusIcon, color: statusColor, size: 28),
                      ),
                    )
                        : Icon(statusIcon, color: statusColor, size: 28),
                  ),

                  const SizedBox(width: 16),

                  // Transaction details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(record.date),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${_formatCurrency(record.totalAmount)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            if (!record.isPaid) ...[
                              Text(
                                ' • ',
                                style: TextStyle(color: _textSecondary),
                              ),
                              Text(
                                'Due: ₹${_formatCurrency(record.leftAmount)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: _textSecondary,
                  ),
                ],
              ),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first record',
            style: TextStyle(
              fontSize: 15,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _addNewRecord,
        backgroundColor: _primaryColor,
        elevation: 0,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Record',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Icon(
      Icons.person_outline,
      size: 48,
      color: _primaryColor.withOpacity(0.6),
    );
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

  // Dialog Methods
  void _showAddPaymentDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment_outlined,
                        color: _primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Payment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            'Clear pending dues',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _warningColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _warningColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _warningColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pending: ₹${_formatCurrency(customer!.totalDue)}',
                          style: TextStyle(
                            color: _warningColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: _backgroundColor,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amountText = amountController.text.trim();
                          final paidAmount = double.tryParse(amountText);

                          if (paidAmount != null && paidAmount > 0) {
                            Navigator.pop(context);
                            await _processPayment(paidAmount);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Enter a valid amount'),
                                backgroundColor: _dangerColor,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add Payment',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processPayment(double paidAmount) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Processing payment...',
                style: TextStyle(
                  fontSize: 15,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await clearDues(paidAmount);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Payment added successfully'),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Original Methods (preserved)
  Future<void> _makeCall() async {
    if (customer?.phone != null) {
      await makePhoneCall(customer!.phone);
    }
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit Customer Screen - Navigate to your existing page'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _deleteCustomer() {
    if (customer == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: _dangerColor, size: 28),
              const SizedBox(width: 12),
              const Text('Delete Customer'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${customer!.name}"?',
                style: TextStyle(fontSize: 15, color: _textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This action cannot be undone. All records associated with this customer will also be deleted.',
                  style: TextStyle(
                    color: _dangerColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final customerRecords = await widget.isar.records
                    .where()
                    .filter()
                    .customerIdEqualTo(customer!.id)
                    .findAll();

                await widget.isar.writeTxn(() async {
                  for (final record in customerRecords) {
                    await widget.isar.records.delete(record.id);
                  }
                  await widget.isar.customers.delete(customer!.id);
                });

                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${customer!.name} deleted successfully'),
                    backgroundColor: _dangerColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _dangerColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _addNewRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRecordScreen(
          preSelectedCustomer: customer!,
          isar: widget.isar,
        ),
      ),
    );
  }

  void _viewAllRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerRecordsScreen(
          customerId: widget.customerId,
          isar: widget.isar,
        ),
      ),
    );
  }

  Future<void> clearDues(double paymentAmount) async {
    final pendingRecords = await widget.isar.records
        .filter()
        .customerIdEqualTo(customer!.id)
        .sortByDate()
        .findAll();

    final unpaidRecords = pendingRecords.where((r) => r.leftAmount > 0).toList();
    double totalPaidThisSession = 0;

    await widget.isar.writeTxn(() async {
      for (final record in unpaidRecords) {
        final remainingDue = record.totalAmount - record.paidAmount;

        if (paymentAmount >= remainingDue) {
          record.paidAmount = record.totalAmount;
          record.leftAmount = 0;
          record.isPaid = true;
          paymentAmount -= remainingDue;
          totalPaidThisSession += remainingDue;
        } else {
          record.paidAmount += paymentAmount;
          record.leftAmount = record.totalAmount - record.paidAmount;
          record.isPaid = false;
          totalPaidThisSession += paymentAmount;
          paymentAmount = 0;
        }

        await widget.isar.records.put(record);
        if (paymentAmount == 0) break;
      }

      customer!.totalPaid += totalPaidThisSession;
      customer!.totalDue -= totalPaidThisSession;
      await widget.isar.customers.put(customer!);

      setState(() {
        _loadCustomerData();
      });
    });
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> sendSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri.parse(
      'sms:$phoneNumber?body=${Uri.encodeComponent(message)}',
    );
    try {
      if (!await launchUrl(smsUri)) {
        throw Exception('Could not launch SMS app');
      }
    } catch (e) {
      print("Error launching SMS: $e");
    }
  }
}