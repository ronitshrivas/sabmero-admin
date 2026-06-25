import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/token_store.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((_) => AuthService());
final adminServiceProvider = Provider((_) => AdminService());

// Whether someone is logged in (drives the login gate).
final authStateProvider = FutureProvider<bool>((ref) async {
  final token = await TokenStore.token();
  return token != null && token.isNotEmpty;
});

final adminNameProvider = FutureProvider<String>((ref) async {
  return (await TokenStore.name()) ?? 'Admin';
});

// ── Data providers. Each is auto-refreshable via ref.invalidate(...). ──

final dashboardProvider = FutureProvider<DashboardStats?>((ref) {
  return ref.read(adminServiceProvider).dashboard();
});

// Users with an optional (role, search) filter argument.
final usersProvider = FutureProvider.family<List<AdminUser>, ({String? role, String? search})>(
  (ref, args) => ref.read(adminServiceProvider).users(role: args.role, search: args.search),
);

final vendorRequestsProvider = FutureProvider.family<List<VendorRequest>, String?>(
  (ref, status) => ref.read(adminServiceProvider).vendorRequests(status: status),
);

final vendorsProvider = FutureProvider<List<Vendor>>(
  (ref) => ref.read(adminServiceProvider).vendors(),
);

final ordersProvider = FutureProvider.family<List<OrderRow>, String?>(
  (ref, status) => ref.read(adminServiceProvider).orders(status: status),
);

final bookingsProvider = FutureProvider.family<List<BookingRow>, String?>(
  (ref, status) => ref.read(adminServiceProvider).bookings(status: status),
);

final categoriesProvider = FutureProvider<List<CategoryRow>>(
  (ref) => ref.read(adminServiceProvider).categories(),
);

final promosProvider = FutureProvider<List<PromoRow>>(
  (ref) => ref.read(adminServiceProvider).promos(),
);

final returnsProvider = FutureProvider<List<ReturnRow>>(
  (ref) => ref.read(adminServiceProvider).returns(),
);

// Riders & technicians, derived from the users list (used in assign dialogs).
final ridersProvider = FutureProvider<List<AdminUser>>(
  (ref) => ref.read(adminServiceProvider).users(role: 'Rider'),
);

final techniciansProvider = FutureProvider<List<AdminUser>>(
  (ref) => ref.read(adminServiceProvider).users(role: 'Technician'),
);
