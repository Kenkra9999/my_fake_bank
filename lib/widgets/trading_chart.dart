import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:my_fake_bank/models/crypto_model.dart';

class TradingChart extends StatelessWidget {
  final List<CandleData> data;
  const TradingChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      );
    }

    return SfCartesianChart(
      backgroundColor: const Color(0xFF0B0E11),
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        isVisible: false,
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        majorGridLines: const MajorGridLines(width: 0.1, color: Colors.grey),
      ),
      axes: [
        NumericAxis(
          name: 'volumeAxis',
          opposedPosition: false,
          isVisible: false,
        )
      ],
      indicators: <TechnicalIndicator>[
        EmaIndicator<CandleData, DateTime>(
          seriesName: 'MainSeries',
          valueField: 'close',
          period: 14,
          signalLineColor: Colors.blueAccent, // Đã sửa thành signalLineColor
        ),
        BollingerBandIndicator<CandleData, DateTime>(
          seriesName: 'MainSeries',
          upperLineColor: const Color(0x80E040FB),
          lowerLineColor: const Color(0x80E040FB),
        ),
      ],
      series: <CartesianSeries<CandleData, DateTime>>[
        ColumnSeries<CandleData, DateTime>(
          dataSource: data,
          name: 'Volume',
          xValueMapper: (CandleData d, _) => d.x,
          yValueMapper: (CandleData d, _) => d.volume,
          yAxisName: 'volumeAxis',
          color: const Color(0x339E9E9E),
        ),
        CandleSeries<CandleData, DateTime>(
          name: 'MainSeries',
          dataSource: data,
          xValueMapper: (CandleData d, _) => d.x,
          lowValueMapper: (CandleData d, _) => d.low,
          highValueMapper: (CandleData d, _) => d.high,
          openValueMapper: (CandleData d, _) => d.open,
          closeValueMapper: (CandleData d, _) => d.close,
          bearColor: Colors.redAccent,
          bullColor: Colors.greenAccent,
          enableSolidCandles: true,
        ),
      ],
    );
  }
}
