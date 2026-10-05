import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';
import '../models/record.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [CustomerSchema, RecordSchema],
      directory: dir.path,
      name: 'mydata', // 👈 MATCHES the filename you try to export
    );
  }

  // Add a new customer
  Future<void> addCustomer(Customer customer) async {
    final isar = await db;
    await isar.writeTxn(() => isar.customers.put(customer));
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    final isar = await db;
    return await isar.customers.where().findAll();
  }

  // ✅ Total Earnings: Sum of all paid amounts
  Future<double> getTotalEarnings() async {
    final isar = await db;
    final records = await isar.records.filter().isPaidEqualTo(true).findAll();
    double total = 0;
    for (var record in records) {
      total += record.paidAmount;
    }
    return total;
  }

  Future<double> getTotalOutstandingDues() async {
    final isar = await db;
    final records = await isar.records.filter().isPaidEqualTo(false).findAll();
    double total = 0;
    for (var record in records) {
      total += record.leftAmount;
    }
    return total;
  }
  Future<double> getTotalAmount() async {
    final isar = await db;
    final records = await isar.records.where().findAll();
    double total = 0;
    for (var record in records) {
      total += record.totalAmount;
    }
    return total;
  }

  Future<int> getTotalCustomers() async {
    final isar = await db;
    return await isar.customers.where().count();
  }

  Future<int> getTotalPendingPaymentsCount() async {
    final isar = await db;
    return await isar.records.filter().isPaidEqualTo(false).count();
  }

}
