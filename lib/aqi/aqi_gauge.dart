import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart'; // Import the Syncfusion gauges package

class AQIGauge extends StatelessWidget {
  final double aqi;

  const AQIGauge({Key? key, required this.aqi}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 500,
            ranges: <GaugeRange>[
              GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
              GaugeRange(startValue: 50, endValue: 100, color: Colors.yellow),
              GaugeRange(startValue: 100, endValue: 150, color: Colors.orange),
              GaugeRange(startValue: 150, endValue: 200, color: Colors.red),
              GaugeRange(startValue: 200, endValue: 300, color: Colors.purple),
              GaugeRange(startValue: 300, endValue: 500, color: Colors.brown),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(value: aqi),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Container(
                  child: Text(
                    aqi.toStringAsFixed(2),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                angle: 90,
                positionFactor: 0.5,
              )
            ],
          ),
        ],
      ),
    );
  }
}
