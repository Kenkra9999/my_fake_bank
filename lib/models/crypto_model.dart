class CandleData {
  final DateTime x;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CandleData({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
}

class FuturePosition {
  String id;
  String symbol;
  bool isLong;
  double entryPrice;
  double margin;
  int leverage;
  double size;

  FuturePosition({
    required this.id,
    required this.symbol,
    required this.isLong,
    required this.entryPrice,
    required this.margin,
    required this.leverage,
    required this.size,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'isLong': isLong,
        'entryPrice': entryPrice,
        'margin': margin,
        'leverage': leverage,
        'size': size,
      };

  factory FuturePosition.fromJson(Map<String, dynamic> json) => FuturePosition(
        id: json['id'],
        symbol: json['symbol'],
        isLong: json['isLong'],
        entryPrice: json['entryPrice'].toDouble(),
        margin: json['margin'].toDouble(),
        leverage: json['leverage'],
        size: json['size'].toDouble(),
      );
}
