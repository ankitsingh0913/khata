import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/app_constants.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/payment.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // customers Table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        totalPurchase REAL DEFAULT 0,
        pendingAmount REAL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // products Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        barcode TEXT,
        purchasePrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        lowStockAlert INTEGER DEFAULT 10,
        unit TEXT DEFAULT 'pcs',
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Bills Table
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        billNumber TEXT NOT NULL UNIQUE,
        customerId TEXT,
        customerName TEXT,
        customerPhone TEXT,
        subtotal REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL,
        paidAmount REAL DEFAULT 0,
        paymentType TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Bill Items Table
    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        billId TEXT NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount REAL DEFAULT 0,
        FOREIGN KEY (billId) REFERENCES bills (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        billId TEXT NOT NULL,
        customerId TEXT,
        amount REAL NOT NULL,
        paymentType TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (billId) REFERENCES bills (id),
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_bills_customer ON bills(customerId)');
    await db.execute('CREATE INDEX idx_bills_date ON bills(createdAt)');
    await db.execute('CREATE INDEX idx_payments_bill ON payments(billId)');
  }

  // ==================== CUSTOMER OPERATIONS ====================

  Future<String> insertCustomer(Customer customer) async {
    final db = await database;
    await db.insert('customers', customer.toMap());
    return customer.id;
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final db = await database;
    final result = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Customer.fromMap(result.first);
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(String id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateCustomerBalance(String customerId, double amount, bool isCredit) async {
    final db = await database;
    final customer = await getCustomerById(customerId);
    if (customer != null) {
      final newPending = isCredit
          ? customer.pendingAmount + amount
          : customer.pendingAmount - amount;
      final newTotal = customer.totalPurchase + (isCredit ? amount : 0);

      await db.update(
        'customers',
        {
          'pendingAmount': newPending < 0 ? 0 : newPending,
          'totalPurchase': newTotal,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
    }
  }

  Future<List<Customer>> getCustomersWithPendingAmount() async {
    final db = await database;
    final result = await db.query(
      'customers',
      where: 'pendingAmount > 0',
      orderBy: 'pendingAmount DESC',
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<String> insertProduct(Product product) async {
    final db = await database;
    await db.insert('products', product.toMap());
    return product.id;
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', where: 'isActive = 1', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(String id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: '(name LIKE ? OR barcode LIKE ?) AND isActive = 1',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> updateStock(String productId, int quantity, bool isDeduct) async {
    final db = await database;
    final product = await getProductById(productId);
    if (product != null) {
      final newStock = isDeduct ? product.stock - quantity : product.stock + quantity;
      await db.update(
        'products',
        {'stock': newStock < 0 ? 0 : newStock, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM products WHERE stock <= lowStockAlert AND isActive = 1 ORDER BY stock ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    // Soft delete
    return await db.update(
      'products',
      {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== BILL OPERATIONS ====================

  Future<String> insertBill(Bill bill) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Insert bill
      await txn.insert('bills', bill.toMap());

      // 2. Insert bill items and update stock
      for (var item in bill.items) {
        await txn.insert('bill_items', item.toMap());

        // Update stock using txn (not db!)
        final productResult = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );

        if (productResult.isNotEmpty) {
          final currentStock = productResult.first['stock'] as int? ?? 0;
          final newStock = currentStock - item.quantity;

          await txn.update(
            'products',
            {
              'stock': newStock < 0 ? 0 : newStock,
              'updatedAt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      // 3. Update customer balance if credit payment
      if (bill.customerId != null && bill.paymentType == AppConstants.paymentCredit) {
        final customerResult = await txn.query(
          'customers',
          where: 'id = ?',
          whereArgs: [bill.customerId],
        );

        if (customerResult.isNotEmpty) {
          final currentPending = (customerResult.first['pendingAmount'] as num?)?.toDouble() ?? 0.0;
          final currentTotal = (customerResult.first['totalPurchase'] as num?)?.toDouble() ?? 0.0;

          await txn.update(
            'customers',
            {
              'pendingAmount': currentPending + bill.total,
              'totalPurchase': currentTotal + bill.total,
              'updatedAt': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [bill.customerId],
          );
        }
      }
    });

    return bill.id;
  }

  Future<List<Bill>> getAllBills({int? limit, int? offset}) async {
    final db = await database;
    final result = await db.query(
      'bills',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    List<Bill> bills = [];
    for (var map in result) {
      final items = await getBillItems(map['id'] as String);
      bills.add(Bill.fromMap(map, items: items));
    }
    return bills;
  }

  Future<Bill?> getBillById(String id) async {
    final db = await database;
    final result = await db.query('bills', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;

    final items = await getBillItems(id);
    return Bill.fromMap(result.first, items: items);
  }

  Future<List<BillItem>> getBillItems(String billId) async {
    final db = await database;
    final result = await db.query('bill_items', where: 'billId = ?', whereArgs: [billId]);
    return result.map((map) => BillItem.fromMap(map)).toList();
  }

  Future<List<Bill>> getBillsByCustomer(String customerId) async {
    final db = await database;
    final result = await db.query(
      'bills',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );

    List<Bill> bills = [];
    for (var map in result) {
      final items = await getBillItems(map['id'] as String);
      bills.add(Bill.fromMap(map, items: items));
    }
    return bills;
  }

  Future<List<Bill>> getBillsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'bills',
      where: 'createdAt BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'createdAt DESC',
    );

    List<Bill> bills = [];
    for (var map in result) {
      final items = await getBillItems(map['id'] as String);
      bills.add(Bill.fromMap(map, items: items));
    }
    return bills;
  }

  Future<List<Bill>> getUnpaidBills() async {
    final db = await database;
    final result = await db.query(
      'bills',
      where: 'status != ?',
      whereArgs: [AppConstants.billPaid],
      orderBy: 'createdAt DESC',
    );

    List<Bill> bills = [];
    for (var map in result) {
      final items = await getBillItems(map['id'] as String);
      bills.add(Bill.fromMap(map, items: items));
    }
    return bills;
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    return await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<String> generateBillNumber() async {
    final db = await database;
    final today = DateTime.now();
    final prefix = 'INV${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM bills WHERE billNumber LIKE '$prefix%'",
    );

    final count = (result.first['count'] as int) + 1;
    return '$prefix${count.toString().padLeft(4, '0')}';
  }

  // ==================== PAYMENT OPERATIONS ====================

  Future<String> insertPayment(Payment payment) async {
    final db = await database;

    await db.transaction((txn) async {
      // Insert payment
      await txn.insert('payments', payment.toMap());

      // Update bill
      final bill = await getBillById(payment.billId);
      if (bill != null) {
        final newPaidAmount = bill.paidAmount + payment.amount;
        String newStatus;
        if (newPaidAmount >= bill.total) {
          newStatus = AppConstants.billPaid;
        } else if (newPaidAmount > 0) {
          newStatus = AppConstants.billPartial;
        } else {
          newStatus = AppConstants.billUnpaid;
        }

        await txn.update(
          'bills',
          {
            'paidAmount': newPaidAmount,
            'status': newStatus,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [payment.billId],
        );

        // Update customer pending amount
        if (bill.customerId != null) {
          final customer = await getCustomerById(bill.customerId!);
          if (customer != null) {
            await txn.update(
              'customers',
              {
                'pendingAmount': customer.pendingAmount - payment.amount,
                'updatedAt': DateTime.now().toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [bill.customerId],
            );
          }
        }
      }
    });

    return payment.id;
  }

  Future<List<Payment>> getPaymentsByBill(String billId) async {
    final db = await database;
    final result = await db.query(
      'payments',
      where: 'billId = ?',
      whereArgs: [billId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> getPaymentsByCustomer(String customerId) async {
    final db = await database;
    final result = await db.query(
      'payments',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => Payment.fromMap(map)).toList();
  }

  // ==================== DASHBOARD OPERATIONS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final startOfMonth = DateTime(today.year, today.month, 1);

    // Today's sales
    final todaySales = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as count 
      FROM bills 
      WHERE createdAt >= ?
    ''', [startOfDay.toIso8601String()]);

    // Monthly sales
    final monthlySales = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as count 
      FROM bills 
      WHERE createdAt >= ?
    ''', [startOfMonth.toIso8601String()]);

    // Total pending
    final pendingResult = await db.rawQuery('''
      SELECT COALESCE(SUM(pendingAmount), 0) as total 
      FROM customers
    ''');

    // Total customers
    final customerCount = await db.rawQuery('SELECT COUNT(*) as count FROM customers');

    // Total products
    final productCount = await db.rawQuery('SELECT COUNT(*) as count FROM products WHERE isActive = 1');

    // Low stock count
    final lowStock = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE stock <= lowStockAlert AND isActive = 1',
    );

    return {
      'todaySales': (todaySales.first['total'] as num?)?.toDouble() ?? 0.0,
      'todayBillCount': todaySales.first['count'] as int? ?? 0,
      'monthlySales': (monthlySales.first['total'] as num?)?.toDouble() ?? 0.0,
      'monthlyBillCount': monthlySales.first['count'] as int? ?? 0,
      'totalPending': (pendingResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'customerCount': customerCount.first['count'] as int? ?? 0,
      'productCount': productCount.first['count'] as int? ?? 0,
      'lowStockCount': lowStock.first['count'] as int? ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 5}) async {
    final db = await database;
    final result = await db.query(
      'customers',
      orderBy: 'totalPurchase DESC',
      limit: limit,
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getRecentBills({int limit = 10}) async {
    final db = await database;
    final result = await db.query(
      'bills',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getSalesChart({int days = 7}) async {
    final db = await database;
    final List<Map<String, dynamic>> chartData = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await db.rawQuery('''
        SELECT COALESCE(SUM(total), 0) as total 
        FROM bills 
        WHERE createdAt >= ? AND createdAt < ?
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      chartData.add({
        'date': startOfDay,
        'total': (result.first['total'] as num?)?.toDouble() ?? 0.0,
      });
    }

    return chartData;
  }

  // Close database
  Future close() async {
    final db = await database;
    db.close();
  }
}