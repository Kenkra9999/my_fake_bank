import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';

// --- MODEL LOAN ---
class Loan {
  String id;
  String purpose;
  int principalAmount;
  double interestRate;
  int months;
  DateTime createdDate;
  List<LoanPayment> payments;
  bool isApproved;

  Loan({
    required this.id,
    required this.purpose,
    required this.principalAmount,
    this.interestRate = 2.0,
    required this.months,
    required this.createdDate,
    this.payments = const [],
    this.isApproved = false,
  });

  int get monthlyPrincipal => principalAmount ~/ months;
  int get monthlyInterest => (principalAmount * (interestRate / 100)).toInt();
  int get monthlyTotal => monthlyPrincipal + monthlyInterest;

  int get remainingBalance {
    int paidPrincipal = payments.length * monthlyPrincipal;
    int remaining = principalAmount - paidPrincipal;
    return remaining < 0 ? 0 : remaining;
  }

  int get totalInterest => monthlyInterest * months;
  int get totalAmount => principalAmount + totalInterest;

  List<MonthlyPayment> getMonthlyPaymentSchedule() {
    List<MonthlyPayment> schedule = [];
    for (int i = 0; i < months; i++) {
      schedule.add(
        MonthlyPayment(
          month: i + 1,
          dueDate: createdDate.add(Duration(days: 30 * (i + 1))),
          amount: monthlyTotal,
          isPaid: payments.any((p) => p.month == i + 1),
        ),
      );
    }
    return schedule;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purpose': purpose,
      'principalAmount': principalAmount,
      'interestRate': interestRate,
      'months': months,
      'createdDate': createdDate.toIso8601String(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'isApproved': isApproved,
    };
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      purpose: json['purpose'],
      principalAmount: json['principalAmount'],
      interestRate: json['interestRate'],
      months: json['months'],
      createdDate: DateTime.parse(json['createdDate']),
      payments: (json['payments'] as List)
          .map((p) => LoanPayment.fromJson(p))
          .toList(),
      isApproved: json['isApproved'],
    );
  }
}

class LoanPayment {
  int month;
  int amount;
  DateTime paymentDate;

  LoanPayment({
    required this.month,
    required this.amount,
    required this.paymentDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
    };
  }

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      month: json['month'],
      amount: json['amount'],
      paymentDate: DateTime.parse(json['paymentDate']),
    );
  }
}

class MonthlyPayment {
  int month;
  DateTime dueDate;
  int amount;
  bool isPaid;

  MonthlyPayment({
    required this.month,
    required this.dueDate,
    required this.amount,
    required this.isPaid,
  });
}

// --- MODEL CRYPTO ---
class ChartSampleData {
  ChartSampleData({this.x, this.open, this.high, this.low, this.close});
  final DateTime? x;
  final num? open;
  final num? high;
  final num? low;
  final num? close;
}

class TradePosition {
  String id;
  String symbol;
  bool isLong;
  double margin;
  int leverage;
  double entryPrice;
  double size;

  TradePosition({
    required this.id,
    required this.symbol,
    required this.isLong,
    required this.margin,
    required this.leverage,
    required this.entryPrice,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'isLong': isLong,
        'margin': margin,
        'leverage': leverage,
        'entryPrice': entryPrice,
        'size': size,
      };

  factory TradePosition.fromJson(Map<String, dynamic> json) => TradePosition(
        id: json['id'],
        symbol: json['symbol'],
        isLong: json['isLong'],
        margin: json['margin'],
        leverage: json['leverage'],
        entryPrice: json['entryPrice'],
        size: json['size'],
      );
}

void main() {
  runApp(const VPBankCloneApp());
}

class VPBankCloneApp extends StatelessWidget {
  const VPBankCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// --- MÀN HÌNH CHÍNH ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String balance = "1,006,214";

  @override
  void initState() {
    super.initState();
    _loadBalance();
    WidgetsBinding.instance.addObserver(
      _LifecycleObserver(onResume: _loadBalance),
    );
  }

  void _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBalance = prefs.getInt('balance') ?? 1006214;
    if (mounted) {
      setState(() {
        balance = _formatBalance(savedBalance);
      });
    }
  }

  String _formatBalance(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00A55D), Color(0xFF00E676)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.white24,
                        child: Text(
                          "QT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tài khoản chính - Quách Văn Trường",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.favorite_border, color: Colors.white),
                      const SizedBox(width: 15),
                      const Icon(Icons.search, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$balance đ",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.visibility, color: Colors.white70),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              icon: Icons.swap_horiz_rounded,
              title: "Chuyển tiền",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TransferInputScreen(),
                ),
              ).then((_) => _loadBalance()),
            ),
            _buildActionCard(
              icon: Icons.qr_code_scanner,
              title: "Quét mã QR",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              ).then((_) => _loadBalance()),
            ),
            _buildActionCard(
              icon: Icons.attach_money,
              title: "Vay tiền",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoanApplicationScreen(),
                ),
              ).then((_) => _loadBalance()),
            ),
            _buildActionCard(
              icon: Icons.receipt_long,
              title: "Quản lý khoản vay",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoanManagementScreen(),
                ),
              ).then((_) => _loadBalance()),
            ),
            _buildActionCard(icon: Icons.history, title: "Lịch sử giao dịch"),
            _buildActionCard(icon: Icons.credit_card, title: "Quản lý thẻ"),
            _buildActionCard(
              icon: Icons.currency_bitcoin,
              title: "Đầu tư Crypto",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CryptoDashboardScreen(),
                ),
              ).then((_) => _loadBalance()),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
                child: Icon(icon, color: const Color(0xFF00C853)),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MÀN HÌNH NHẬP THÔNG TIN ---
