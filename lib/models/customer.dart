import 'package:isar/isar.dart';

part 'customer.g.dart';

@Collection()
class Customer {
  Id id = Isar.autoIncrement;

  late String name;
  late String phone;
  String? address;
  String? imagePath;

  double totalPaid = 0;
  double totalDue = 0;
}
