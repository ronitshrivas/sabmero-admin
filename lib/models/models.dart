// Plain models mapping the backend's JSON. Every fromJson is null-tolerant so a
// missing field never crashes the table that renders it.

T? _as<T>(dynamic v) => v is T ? v : null;

int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);
double _dbl(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
bool _bool(dynamic v) => v == true;
String _str(dynamic v) => v?.toString() ?? '';

class DashboardStats {
  final int totalUsers, totalCustomers, totalVendors, pendingVendors;
  final int totalTechnicians, totalRiders, totalProducts, totalCategories;
  final int totalOrders, pendingOrders, deliveredOrders;
  final int totalBookings, pendingBookings, pendingReturns;
  final double totalSales, totalCommission;

  DashboardStats.fromJson(Map<String, dynamic> j)
      : totalUsers = _int(j['totalUsers']),
        totalCustomers = _int(j['totalCustomers']),
        totalVendors = _int(j['totalVendors']),
        pendingVendors = _int(j['pendingVendors']),
        totalTechnicians = _int(j['totalTechnicians']),
        totalRiders = _int(j['totalRiders']),
        totalProducts = _int(j['totalProducts']),
        totalCategories = _int(j['totalCategories']),
        totalOrders = _int(j['totalOrders']),
        pendingOrders = _int(j['pendingOrders']),
        deliveredOrders = _int(j['deliveredOrders']),
        totalBookings = _int(j['totalBookings']),
        pendingBookings = _int(j['pendingBookings']),
        pendingReturns = _int(j['pendingReturns']),
        totalSales = _dbl(j['totalSales']),
        totalCommission = _dbl(j['totalCommission']);
}

class AdminUser {
  final int id;
  final String fullName, phone, role, kycStatus;
  final String? email, kycRejectionReason, kycDocumentPath;
  final bool isKycVerified, isActive;
  final String createdAt;

  AdminUser.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        fullName = _str(j['fullName']),
        phone = _str(j['phone']),
        role = _str(j['role']),
        kycStatus = _str(j['kycStatus']).isEmpty ? 'NotSubmitted' : _str(j['kycStatus']),
        email = _as<String>(j['email']),
        kycRejectionReason = _as<String>(j['kycRejectionReason']),
        kycDocumentPath = _as<String>(j['kycDocumentPath']),
        isKycVerified = _bool(j['isKycVerified']),
        isActive = _bool(j['isActive']),
        createdAt = _str(j['createdAt']);
}

class VendorRequest {
  final int id, userId;
  final String ownerName, phone, businessName, businessAddress, status;
  final String? businessDocumentPath, citizenshipDocumentPath, nidDocumentPath, rejectionReason, reviewedAt;
  final int? vendorId;
  final String createdAt;

  VendorRequest.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        userId = _int(j['userId']),
        ownerName = _str(j['ownerName']),
        phone = _str(j['phone']),
        businessName = _str(j['businessName']),
        businessAddress = _str(j['businessAddress']),
        status = _str(j['status']),
        businessDocumentPath = _as<String>(j['businessDocumentPath']),
        citizenshipDocumentPath = _as<String>(j['citizenshipDocumentPath']),
        nidDocumentPath = _as<String>(j['nidDocumentPath']),
        rejectionReason = _as<String>(j['rejectionReason']),
        reviewedAt = _as<String>(j['reviewedAt']),
        vendorId = _as<int>(j['vendorId']) ?? (j['vendorId'] is num ? (j['vendorId'] as num).toInt() : null),
        createdAt = _str(j['createdAt']);
}

class Vendor {
  final int id, userId, productCount;
  final String ownerName, phone, businessName, businessAddress;
  final bool isApproved;
  final double commissionRate;
  final String createdAt;

  Vendor.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        userId = _int(j['userId']),
        productCount = _int(j['productCount']),
        ownerName = _str(j['ownerName']),
        phone = _str(j['phone']),
        businessName = _str(j['businessName']),
        businessAddress = _str(j['businessAddress']),
        isApproved = _bool(j['isApproved']),
        commissionRate = _dbl(j['commissionRate']),
        createdAt = _str(j['createdAt']);
}

class OrderItemRow {
  final String productName;
  final int quantity;
  final double unitPrice, lineTotal;
  OrderItemRow.fromJson(Map<String, dynamic> j)
      : productName = _str(j['productName']),
        quantity = _int(j['quantity']),
        unitPrice = _dbl(j['unitPrice']),
        lineTotal = _dbl(j['lineTotal']);
}

class OrderRow {
  final int id, userId;
  final int? riderId, installationBookingId;
  final String customerName, paymentMethod, paymentStatus, status, deliveryAddress, createdAt;
  final String? riderName, promoCode;
  final double subTotal, discount, totalAmount, commissionAmount;
  final List<OrderItemRow> items;

  OrderRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        userId = _int(j['userId']),
        riderId = _as<int>(j['riderId']),
        installationBookingId = _as<int>(j['installationBookingId']),
        customerName = _str(j['customerName']),
        paymentMethod = _str(j['paymentMethod']),
        paymentStatus = _str(j['paymentStatus']),
        status = _str(j['status']),
        deliveryAddress = _str(j['deliveryAddress']),
        createdAt = _str(j['createdAt']),
        riderName = _as<String>(j['riderName']),
        promoCode = _as<String>(j['promoCode']),
        subTotal = _dbl(j['subTotal']),
        discount = _dbl(j['discount']),
        totalAmount = _dbl(j['totalAmount']),
        commissionAmount = _dbl(j['commissionAmount']),
        items = ((j['items'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(OrderItemRow.fromJson)
            .toList();
}

class BookingRow {
  final int id, userId;
  final int? technicianId, relatedOrderId;
  final String serviceType, status, timeSlot, serviceAddress, paymentMethod, createdAt;
  final String? bookingDate;
  final double? serviceCharge;
  final String customerName, customerPhone;
  final String? description, damageImagePath, paymentScreenshotPath;
  final List<String> damageImagePaths;

  BookingRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        userId = _int(j['userId']),
        technicianId = _as<int>(j['technicianId']),
        relatedOrderId = _as<int>(j['relatedOrderId']),
        serviceType = _str(j['serviceType']),
        status = _str(j['status']),
        timeSlot = _str(j['timeSlot']),
        serviceAddress = _str(j['serviceAddress']),
        paymentMethod = _str(j['paymentMethod']),
        createdAt = _str(j['createdAt']),
        bookingDate = _as<String>(j['bookingDate']),
        serviceCharge = j['serviceCharge'] == null ? null : _dbl(j['serviceCharge']),
        customerName = _str(j['customerName']),
        customerPhone = _str(j['customerPhone']),
        description = _as<String>(j['description']),
        damageImagePath = _as<String>(j['damageImagePath']),
        paymentScreenshotPath = _as<String>(j['paymentScreenshotPath']),
        damageImagePaths = ((j['damageImagePaths'] as List?) ?? const [])
            .whereType<String>()
            .toList();
}

class CategoryRow {
  final int id, productCount;
  final String name;
  final String? imagePath;
  final bool isActive;
  CategoryRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        productCount = _int(j['productCount']),
        name = _str(j['name']),
        imagePath = _as<String>(j['imagePath']),
        isActive = _bool(j['isActive']);
}

class PromoRow {
  final int id;
  final String code, expiresAt;
  final double discountPercent;
  final bool isActive;
  PromoRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        code = _str(j['code']),
        expiresAt = _str(j['expiresAt']),
        discountPercent = _dbl(j['discountPercent']),
        isActive = _bool(j['isActive']);
}

class ReturnRow {
  final int id, orderId;
  final String reason, status, createdAt;
  final String? adminNote;
  ReturnRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        orderId = _int(j['orderId']),
        reason = _str(j['reason']),
        status = _str(j['status']),
        createdAt = _str(j['createdAt']),
        adminNote = _as<String>(j['adminNote']);
}

// ── Vendor commission / settlement payouts (admin side) ──────────────────────
// GET /api/vendor-payments/vendors → list of vendors to pay (with QR + totals).
class VendorPayoutSummary {
  final int vendorId;
  final String businessName, ownerName, phone;
  final String? paymentQrPath;
  final double commissionRate, totalPaid;
  final String? lastPaidAt;

  VendorPayoutSummary.fromJson(Map<String, dynamic> j)
      : vendorId = _int(j['vendorId']),
        businessName = _str(j['businessName']),
        ownerName = _str(j['ownerName']),
        phone = _str(j['phone']),
        paymentQrPath = _as<String>(j['paymentQrPath']),
        commissionRate = _dbl(j['commissionRate']),
        totalPaid = _dbl(j['totalPaid']),
        lastPaidAt = _as<String>(j['lastPaidAt']);

  bool get hasQr => paymentQrPath != null && paymentQrPath!.isNotEmpty;
}

// GET /api/vendor-payments/history → one recorded payment row.
class VendorPaymentRow {
  final int id, vendorId;
  final String vendorName, ownerName, phone, status, createdAt;
  final double amount;
  final String? note, screenshotPath, acknowledgedAt;

  VendorPaymentRow.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        vendorId = _int(j['vendorId']),
        vendorName = _str(j['vendorName']),
        ownerName = _str(j['ownerName']),
        phone = _str(j['phone']),
        status = (_str(j['status']).isEmpty ? 'Paid' : _str(j['status'])),
        createdAt = _str(j['createdAt']),
        amount = _dbl(j['amount']),
        note = _as<String>(j['note']),
        screenshotPath = _as<String>(j['screenshotPath']),
        acknowledgedAt = _as<String>(j['acknowledgedAt']);

  bool get isAcknowledged => status == 'Acknowledged';
}

// ── Delivery charge settings (admin-configurable) ────────────────────────────
// GET /api/settings/delivery → { deliveryFee, freeDeliveryAbove }.
class DeliverySettings {
  final double deliveryFee;
  final double freeDeliveryAbove;

  DeliverySettings.fromJson(Map<String, dynamic> j)
      : deliveryFee = _dbl(j['deliveryFee']),
        freeDeliveryAbove = _dbl(j['freeDeliveryAbove']);
}

// ── Repair service catalog (admin-managed) ───────────────────────────────────
class ServiceCatalogItem {
  final int id;
  final String name;
  final String? description;
  final String? imagePath;
  final double charge;
  final bool isActive;

  ServiceCatalogItem.fromJson(Map<String, dynamic> j)
      : id = _int(j['id']),
        name = _str(j['name']),
        description = _as<String>(j['description']),
        imagePath = _as<String>(j['imagePath']),
        charge = _dbl(j['charge']),
        isActive = _bool(j['isActive']);
}