class TransferInputScreen extends StatefulWidget {
  const TransferInputScreen({super.key});

  @override
  State<TransferInputScreen> createState() => _TransferInputScreenState();
}

class _TransferInputScreenState extends State<TransferInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chuyển tiền ngoài VPBank")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _accController,
              decoration: const InputDecoration(labelText: "Số tài khoản"),
            ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Tên người nhận"),
            ),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: "Số tiền"),
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SuccessReceiptScreen(
                        name: _nameController.text,
                        amount: _amountController.text,
                        account: _accController.text,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Tiếp tục",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MÀN HÌNH BIÊN LAI ---
class SuccessReceiptScreen extends StatefulWidget {
  final String name;
  final String amount;
  final String account;

  const SuccessReceiptScreen({
    super.key,
    required this.name,
    required this.amount,
    required this.account,
  });

  @override
  State<SuccessReceiptScreen> createState() => _SuccessReceiptScreenState();
}

class _SuccessReceiptScreenState extends State<SuccessReceiptScreen> {
  @override
  void initState() {
    super.initState();
    _deductBalance();
  }

  void _deductBalance() async {
    final prefs = await SharedPreferences.getInstance();
    String cleanAmount =
        widget.amount.replaceAll(',', '').replaceAll(' đ', '').trim();
    int amountToDeduct = int.tryParse(cleanAmount) ?? 0;
    int currentBalance = prefs.getInt('balance') ?? 1006214;
    int newBalance = currentBalance - amountToDeduct;
    if (newBalance < 0) newBalance = 0;
    await prefs.setInt('balance', newBalance);
  }

  @override
  Widget build(BuildContext context) {
    String now = DateFormat('HH:mm, dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF00A55D),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  color: Color(0xFF00C853), size: 80),
              const SizedBox(height: 15),
              const Text(
                "Giao dịch thành công",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
                ),
              ),
              const SizedBox(height: 30),
              _buildReceiptRow("Số tiền", "${widget.amount} đ"),
              _buildReceiptRow("Người thụ hưởng", widget.name.toUpperCase()),
              _buildReceiptRow("Tài khoản nhận", widget.account),
              _buildReceiptRow("Thời gian", now),
              _buildReceiptRow(
                "Mã giao dịch",
                "VPB${DateTime.now().millisecondsSinceEpoch}",
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A55D),
                ),
                child: const Text(
                  "Về trang chủ",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- MÀN HÌNH QUÉT MÃ QR ---
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool isScanned = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  void _initializeController() {
    controller = MobileScannerController(
      autoStart: true,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller?.stop();
    controller?.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) async {
    if (isScanned) return;

    try {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? qrValue = barcode.rawValue;
        if (qrValue != null && qrValue.isNotEmpty) {
          isScanned = true;
          controller?.stop();

          if (mounted) {
            if (qrValue.startsWith("CRYPTO_DEPOSIT|")) {
              int amountVND = int.parse(qrValue.split("|")[1]);
              _processCryptoDeposit(amountVND);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QRResultScreen(qrCode: qrValue),
                ),
              );
            }
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error detecting barcode: $e');
    }
  }

  void _processCryptoDeposit(int vndAmount) async {
    final prefs = await SharedPreferences.getInstance();
    int currentVND = prefs.getInt('balance') ?? 1006214;

    if (currentVND < vndAmount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Số dư tài khoản ngân hàng không đủ để nạp!",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red));
        Navigator.pop(context);
      }
      return;
    }

    double usdtToAdd = vndAmount / 27302;
    double currentUSDT = prefs.getDouble('usdt_balance') ?? 0.0;

    await prefs.setInt('balance', currentVND - vndAmount);
    await prefs.setDouble('usdt_balance', currentUSDT + usdtToAdd);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Thanh toán thành công! Đã nạp ${usdtToAdd.toStringAsFixed(2)} USDT"),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  Future<void> _scanFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final BarcodeCapture? capture =
          await controller?.analyzeImage(image.path);
      if (capture != null && capture.barcodes.isNotEmpty) {
        _handleDetect(capture);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Không tìm thấy mã QR hợp lệ trong ảnh!")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quét mã QR"),
        backgroundColor: const Color(0xFF00A55D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                MobileScanner(controller: controller!, onDetect: _handleDetect),
                Container(color: Colors.black.withOpacity(0.4)),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF00C853),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                                left: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                              ),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                                right: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                              ),
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(10)),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                                left: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                              ),
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(10)),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                                right: BorderSide(
                                    color: Color(0xFF00E676), width: 3),
                              ),
                              borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(10)),
                            ),
                          ),
                        ),
                        ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0)
                              .animate(_animationController),
                          child: Container(
                            width: 250,
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00E676).withOpacity(0),
                                  const Color(0xFF00E676),
                                  const Color(0xFF00E676).withOpacity(0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF00E676).withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          "Đưa mã QR vào khung để quét",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: _scanFromGallery,
                        icon: const Icon(Icons.photo_library,
                            color: Colors.white, size: 40),
                        tooltip: "Lấy ảnh từ thư viện",
                      )
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// --- MÀN HÌNH KẾT QUẢ QUÉT MÃ QR ---
class QRResultScreen extends StatefulWidget {
  final String qrCode;

