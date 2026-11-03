import 'package:flutter/foundation.dart';

/// Notifies screens that data stored by the local database has changed.
class DatabaseEvents {
  DatabaseEvents._();

  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void changed() => revision.value++;
}
