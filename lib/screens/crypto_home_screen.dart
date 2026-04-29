import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/crypto_data.dart';

class CryptoHomeScreen extends StatefulWidget {
  const CryptoHomeScreen({super.key});

  @override
  State<CryptoHomeScreen> createState() => _CryptoHomeScreenState();
}

class _CryptoHomeScreenState extends State<CryptoHomeScreen> {
  late Wallet wallet;
  String selectedSymbol = 'BTC/USDT';
  String selectedTimeframe = '1m';
  double currentPrice = 76080.0;
  double priceChange = -0.88;
  int selectedLeverage = 10;
  bool isLongMode = true;
  List<CandleData> chartData = [];
  TechnicalIndicators? indicators;
  List<TradePosition> positions = [];
  Timer? updateTimer;
  final TextEditingController sizeController = TextEditingController();

  final List<String> timeframes = ['1s', '1m', '3m', '5m', '15m', '30m', '1h', '2h', '4h', '1d'];
  final List<String> symbols = ['BTC/USDT', 'ETH/USDT', 'BNB/USDT'];
  final Map<String, double> basePrices = {
    'BTC/USDT': 76080.0,
    'ETH/USDT': 2272.8,
    'BNB/USDT': 615.5,
  };

  double _positionPnl(TradePosition position, {double? exitPrice}) {
    final price = exitPrice ?? currentPrice;
    final priceMove = position.isLong
        ? price - position.entryPrice
        : position.entryPrice - price;

    return (priceMove / position.entryPrice) * position.size;
  }

  double _positionPnlPercentage(TradePosition position, {double? exitPrice}) {
    final price = exitPrice ?? currentPrice;
    final priceMove = position.isLong
        ? price - position.entryPrice
        : position.entryPrice - price;

    return (priceMove / position.entryPrice) * 100 * position.leverage;
  }

  @override
  void initState() {
    super.initState();
    wallet = Wallet();
    _generateChartData();
    _startAutoUpdate();
  }

  void _generateChartData() {
    chartData = [];
    final Random random = Random();
    DateTime now = DateTime.now();
    double price = basePrices[selectedSymbol] ?? 76080.0;

    for (int i = 59; i >= 0; i--) {
      DateTime candleTime = now.subtract(Duration(minutes: i));
      double open = price;
      double change = (random.nextDouble() - 0.5) * 200;
      double close = price + change;
      double high = max(open, close) + random.nextDouble() * 100;
      double low = min(open, close) - random.nextDouble() * 100;
      double vol = random.nextDouble() * 5000;

      chartData.add(CandleData(
        time: candleTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: vol,
      ));

      price = close;
    }

    currentPrice = chartData.last.close;
    priceChange = ((currentPrice - basePrices[selectedSymbol]!) / basePrices[selectedSymbol]!) * 100;
    indicators = TechnicalIndicators.calculate(chartData);
  }