  const QRResultScreen({super.key, required this.qrCode});

  @override
  State<QRResultScreen> createState() => _QRResultScreenState();
}

class _QRResultScreenState extends State<QRResultScreen> {
  late TextEditingController _stkController;
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final parts = widget.qrCode.split('|');
    String stk = parts.isNotEmpty ? parts[0] : '';
    String name = parts.length > 1 ? parts[1] : '';

    _stkController = TextEditingController(text: stk);
    _nameController = TextEditingController(text: name);
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _stkController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _formatAmount(String value) {
    if (value.isEmpty) return;

    String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericValue.isEmpty) {
      _amountController.clear();
      return;
    }

    int number = int.parse(numericValue);
    String formatted = number.toString();

    StringBuffer result = StringBuffer();
    int count = 0;
    for (int i = formatted.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(formatted[i]);
      count++;
    }

    String finalValue = result.toString().split('').reversed.join('');
    _amountController.value = TextEditingValue(
      text: finalValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: finalValue.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Nhập thông tin chuyển tiền"),
        backgroundColor: const Color(0xFF00A55D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00A55D), Color(0xFF00E676)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_2,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Mã QR đã quét",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 5),
                          Text(
                            widget.qrCode.length > 20
                                ? "${widget.qrCode.substring(0, 20)}..."
                                : widget.qrCode,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("Thông tin người nhận",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 20),
              const Text("Số tài khoản",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _stkController,
                decoration: InputDecoration(
                  hintText: "Nhập số tài khoản",
                  prefixIcon: const Icon(Icons.account_balance_wallet),
                  prefixIconColor: const Color(0xFF00A55D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF00A55D), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Tên người nhận",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Nhập tên người nhận",
                  prefixIcon: const Icon(Icons.person),
                  prefixIconColor: const Color(0xFF00A55D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF00A55D), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Số tiền cần chuyển",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: _formatAmount,
                decoration: InputDecoration(
                  hintText: "0",
                  prefixIcon: const Icon(Icons.payments),
                  prefixIconColor: const Color(0xFF00A55D),
                  suffixText: "đ",
                  suffixStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00A55D)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF00A55D), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A55D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00A55D).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("STK người nhận:", _stkController.text),
                    const SizedBox(height: 10),
                    _buildSummaryRow("Tên người nhận:", _nameController.text),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      "Số tiền:",
                      _amountController.text.isEmpty
                          ? "0"
                          : "${_amountController.text} đ",
                      isAmount: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(
                            color: Color(0xFF00A55D), width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Quét lại",
                          style: TextStyle(
                              color: Color(0xFF00A55D),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_stkController.text.isEmpty ||
                            _nameController.text.isEmpty ||
                            _amountController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Vui lòng điền đầy đủ thông tin!"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SuccessReceiptScreen(
                              name: _nameController.text,
                              amount: _amountController.text,
                              account: _stkController.text,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A55D),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Tiếp tục",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isAmount ? const Color(0xFF00A55D) : Colors.black87)),
      ],
    );
  }
}

