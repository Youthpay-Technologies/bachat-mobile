import 'package:sembast/sembast_memory.dart';

Future<Database> openDatabase() => databaseFactoryMemory.openDatabase('bachat');