  void _startAutoUpdate() {
    updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && chartData.isNotEmpty) {
        final Random random = Random();
        final lastCandle = chartData.last;
        final newPrice = lastCandle.close + (random.nextDouble() - 0.5) * 50;

        chartData[chartData.length - 1] = CandleData(
          time: lastCandle.time,
          open: lastCandle.open,
          high: max(lastCandle.high, newPrice),
          low: min(lastCandle.low, newPrice),
          close: newPrice,
          volume: lastCandle.volume + random.nextInt(500).toDouble(),
        );

        setState(() {
          currentPrice = newPrice;
          priceChange = ((currentPrice - basePrices[selectedSymbol]!) / basePrices[selectedSymbol]!) * 100;
          indicators = TechnicalIndicators.calculate(chartData);
        });
      }
    });
  }

  void _openPosition() {
    if (sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter position size')),
      );
      return;
    }

    final size = double.tryParse(sizeController.text);
    if (size == null || size <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid position size')),
      );
      return;
    }

    double margin = size / selectedLeverage;

    if (wallet.usdtBalance < margin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    wallet.withdraw('USDT', margin);

    TradePosition position = TradePosition(
      id: 'POS-${DateTime.now().millisecondsSinceEpoch}',
      symbol: selectedSymbol,
      isLong: isLongMode,
      entryPrice: currentPrice,
      size: size,
      leverage: selectedLeverage,
      margin: margin,
      openTime: DateTime.now(),
    );

    setState(() {
      positions.add(position);
      sizeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${isLongMode ? "Long" : "Short"} position opened at \$${currentPrice.toStringAsFixed(2)}',
        ),
        backgroundColor: isLongMode ? Colors.green : Colors.red,
      ),
    );
  }

  void _closePosition(TradePosition position) {
    final pnl = _positionPnl(position, exitPrice: currentPrice);

    setState(() {
      position.closePrice = currentPrice;
      position.closeTime = DateTime.now();
      position.isClosed = true;

      wallet.deposit('USDT', max(0, position.margin + pnl));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Position closed. P&L: ${pnl > 0 ? "+" : ""}\$${pnl.toStringAsFixed(2)}',
        ),
        backgroundColor: pnl >= 0 ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        title: const Text('Crypto Trading Pro', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wallet Section
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Wallet Balance', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('USDT', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            '\$${wallet.usdtBalance.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('VND', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            'VND ${(wallet.vndBalance / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showDepositDialog(),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Deposit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showWithdrawDialog(),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Symbol & Price
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: selectedSymbol,
                    dropdownColor: const Color(0xFF1A1F2E),
                    style: const TextStyle(color: Colors.white),
                    items: symbols.map<DropdownMenuItem<String>>((v) {
                      return DropdownMenuItem(value: v, child: Text(v));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          selectedSymbol = v;
                          _generateChartData();
                        });
                      }
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '${priceChange > 0 ? "+" : ""}${priceChange.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: priceChange >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timeframe Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: timeframes
                      .map((tf) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => selectedTimeframe = tf),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selectedTimeframe == tf ? Colors.blue : const Color(0xFF1A1F2E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selectedTimeframe == tf ? Colors.blue : Colors.grey[800]!,
                                  ),
                                ),
                                child: Text(
                                  tf,
                                  style: TextStyle(
                                    color: selectedTimeframe == tf ? Colors.white : Colors.grey[500],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),

            // Chart
            if (chartData.isNotEmpty && indicators != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 350,
                      child: SfCartesianChart(
                        plotAreaBorderColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                        primaryXAxis: DateTimeAxis(
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                          axisLineStyle: AxisLineStyle(color: Colors.grey.shade800, width: 0.5),
                          majorTickLines: const MajorTickLines(size: 0),
                        ),
                        primaryYAxis: NumericAxis(
                          labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
                          axisLineStyle: AxisLineStyle(color: Colors.grey.shade800, width: 0.5),
                          majorTickLines: const MajorTickLines(size: 0),
                        ),
                        series: [
                          CandleSeries<CandleData, DateTime>(
                            dataSource: chartData,
                            xValueMapper: (CandleData candle, _) => candle.time,
                            openValueMapper: (CandleData candle, _) => candle.open,
                            highValueMapper: (CandleData candle, _) => candle.high,
                            lowValueMapper: (CandleData candle, _) => candle.low,
                            closeValueMapper: (CandleData candle, _) => candle.close,
                            name: 'Price',
                            bullColor: Colors.green,
                            bearColor: Colors.red,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Indicators
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Technical Indicators (5)',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildIndicatorChip('Volume', '${indicators!.volume.last.toStringAsFixed(0)} USDT'),
                              _buildIndicatorChip('RSI(14)', '${indicators!.rsi.isNotEmpty ? indicators!.rsi.last.toStringAsFixed(2) : "N/A"}'),
                              _buildIndicatorChip('MACD', '${indicators!.macd.isNotEmpty ? indicators!.macd.last.toStringAsFixed(4) : "N/A"}'),
                              _buildIndicatorChip('BB Upper', '${indicators!.bollingerUpper.isNotEmpty ? indicators!.bollingerUpper.last.toStringAsFixed(2) : "N/A"}'),
                              _buildIndicatorChip('MA(20)', '${indicators!.movingAverage.isNotEmpty ? indicators!.movingAverage.last.toStringAsFixed(2) : "N/A"}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Trading Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Open Position',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLongMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isLongMode ? Colors.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'Long',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isLongMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isLongMode ? Colors.red : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'Short',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Leverage', style: TextStyle(color: Colors.white, fontSize: 14)),
                      Text('${selectedLeverage}x (Max: 500x)', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: selectedLeverage.toDouble(),
                    min: 1,
                    max: 500,
                    divisions: 499,
                    activeColor: Colors.blue,
                    onChanged: (val) => setState(() => selectedLeverage = val.toInt()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: sizeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Position Size (USDT)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openPosition,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: const Text(
                        'Open Position',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Positions
            if (positions.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Positions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    ...positions.map((pos) => _buildPositionCard(pos)),
                  ],
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorChip(String name, String value) {
    return Chip(
      label: Text('$name: $value', style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: Colors.blue.withOpacity(0.3),
    );
  }

  Widget _buildPositionCard(TradePosition pos) {
    final exitPrice = pos.isClosed ? pos.closePrice : null;
    double pnl = _positionPnl(pos, exitPrice: exitPrice);
    double pnlPct = _positionPnlPercentage(pos, exitPrice: exitPrice);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pos.isLong ? "LONG" : "SHORT"} ${pos.symbol}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: pos.isLong ? Colors.green : Colors.red),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entry: \$${pos.entryPrice.toStringAsFixed(2)} | ${pos.leverage}x',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pnl > 0 ? "+" : ""}\$${pnl.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: pnl >= 0 ? Colors.green : Colors.red, fontSize: 14),
                  ),
                  Text(
                    '${pnlPct > 0 ? "+" : ""}${pnlPct.toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 12, color: pnlPct >= 0 ? Colors.green : Colors.red),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: pos.isClosed ? null : () => _closePosition(pos),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 8)),
              child: Text(
                pos.isClosed ? 'Closed' : 'Close',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    TextEditingController amountController = TextEditingController();
    String selectedCurrency = 'USDT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          title: const Text('Deposit', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: const Color(0xFF1A1F2E),
                style: const TextStyle(color: Colors.white),
                items: ['USDT', 'VND'].map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedCurrency = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  setState(() => wallet.deposit(selectedCurrency, amount));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deposited $amount $selectedCurrency'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Deposit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    TextEditingController amountController = TextEditingController();
    String selectedCurrency = 'USDT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          title: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: const Color(0xFF1A1F2E),
                style: const TextStyle(color: Colors.white),
                items: ['USDT', 'VND'].map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedCurrency = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  setState(() => wallet.withdraw(selectedCurrency, amount));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Withdrew $amount $selectedCurrency'), backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Withdraw', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