// --- MÀN HÌNH VAY TIỀN ---
class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  int selectedMonths = 3;
  double _interestRate = 2.0;

  @override
  void dispose() {
    _purposeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitLoan() async {
    if (_purposeController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Vui lòng điền đầy đủ thông tin!"),
            backgroundColor: Colors.red),
      );
      return;
    }

    String cleanAmount =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    int amount = int.tryParse(cleanAmount) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Số tiền phải lớn hơn 0!"),
            backgroundColor: Colors.red),
      );
      return;
    }

    final loan = Loan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      purpose: _purposeController.text,
      principalAmount: amount,
      interestRate: _interestRate,
      months: selectedMonths,
      createdDate: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoanApprovalScreen(loan: loan)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Đăng ký vay tiền"),
        backgroundColor: const Color(0xFF00A55D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A55D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00A55D).withOpacity(0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thông tin vay",
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00A55D))),
                    SizedBox(height: 8),
                    Text(
                        "✓ Lãi suất cố định: 2%/tháng\n✓ Được duyệt tự động 100%\n✓ Trả gốc và lãi linh hoạt theo tháng\n✓ Trừ trực tiếp vào tài khoản",
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text("Mục đích vay",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _purposeController,
                decoration: InputDecoration(
                  hintText: "VD: Kinh doanh, Giáo dục, Mua sắm...",
                  prefixIcon: const Icon(Icons.assignment),
                  prefixIconColor: const Color(0xFF00A55D),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF00A55D), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text("Số tiền muốn vay",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue.isEmpty) {
                    _amountController.clear();
                    setState(() {});
                    return;
                  }
                  int number = int.parse(cleanValue);
                  String formatted = number.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                      (match) => '${match[1]},');
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.fromPosition(
                        TextPosition(offset: formatted.length)),
                  );
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: "0",
                  prefixIcon: const Icon(Icons.payments),
                  prefixIconColor: const Color(0xFF00A55D),
                  suffixText: "đ",
                  suffixStyle: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF00A55D)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF00A55D), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text("Thời gian vay: $selectedMonths tháng",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              Slider(
                value: selectedMonths.toDouble(),
                min: 1,
                max: 36,
                divisions: 35,
                label: selectedMonths.toString(),
                activeColor: const Color(0xFF00A55D),
                onChanged: (value) {
                  setState(() {
                    selectedMonths = value.toInt();
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_amountController.text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00A55D).withOpacity(0.2)),
                  ),
                  child: Builder(
                    builder: (context) {
                      int principal = int.parse(_amountController.text
                          .replaceAll(RegExp(r'[^0-9]'), ''));
                      int totalInterest =
                          (principal * (_interestRate / 100) * selectedMonths)
                              .toInt();
                      int monthlyPayment = (principal ~/ selectedMonths) +
                          (principal * (_interestRate / 100)).toInt();

                      return Column(
                        children: [
                          _buildCalculationRow(
                              "Số tiền gốc", "${_amountController.text} đ"),
                          const Divider(height: 20),
                          _buildCalculationRow("Tổng lãi phải trả (2%/tháng)",
                              "${totalInterest.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ"),
                          const Divider(height: 20),
                          _buildCalculationRow("Thanh toán mỗi tháng (gốc+lãi)",
                              "${monthlyPayment.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ",
                              isHighlight: true),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitLoan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A55D),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Đăng ký vay",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                color: isHighlight ? const Color(0xFF00A55D) : Colors.grey,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? const Color(0xFF00A55D) : Colors.black87)),
      ],
    );
  }
}

// --- MÀN HÌNH DUYỆT VAY ---
class LoanApprovalScreen extends StatefulWidget {
  final Loan loan;

  const LoanApprovalScreen({super.key, required this.loan});

  @override
  State<LoanApprovalScreen> createState() => _LoanApprovalScreenState();
}

class _LoanApprovalScreenState extends State<LoanApprovalScreen> {
  @override
  void initState() {
    super.initState();
    _approveLoan();
  }

  void _approveLoan() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final loansJson = prefs.getString('loans') ?? '[]';
    final List<dynamic> loansList = jsonDecode(loansJson);

    final updatedLoan = Loan(
      id: widget.loan.id,
      purpose: widget.loan.purpose,
      principalAmount: widget.loan.principalAmount,
      months: widget.loan.months,
      interestRate: widget.loan.interestRate,
      createdDate: widget.loan.createdDate,
      isApproved: true,
    );

    loansList.add(updatedLoan.toJson());
    await prefs.setString('loans', jsonEncode(loansList));

    int currentBalance = prefs.getInt('balance') ?? 1006214;
    int newBalance = currentBalance + widget.loan.principalAmount;
    await prefs.setInt('balance', newBalance);

    if (mounted) {
      setState(() {
        widget.loan.isApproved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00A55D),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: widget.loan.isApproved
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00C853), size: 80),
                    const SizedBox(height: 20),
                    const Text("Duyệt vay thành công!",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853))),
                    const SizedBox(height: 10),
                    const Text("Tiền đã được cộng vào tài khoản của bạn.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 30),
                    _buildInfoBox("Số tiền vay",
                        "${widget.loan.principalAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ"),
                    _buildInfoBox("Mục đích", widget.loan.purpose),
                    _buildInfoBox("Kỳ hạn", "${widget.loan.months} tháng"),
                    _buildInfoBox("Lãi suất", "2%/tháng"),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/', (route) => false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A55D),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Về trang chủ",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00A55D))),
                    ),
                    SizedBox(height: 30),
                    Text("Đang xử lý duyệt vay...",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    SizedBox(height: 20),
                    Text("Hệ thống đang kiểm duyệt tự động\nVui lòng đợi 100%",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }
}

