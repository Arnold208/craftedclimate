import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class CustomGauge extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double width;
  final double height;

  const CustomGauge({
    super.key,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: minValue,
            maximum: maxValue,
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 400,
                endValue: 1000,
                color: Colors.green, // Excellent to Fair
              ),
              GaugeRange(
                startValue: 1000,
                endValue: 1400,
                color: Colors.yellow, // Mediocre
              ),
              GaugeRange(
                startValue: 1400,
                endValue: 2100,
                color: Colors.red, // Bad
              ),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(value: value),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  value.toStringAsFixed(2),
                  style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(255, 0, 0, 0)),
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
