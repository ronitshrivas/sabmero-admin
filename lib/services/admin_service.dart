import '../core/api_client.dart';
import '../models/models.dart';

// Wraps every admin-facing endpoint used by the panel. Each method returns
// either typed data or an ApiResult for action calls (approve/assign/etc).
class AdminService {
  final _api = ApiClient.instance;

  List<Map<String, dynamic>> _list(dynamic data) =>
      ((data as List?) ?? []).whereType<Map<String, dynamic>>().toList();

  // ── Dashboard ──
  Future<DashboardStats?> dashboard() async {
    final res = await _api.get('/admin/dashboard');
    if (!res.ok || res.data is! Map) return null;
    return DashboardStats.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Users ──
  Future<List<AdminUser>> users({String? role, String? search}) async {
    final res = await _api.get(
      '/admin/users',
      query: {
        if (role != null && role.isNotEmpty) 'role': role,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _list(res.data).map(AdminUser.fromJson).toList();
  }

  Future<ApiResult> setUserActive(int id, bool active) =>
      _api.put('/admin/users/$id/active', body: {'isActive': active});

  Future<ApiResult> reviewKyc(
    int id,
    bool verified, {
    String? rejectionReason,
  }) => _api.put(
    '/admin/users/$id/kyc',
    body: {
      'verified': verified,
      if (!verified) 'rejectionReason': rejectionReason ?? '',
    },
  );

  Future<ApiResult> createStaff({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String address = '',
  }) => _api.post(
    '/admin/staff',
    body: {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'role': role,
      'address': address,
    },
  );

  // ── Vendor requests ──
  Future<List<VendorRequest>> vendorRequests({String? status}) async {
    final res = await _api.get(
      '/admin/vendor-requests',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    return _list(res.data).map(VendorRequest.fromJson).toList();
  }

  Future<ApiResult> reviewVendorRequest(
    int id, {
    required bool approved,
    double? commissionRate,
    String? rejectionReason,
  }) => _api.put(
    '/admin/vendor-requests/$id/review',
    body: {
      'approved': approved,
      if (commissionRate != null) 'commissionRate': commissionRate,
      if (!approved) 'rejectionReason': rejectionReason ?? '',
    },
  );

  Future<List<Vendor>> vendors({bool onlyPending = false}) async {
    final res = await _api.get(
      '/admin/vendors',
      query: {'onlyPending': onlyPending},
    );
    return _list(res.data).map(Vendor.fromJson).toList();
  }

  // ── Orders ──
  Future<List<OrderRow>> orders({String? status}) async {
    final res = await _api.get(
      '/admin/orders',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    return _list(res.data).map(OrderRow.fromJson).toList();
  }

  Future<ApiResult> assignRider(int orderId, int riderId) => _api.put(
    '/admin/orders/$orderId/assign-rider',
    body: {'riderId': riderId},
  );

  // ── Bookings ──
  Future<List<BookingRow>> bookings({String? status}) async {
    final res = await _api.get(
      '/admin/bookings',
      query: {if (status != null && status.isNotEmpty) 'status': status},
    );
    return _list(res.data).map(BookingRow.fromJson).toList();
  }

  Future<ApiResult> assignTechnician(int bookingId, int technicianId) =>
      _api.put(
        '/admin/bookings/$bookingId/assign-tech',
        body: {'technicianId': technicianId},
      );

  // ── Categories (public GET, admin writes) ──
  Future<List<CategoryRow>> categories() async {
    final res = await _api.get('/Categories', query: {'includeInactive': true});
    return _list(res.data).map(CategoryRow.fromJson).toList();
  }

  Future<ApiResult> createCategory(String name, {String? imagePath}) =>
      _api.post('/Categories', body: {'name': name, 'imagePath': imagePath});

  Future<ApiResult> updateCategory(
    int id,
    String name,
    bool isActive, {
    String? imagePath,
  }) => _api.put(
    '/Categories/$id',
    body: {'name': name, 'isActive': isActive, 'imagePath': imagePath},
  );

  Future<ApiResult> deleteCategory(int id) => _api.delete('/Categories/$id');

  // ── Promos ──
  Future<List<PromoRow>> promos() async {
    final res = await _api.get('/Promos');
    return _list(res.data).map(PromoRow.fromJson).toList();
  }

  Future<ApiResult> createPromo(
    String code,
    double discountPercent,
    String expiresAtIso,
  ) => _api.post(
    '/Promos',
    body: {
      'code': code,
      'discountPercent': discountPercent,
      'expiresAt': expiresAtIso,
    },
  );

  Future<ApiResult> deletePromo(int id) => _api.delete('/Promos/$id');

  // ── Returns ──
  Future<List<ReturnRow>> returns() async {
    final res = await _api.get('/Returns');
    return _list(res.data).map(ReturnRow.fromJson).toList();
  }

  Future<ApiResult> resolveReturn(int id, String status, {String? adminNote}) =>
      _api.put(
        '/Returns/$id/resolve',
        body: {'status': status, 'adminNote': adminNote},
      );

  // ── Payments ──
  // Current QR image path ("" when not set yet).
  Future<String> getQrPath() async {
    final res = await _api.get('/Payments/qr');
    final data = res.data;
    return (data is Map) ? (data['qrImagePath']?.toString() ?? '') : '';
  }

  // Set/replace the global payment QR (path from an upload).
  Future<({bool ok, String message})> setQr(String path) async {
    final res = await _api.put('/Payments/qr', body: {'qrImagePath': path});
    return (
      ok: res.ok,
      message: res.message ?? (res.ok ? 'QR updated.' : 'Failed.'),
    );
  }

  // Upload the QR image bytes → server path.
  Future<({bool ok, String message, String? path})> uploadQrImage(
    List<int> bytes,
    String filename,
  ) async {
    final res = await _api.uploadBytes('/Uploads/payment', bytes, filename);
    if (!res.ok)
      return (ok: false, message: res.message ?? 'Upload failed.', path: null);
    final data = res.data;
    final path = (data is Map) ? data['path']?.toString() : null;
    return path == null || path.isEmpty
        ? (
            ok: false,
            message: 'Upload succeeded but no path returned.',
            path: null,
          )
        : (ok: true, message: 'Uploaded.', path: path);
  }

  Future<List<Map<String, dynamic>>> pendingPayments() async {
    final res = await _api.get('/Payments/pending');
    return _list(res.data);
  }

  Future<ApiResult> verifyPayment(
    String type,
    int bookingOrOrderId,
    bool approved,
  ) => _api.post(
    '/Payments/verify',
    body: {'type': type, 'id': bookingOrOrderId, 'approve': approved},
  );
}