// --- MÀN HÌNH QUẢN LÝ KHOẢN VAY ---
class LoanManagementScreen extends StatefulWidget {
  const LoanManagementScreen({super.key});

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen> {
  List<Loan> loans = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  void _loadLoans() async {
    final prefs = await SharedPreferences.getInstance();
    final loansJson = prefs.getString('loans') ?? '[]';
    final List<dynamic> loansList = jsonDecode(loansJson);

    setState(() {
      loans = loansList.map((l) => Loan.fromJson(l)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Quản lý khoản vay"),
        backgroundColor: const Color(0xFF00A55D),
        foregroundColor: Colors.white,
      ),
      body: loans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info,
                      size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 20),
                  const Text("Bạn chưa có khoản vay nào",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              itemBuilder: (context, index) {
                final loan = loans[loans.length - 1 - index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoanDetailScreen(
                        loan: loan,
                        onPaymentMade: _loadLoans,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1), blurRadius: 8)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(loan.purpose,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: loan.remainingBalance == 0
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                loan.remainingBalance == 0
                                    ? "Đã tất toán"
                                    : "Đang trả nợ",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: loan.remainingBalance == 0
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Tổng vay",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                    "${loan.principalAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Gốc còn lại",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(
                                    "${loan.remainingBalance.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00A55D))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Kỳ hạn",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text("${loan.months} tháng",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// --- MÀN HÌNH CHI TIẾT & THANH TOÁN VAY ---
class LoanDetailScreen extends StatefulWidget {
  final Loan loan;
  final VoidCallback onPaymentMade;

  const LoanDetailScreen({
    super.key,
    required this.loan,
    required this.onPaymentMade,
  });

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Loan currentLoan;

  @override
  void initState() {
    super.initState();
    currentLoan = widget.loan;
  }

  void _payMonth(int month, int amountToPay) async {
    final prefs = await SharedPreferences.getInstance();

    final loansJson = prefs.getString('loans') ?? '[]';
    final List<dynamic> loansList = jsonDecode(loansJson);

    final loanIndex = loansList.indexWhere((l) => l['id'] == widget.loan.id);
    if (loanIndex == -1) return;

    final loanData = loansList[loanIndex];
    loanData['payments'] ??= [];

    bool alreadyPaid =
        (loanData['payments'] as List).any((p) => p['month'] == month);
    if (alreadyPaid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Kỳ này đã thanh toán rồi!"),
            backgroundColor: Colors.orange));
      }
      return;
    }

    int currentBalance = prefs.getInt('balance') ?? 1006214;
    if (currentBalance < amountToPay) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("Số dư không đủ để thanh toán! Vui lòng nạp thêm tiền."),
            backgroundColor: Colors.red));
      }
      return;
    }

    int newBalance = currentBalance - amountToPay;
    await prefs.setInt('balance', newBalance);

    (loanData['payments'] as List).add({
      'month': month,
      'amount': amountToPay,
      'paymentDate': DateTime.now().toIso8601String(),
    });

    loansList[loanIndex] = loanData;
    await prefs.setString('loans', jsonEncode(loansList));

    setState(() {
      currentLoan = Loan.fromJson(loanData);
    });

    widget.onPaymentMade();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Thanh toán thành công! (-${amountToPay.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ)"),
            backgroundColor: const Color(0xFF00C853)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthlyPayments = currentLoan.getMonthlyPaymentSchedule();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text("Chi tiết khoản vay"),
        backgroundColor: const Color(0xFF00A55D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00A55D), Color(0xFF00E676)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(currentLoan.purpose,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHeaderInfo("Số tiền gốc",
                            "${currentLoan.principalAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ"),
                        _buildHeaderInfo("Dư nợ gốc",
                            "${currentLoan.remainingBalance.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 8)
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatBox("Tổng lãi phải trả",
                        "${currentLoan.totalInterest.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ"),
                    _buildStatBox("Tổng gốc + lãi",
                        "${currentLoan.totalAmount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ"),
                    _buildStatBox("Tiến độ",
                        "${currentLoan.payments.length}/${currentLoan.months}"),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("Lịch thanh toán (Gốc + Lãi) mỗi tháng",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              ...monthlyPayments.map((payment) {
                bool isPaid = payment.isPaid;
                return GestureDetector(
                  onTap: !isPaid
                      ? () => _payMonth(payment.month, payment.amount)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isPaid ? Colors.green.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isPaid
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Kỳ ${payment.month}",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isPaid
                                        ? Colors.green
                                        : Colors.black87)),
                            Text(
                                DateFormat('dd/MM/yyyy')
                                    .format(payment.dueDate),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    "${payment.amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} đ",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isPaid
                                            ? Colors.green
                                            : Colors.black87)),
                                Text(isPaid ? "Đã thanh toán" : "Bấm để trả",
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isPaid
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: isPaid
                                            ? FontWeight.normal
                                            : FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Icon(isPaid ? Icons.check_circle : Icons.payment,
                                color: isPaid ? Colors.green : Colors.orange,
                                size: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A55D))),
        ],
      ),
    );
  }
}

// --- LIFECYCLE OBSERVER ---
class _LifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResume;

  _LifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

// ==========================================
// --- MÀN HÌNH CRYPTO DASHBOARD ---
// ==========================================
class CryptoDashboardScreen extends StatefulWidget {
  const CryptoDashboardScreen({super.key});

  @override
  State<CryptoDashboardScreen> createState() => _CryptoDashboardScreenState();
}

class _CryptoDashboardScreenState extends State<CryptoDashboardScreen> {
  double usdtBalance = 0.0;
  final int exchangeRate = 27302;
  List<dynamic> coins = [];
  Timer? _timer;

  final List<String> symbols = [
    "BTCUSDT",
    "ETHUSDT",
    "BNBUSDT",
    "SOLUSDT",
    "XRPUSDT"
  ];

  @override
  void initState() {
    super.initState();
    _loadCryptoBalance();
    _fetchMarketData();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (timer) => _fetchMarketData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadCryptoBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      usdtBalance = prefs.getDouble('usdt_balance') ?? 0.0;
    });
  }

