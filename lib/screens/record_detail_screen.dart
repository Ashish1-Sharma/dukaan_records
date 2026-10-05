import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:intl/intl.dart';
import 'package:mydukaan_records/models/customer.dart';
import 'package:mydukaan_records/models/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// Assuming your models are imported
// import 'customer.dart';
// import 'record.dart';

class RecordDetailScreen extends StatefulWidget {
  final Isar isar;
  final int recordId;

  const RecordDetailScreen({
    super.key,
    required this.isar,
    required this.recordId,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  Record? record;
  Customer? customer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordData();
  }

  Future<void> _loadRecordData() async {
    try {
      // Load record
      final recordData = await widget.isar.records
          .where()
          .idEqualTo(widget.recordId)
          .findFirst();

      if (recordData != null) {
        // Load associated customer
        final customerData = await widget.isar.customers
            .where()
            .idEqualTo(recordData.customerId)
            .findFirst();

        setState(() {
          record = recordData;
          customer = customerData;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _makeCall() async {
    if (customer?.phone != null) {
      final Uri phoneUri = Uri(scheme: 'tel', path: customer!.phone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
  }

  void _shareRecord() {
    if (record != null && customer != null) {
      final String shareText = '''
📋 *Record Details*

👤 Customer: ${customer!.name}
📱 Phone: ${customer!.phone}
📝 Description: ${record!.description}
💰 Total Amount: ₹${NumberFormat('#,##,###').format(record!.totalAmount)}
💸 Paid Amount: ₹${NumberFormat('#,##,###').format(record!.paidAmount)}
🔄 Remaining: ₹${NumberFormat('#,##,###').format(record!.leftAmount)}
📅 Date: ${DateFormat('dd MMM yyyy, hh:mm a').format(record!.date)}
✅ Status: ${record!.isPaid ? 'PAID' : 'PENDING'}

Generated from Vyapar Ledger
''';
      Share.share(shareText);
    }
  }

  void _editRecord() {
    // Navigate to edit record screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Record Screen - To be implemented')),
    );
  }

  void _markAsPaid() async {
    if (record != null && !record!.isPaid) {
      // Update record as paid
      final leftAmount = record!.leftAmount;
      record!.isPaid = true;
      record!.paidAmount = record!.totalAmount;
      record!.leftAmount = 0;

      await widget.isar.writeTxn(() async {
        await widget.isar.records.put(record!);
      });

      setState(() {});
      customer!.totalPaid += leftAmount;
      customer!.totalDue -= leftAmount;
      await widget.isar.writeTxn(() async {
        await widget.isar.customers.put(customer!);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record marked as paid!'),
          backgroundColor: Color(0xFF388E3C),
        ),
      );
    }
  }

  void _addPayment() {
    // Show dialog to add partial payment
    _showAddPaymentDialog();
  }

  void _showAddPaymentDialog() {
    if (record == null) return;

    final TextEditingController amountController = TextEditingController();
    final double remainingAmount = record!.leftAmount;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remaining Amount: ₹${NumberFormat('#,##,###').format(remainingAmount)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double paymentAmount = double.tryParse(amountController.text) ?? 0;
                if (paymentAmount > 0 && paymentAmount <= remainingAmount) {
                  // Update record
                  record!.paidAmount += paymentAmount;
                  record!.leftAmount = record!.totalAmount - record!.paidAmount;
                  record!.isPaid = record!.leftAmount == 0;

                  await widget.isar.writeTxn(() async {
                    await widget.isar.records.put(record!);
                  });

                  setState(() {});
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ₹${NumberFormat('#,##,###').format(paymentAmount)} added!'),
                      backgroundColor: const Color(0xFF388E3C),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              child: const Text('Add Payment', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    if (record == null || customer == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Record not found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final bool isOverdue = !record!.isPaid &&
        record!.date.isBefore(DateTime.now().subtract(const Duration(days: 30)));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Record Details'),
        actions: [
          IconButton(
            onPressed: _shareRecord,
            icon: const Icon(Icons.share),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _editRecord,
                child: const Row(
                  children: [
                    Icon(Icons.edit, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Edit Record'),
                  ],
                ),
              ),
              if (!record!.isPaid)
                PopupMenuItem(
                  onTap: _markAsPaid,
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF388E3C)),
                      SizedBox(width: 8),
                      Text('Mark as Paid'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header (Customer Info)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Customer Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: customer!.imagePath != null
                        ? ClipOval(
                      child: Image.asset(
                        customer!.imagePath!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.white),
                      ),
                    )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),

                  // Customer Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer!.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy • hh:mm a').format(record!.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Call Button
                  IconButton(
                    onPressed: _makeCall,
                    icon: const Icon(Icons.call, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),

            // Record Image (if available)
            if (record!.imagePath != null)
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey[200],
                child: Image.asset(
                  record!.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                ),
              ),

            // Record Actions (Instagram-like)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: record!.isPaid ? const Color(0xFF388E3C) :
                      isOverdue ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          record!.isPaid ? Icons.check_circle : Icons.schedule,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          record!.isPaid ? 'PAID' :
                          isOverdue ? 'OVERDUE' : 'PENDING',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Action Buttons
                  if (!record!.isPaid) ...[
                    TextButton.icon(
                      onPressed: _addPayment,
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('Add Payment'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Record Details
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    record!.description,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _buildAmountRow(
                          'Total Amount',
                          '₹${NumberFormat('#,##,###').format(record!.totalAmount)}',
                          Colors.black87,
                          FontWeight.bold,
                        ),
                        const SizedBox(height: 8),
                        _buildAmountRow(
                          'Paid Amount',
                          '₹${NumberFormat('#,##,###').format(record!.paidAmount)}',
                          const Color(0xFF388E3C),
                          FontWeight.w600,
                        ),
                        const SizedBox(height: 8),
                        _buildAmountRow(
                          'Remaining Amount',
                          '₹${NumberFormat('#,##,###').format(record!.leftAmount)}',
                          record!.leftAmount > 0 ?
                          (isOverdue ? Colors.red : Colors.orange) :
                          const Color(0xFF388E3C),
                          FontWeight.w600,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Additional Info
                  if (customer!.address != null && customer!.address!.isNotEmpty)
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Address',
                      customer!.address!,
                    ),

                  _buildInfoRow(
                    Icons.phone_outlined,
                    'Phone',
                    customer!.phone,
                  ),

                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'Created',
                    DateFormat('EEEE, dd MMMM yyyy • hh:mm a').format(record!.date),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: !record!.isPaid
          ? FloatingActionButton.extended(
        onPressed: record!.leftAmount == record!.totalAmount ? _markAsPaid : _addPayment,
        backgroundColor: const Color(0xFF2E7D32),
        icon: Icon(
          record!.leftAmount == record!.totalAmount ? Icons.check : Icons.payment,
          color: Colors.white,
        ),
        label: Text(
          record!.leftAmount == record!.totalAmount ? 'Mark as Paid' : 'Add Payment',
          style: const TextStyle(color: Colors.white),
        ),
      )
          : null,
    );
  }

  Widget _buildAmountRow(String label, String amount, Color color, FontWeight weight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: weight,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}