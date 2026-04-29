import 'dart:math';

// Wallet model
class Wallet {
  double usdtBalance;
  double vndBalance;

  Wallet({this.usdtBalance = 1000.0, this.vndBalance = 25000000.0});

  void deposit(String currency, double amount) {
    if (currency == 'USDT') {
      usdtBalance += amount;
    } else if (currency == 'VND') {
      vndBalance += amount;
    }
  }

  void withdraw(String currency, double amount) {
    if (currency == 'USDT' && usdtBalance >= amount) {
      usdtBalance -= amount;
    } else if (currency == 'VND' && vndBalance >= amount) {
      vndBalance -= amount;
    }
  }
}

// Candlestick data
class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

// Technical indicators
class TechnicalIndicators {
  List<double> volume;
  List<double> rsi;
  List<double> macd;
  List<double> bollingerUpper;
  List<double> bollingerMiddle;
  List<double> bollingerLower;
  List<double> movingAverage;

  TechnicalIndicators({
    required this.volume,
    required this.rsi,
    required this.macd,
    required this.bollingerUpper,
    required this.bollingerMiddle,
    required this.bollingerLower,
    required this.movingAverage,
  });

  static TechnicalIndicators calculate(List<CandleData> candles) {
    List<double> closes = candles.map((c) => c.close).toList();
    List<double> volumes = candles.map((c) => c.volume).toList();

    // Calculate RSI
    List<double> rsi = _calculateRSI(closes);

    // Calculate MACD
    List<double> macd = _calculateMACD(closes);

    // Calculate Bollinger Bands
    Map<String, List<double>> bb = _calculateBollingerBands(closes);

    // Calculate Moving Average
    List<double> ma = _calculateMA(closes);

    return TechnicalIndicators(
      volume: volumes,
      rsi: rsi,
      macd: macd,
      bollingerUpper: bb['upper']!,
      bollingerMiddle: bb['middle']!,
      bollingerLower: bb['lower']!,
      movingAverage: ma,
    );
  }

  static List<double> _calculateRSI(List<double> prices, {int period = 14}) {
    List<double> rsiValues = [];
    if (prices.length < period + 1) return [];

    for (int i = period; i < prices.length; i++) {
      double gains = 0;
      double losses = 0;

      for (int j = i - period; j < i; j++) {
        double change = prices[j + 1] - prices[j];
        if (change > 0) {
          gains += change;
        } else {
          losses += -change;
        }
      }

      double avgGain = gains / period;
      double avgLoss = losses / period;
      double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      double rsiValue = 100 - (100 / (1 + rs));
      rsiValues.add(rsiValue);
    }
    return rsiValues;
  }

  static List<double> _calculateMACD(List<double> prices) {
    List<double> ema12 = _calculateEMA(prices, 12);
    List<double> ema26 = _calculateEMA(prices, 26);

    List<double> macdLine = [];
    int minLen = min(ema12.length, ema26.length);
    for (int i = 0; i < minLen; i++) {
      macdLine.add(ema12[i] - ema26[i]);
    }
    return macdLine;
  }

  static List<double> _calculateEMA(List<double> prices, int period) {
    List<double> ema = [];
    double multiplier = 2.0 / (period + 1);
    double sma = prices.take(period).fold<double>(0, (a, b) => a + b) / period;
    ema.add(sma);

    for (int i = period; i < prices.length; i++) {
      double emaValue = prices[i] * multiplier + ema.last * (1 - multiplier);
      ema.add(emaValue);
    }
    return ema;
  }

  static Map<String, List<double>> _calculateBollingerBands(List<double> prices,
      {int period = 20, double stdDevMultiplier = 2.0}) {
    List<double> sma = [];
    List<double> upper = [];
    List<double> lower = [];

    for (int i = period - 1; i < prices.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += prices[j];
      }
      double avg = sum / period;
      sma.add(avg);

      double variance = 0;
      for (int j = i - period + 1; j <= i; j++) {
        variance += (prices[j] - avg) * (prices[j] - avg);
      }
      double stdDev = sqrt(variance / period);

      upper.add(avg + stdDev * stdDevMultiplier);
      lower.add(avg - stdDev * stdDevMultiplier);
    }

    return {
      'upper': upper,
      'middle': sma,
      'lower': lower,
    };
  }

  static List<double> _calculateMA(List<double> prices, {int period = 20}) {
    List<double> ma = [];
    for (int i = period - 1; i < prices.length; i++) {
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += prices[j];
      }
      ma.add(sum / period);
    }
    return ma;
  }
}

// Trade position
class TradePosition {
  String id;
  String symbol;
  bool isLong;
  double entryPrice;
  double size;
  int leverage;
  double margin;
  DateTime openTime;
  double? closePrice;
  DateTime? closeTime;
  bool isClosed;

  TradePosition({
    required this.id,
    required this.symbol,
    required this.isLong,
    required this.entryPrice,
    required this.size,
    required this.leverage,
    required this.margin,
    required this.openTime,
    this.closePrice,
    this.closeTime,
    this.isClosed = false,
  });

  double get pnl {
    double currentPrice = closePrice ?? entryPrice;
    if (isLong) {
      return (currentPrice - entryPrice) * size;
    } else {
      return (entryPrice - currentPrice) * size;
    }
  }

  double get pnlPercentage {
    double currentPrice = closePrice ?? entryPrice;
    if (isLong) {
      return ((currentPrice - entryPrice) / entryPrice) * 100;
    } else {
      return ((entryPrice - currentPrice) / entryPrice) * 100;
    }
  }
}