  Future<void> _fetchMarketData() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            coins =
                data.where((coin) => symbols.contains(coin['symbol'])).toList();
            coins.sort((a, b) => symbols
                .indexOf(a['symbol'])
                .compareTo(symbols.indexOf(b['symbol'])));
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy giá coin: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: const Text("Thị trường Futures"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF3BA2F), Color(0xFFF9A825)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Text("Tổng tài sản (USDT)",
                      style: TextStyle(
                          color: Colors.black54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(usdtBalance.toStringAsFixed(2),
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 5),
                  Text(
                      "≈ ${(usdtBalance * exchangeRate).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} VNĐ",
                      style: const TextStyle(color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CryptoDepositScreen()))
                        .then((_) => _loadCryptoBalance()),
                    icon: const Icon(Icons.download),
                    label: const Text("Nạp USDT"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CryptoWithdrawScreen()))
                        .then((_) => _loadCryptoBalance()),
                    icon: const Icon(Icons.upload),
                    label: const Text("Rút VNĐ"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Thị trường",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 10),
            Expanded(
              child: coins.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber))
                  : ListView.builder(
                      itemCount: coins.length,
                      itemBuilder: (context, index) {
                        final coin = coins[index];
                        String symbol =
                            coin['symbol'].toString().replaceAll("USDT", "");
                        double price = double.parse(coin['lastPrice']);
                        double change =
                            double.parse(coin['priceChangePercent']);
                        Color color = change >= 0 ? Colors.green : Colors.red;

                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CoinTradingScreen(
                                            symbol: coin['symbol'])))
                                .then((_) => _loadCryptoBalance()),
                            leading: CircleAvatar(
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                child: Text(symbol[0],
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold))),
                            title: Text("$symbol/USDT",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "Vol: ${(double.parse(coin['quoteVolume']) / 1000000).toStringAsFixed(2)}M",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    "\$${price.toStringAsFixed(price < 1 ? 4 : 2)}",
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                      "${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%",
                                      style: TextStyle(
                                          color: color, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- MÀN HÌNH RÚT TIỀN (BÁN USDT RA VNĐ) ---
// ==========================================
class CryptoWithdrawScreen extends StatefulWidget {
  const CryptoWithdrawScreen({super.key});

  @override
  State<CryptoWithdrawScreen> createState() => _CryptoWithdrawScreenState();
}

class _CryptoWithdrawScreenState extends State<CryptoWithdrawScreen> {
  final TextEditingController _usdtController = TextEditingController();
  final int exchangeRate = 27302;
  double usdtBalance = 0.0;
  double vndReceive = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  void _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      usdtBalance = prefs.getDouble('usdt_balance') ?? 0.0;
    });
  }

