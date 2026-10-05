import 'package:isar/isar.dart';

part 'record.g.dart';

@Collection()
class Record {
  Id id = Isar.autoIncrement;

  // Link to the customer
  late int customerId;

  // Description of the item or purpose
  late String description;

  // Amount expected (Total amount)
  double totalAmount = 0;

  // Amount paid so far
  double paidAmount = 0;

  double leftAmount = 0;
  // Is this record completely paid off?
  bool isPaid = false;

  // When the transaction was made
  DateTime date = DateTime.now();

  // Optional image path (bill/product)
  String? imagePath;
}