  void _withdraw() async {
    double withdrawUsdt = double.tryParse(_usdtController.text) ?? 0;
    if (withdrawUsdt <= 0 || withdrawUsdt > usdtBalance) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Số lượng USDT không hợp lệ!"),
            backgroundColor: Colors.red));
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int currentVnd = prefs.getInt('balance') ?? 0;

    await prefs.setDouble('usdt_balance', usdtBalance - withdrawUsdt);
    await prefs.setInt('balance', currentVnd + vndReceive.toInt());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Rút tiền thành công! Đã cộng vào tài khoản chính."),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: const Text("Bán USDT Rút về VNĐ"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(
                  "Số dư khả dụng: ${usdtBalance.toStringAsFixed(2)} USDT",
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usdtController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Số USDT muốn bán",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber)),
                  suffixText: "USDT",
                  suffixStyle: TextStyle(color: Colors.amber)),
              onChanged: (val) {
                double amount = double.tryParse(val) ?? 0;
                setState(() => vndReceive = amount * exchangeRate);
              },
            ),
            const SizedBox(height: 20),
            Text(
                "Thực nhận: ${vndReceive.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} VNĐ",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _withdraw,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text("Xác nhận Bán",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- MÀN HÌNH NẠP CRYPTO (TẠO QR) ---
// ==========================================
class CryptoDepositScreen extends StatefulWidget {
  const CryptoDepositScreen({super.key});

  @override
  State<CryptoDepositScreen> createState() => _CryptoDepositScreenState();
}

class _CryptoDepositScreenState extends State<CryptoDepositScreen> {
  final TextEditingController _vndController = TextEditingController();
  final int exchangeRate = 27302;
  String qrData = "";
  double usdtAmount = 0.0;

  void _generateQR() {
    String cleanAmount = _vndController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanAmount.isEmpty) {
      setState(() => qrData = "");
      return;
    }
    int vnd = int.parse(cleanAmount);
    setState(() {
      usdtAmount = vnd / exchangeRate;
      qrData = "CRYPTO_DEPOSIT|$vnd";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: const Text("Nạp USDT"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _vndController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: "Nhập số VNĐ muốn nạp",
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber)),
                  suffixText: "VNĐ",
                  suffixStyle: TextStyle(color: Colors.amber)),
              onChanged: (val) => _generateQR(),
            ),
            const SizedBox(height: 20),
            if (qrData.isNotEmpty) ...[
              Text("Nhận được: ≈ ${usdtAmount.toStringAsFixed(2)} USDT",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent)),
              const SizedBox(height: 20),
              Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  child: QrImageView(
                      data: qrData, version: QrVersions.auto, size: 250.0)),
              const SizedBox(height: 20),
              const Text(
                  "Chụp màn hình mã QR này lại.\nVề Trang Chủ -> Quét mã QR -> Chọn ảnh thư viện để thanh toán.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// --- MÀN HÌNH TRADING (CHART NẾN & ĐÒN BẨY) ---
// ==========================================
class CoinTradingScreen extends StatefulWidget {
  final String symbol;

  const CoinTradingScreen({super.key, required this.symbol});

  @override
  State<CoinTradingScreen> createState() => _CoinTradingScreenState();
}

class _CoinTradingScreenState extends State<CoinTradingScreen> {
  List<ChartSampleData> chartData = [];
  double currentPrice = 0.0;
  Timer? _timer;
  List<TradePosition> activePositions = [];

  @override
  void initState() {
    super.initState();
    _fetchKlines();
    _loadPositions();
    _timer = Timer.periodic(
        const Duration(seconds: 2), (timer) => _fetchCurrentPrice());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchKlines() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=${widget.symbol}&interval=15m&limit=50'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<ChartSampleData> temp = [];
        for (var item in data) {
          temp.add(ChartSampleData(
            x: DateTime.fromMillisecondsSinceEpoch(item[0]),
            open: double.parse(item[1]),
            high: double.parse(item[2]),
            low: double.parse(item[3]),
            close: double.parse(item[4]),
          ));
        }
        if (mounted) {
          setState(() {
            chartData = temp;
            currentPrice = temp.last.close as double;
          });
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy klines: $e");
    }
  }

  Future<void> _fetchCurrentPrice() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=${widget.symbol}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => currentPrice = double.parse(data['price']));
        }
      }
    } catch (e) {
      debugPrint("Lỗi lấy giá: $e");
    }
  }

  void _loadPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? posStr = prefs.getString('positions');
    if (posStr != null) {
      final List<dynamic> decoded = jsonDecode(posStr);
      setState(() {
        activePositions = decoded
            .map((e) => TradePosition.fromJson(e))
            .where((p) => p.symbol == widget.symbol)
            .toList();
      });
    }
  }

  void _savePositions(List<TradePosition> newPosList) async {
    final prefs = await SharedPreferences.getInstance();
    final String? posStr = prefs.getString('positions');
    List<TradePosition> allPos = [];
    if (posStr != null) {
      allPos = (jsonDecode(posStr) as List)
          .map((e) => TradePosition.fromJson(e))
          .toList();
    }
    allPos.removeWhere((p) => p.symbol == widget.symbol);
    allPos.addAll(newPosList);
    await prefs.setString(
        'positions', jsonEncode(allPos.map((e) => e.toJson()).toList()));
  }

  void _showOrderDialog(bool isLong) {
    double leverage = 20.0;
    TextEditingController marginController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      isLong
                          ? "Mở Long (Mua) ${widget.symbol}"
                          : "Mở Short (Bán) ${widget.symbol}",
                      style: TextStyle(
                          color: isLong ? Colors.green : Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Đòn bẩy: ${leverage.toInt()}x",
                      style: const TextStyle(color: Colors.white)),
                  Slider(
                    value: leverage,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    activeColor: Colors.amber,
                    onChanged: (val) {
                      setModalState(() {
                        leverage = val;
                      });
                    },
                  ),
                  TextField(
                    controller: marginController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: "Vốn Margin (USDT)",
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber))),
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (context) {
                    double margin = double.tryParse(marginController.text) ?? 0;
                    double fee = (margin * leverage) * 0.001;
                    return Text(
                        "Phí giao dịch (0.1% vol): ${fee.toStringAsFixed(2)} USDT",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12));
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _executeTrade(
                          isLong, marginController.text, leverage.toInt(), ctx),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: isLong ? Colors.green : Colors.red),
                      child: Text("Xác nhận ${isLong ? 'Long' : 'Short'}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _executeTrade(
      bool isLong, String marginStr, int leverage, BuildContext ctx) async {
    double margin = double.tryParse(marginStr) ?? 0;
    if (margin <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    double currentUsdt = prefs.getDouble('usdt_balance') ?? 0.0;
    double fee = (margin * leverage) * 0.001;
    double totalCost = margin + fee;

    if (currentUsdt < totalCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Không đủ USDT (Bao gồm phí)!"),
            backgroundColor: Colors.red));
      }
      return;
    }

    await prefs.setDouble('usdt_balance', currentUsdt - totalCost);
    double size = (margin * leverage) / currentPrice;

    TradePosition newPos = TradePosition(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      symbol: widget.symbol,
      isLong: isLong,
      margin: margin,
      leverage: leverage,
      entryPrice: currentPrice,
      size: size,
    );

    setState(() => activePositions.add(newPos));
    _savePositions(activePositions);

    if (mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Vào lệnh thành công!"),
          backgroundColor: Colors.green));
    }
  }

  void _closePosition(TradePosition pos) async {
    double currentValue = pos.size * currentPrice;
    double pnl =
        (currentValue - (pos.margin * pos.leverage)) * (pos.isLong ? 1 : -1);

    final prefs = await SharedPreferences.getInstance();
    double currentUsdt = prefs.getDouble('usdt_balance') ?? 0.0;

    double receiveAmount = pos.margin + pnl;
    if (receiveAmount < 0) receiveAmount = 0;

    await prefs.setDouble('usdt_balance', currentUsdt + receiveAmount);

    setState(() => activePositions.removeWhere((p) => p.id == pos.id));
    _savePositions(activePositions);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "Đóng lệnh! Lời/Lỗ: ${pnl > 0 ? '+' : ''}${pnl.toStringAsFixed(2)} USDT"),
          backgroundColor: pnl >= 0 ? Colors.green : Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: Text(widget.symbol.replaceAll("USDT", "/USDT")),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "\$${currentPrice.toStringAsFixed(currentPrice < 1 ? 4 : 2)}",
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: chartData.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber))
                : SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    primaryXAxis: const DateTimeAxis(isVisible: false),
                    primaryYAxis: const NumericAxis(
                      isVisible: true,
                      labelStyle: TextStyle(
                          color: Colors
                              .grey), // Sửa axisLabelStyle thành labelStyle
                    ),
                    series: <CartesianSeries>[
                      CandleSeries<ChartSampleData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (ChartSampleData sales, _) => sales.x,
                        lowValueMapper: (ChartSampleData sales, _) => sales.low,
                        highValueMapper: (ChartSampleData sales, _) =>
                            sales.high,
                        openValueMapper: (ChartSampleData sales, _) =>
                            sales.open,
                        closeValueMapper: (ChartSampleData sales, _) =>
                            sales.close,
                        bearColor:
                            Colors.red, // Sửa bearFillColor thành bearColor
                        bullColor:
                            Colors.green, // Sửa bullFillColor thành bullColor
                      )
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () => _showOrderDialog(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text("Mua (Long)",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(width: 15),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () => _showOrderDialog(false),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 15)),
                        child: const Text("Bán (Short)",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Vị thế của bạn",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)))),
          Expanded(
            child: activePositions.isEmpty
                ? const Center(
                    child: Text("Không có vị thế nào",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: activePositions.length,
                    itemBuilder: (context, index) {
                      final pos = activePositions[index];
                      double currentValue = pos.size * currentPrice;
                      double pnl =
                          (currentValue - (pos.margin * pos.leverage)) *
                              (pos.isLong ? 1 : -1);
                      double roe = (pnl / pos.margin) * 100;

                      return Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: pos.isLong
                                                  ? Colors.green
                                                  : Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(4)),
                                          child: Text(
                                              pos.isLong ? "LONG" : "SHORT",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      const SizedBox(width: 8),
                                      Text("${pos.leverage}x",
                                          style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  ElevatedButton(
                                      onPressed: () => _closePosition(pos),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[800],
                                          minimumSize: const Size(60, 30),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10)),
                                      child: const Text("Đóng",
                                          style:
                                              TextStyle(color: Colors.white))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text("Vốn Margin",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                      Text(
                                          "${pos.margin.toStringAsFixed(2)} USDT",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text("PNL (ROE%)",
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                      Text(
                                          "${pnl > 0 ? '+' : ''}${pnl.toStringAsFixed(2)} (${roe.toStringAsFixed(2)}%)",
                                          style: TextStyle(
                                              color: pnl >= 0
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
