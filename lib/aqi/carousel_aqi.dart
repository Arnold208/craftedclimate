import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class AQICard extends StatelessWidget {
  final String location;
  final int aqi;

  const AQICard({Key? key, required this.location, required this.aqi})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        color: Colors.white, // Set the background color of the card
        child: Row(
          children: [
            // Text Column
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AQI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$aqi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _getColorForAQI(aqi),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'LOCATION',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Gauge Column
            Expanded(
              flex: 3,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 500,
                    axisLineStyle: const AxisLineStyle(
                      thickness: 0.1,
                      color: Colors.black12,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: 0,
                        endValue: 50,
                        color: Colors.green,
                        startWidth: 0.1,
                        endWidth: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: 51,
                        endValue: 100,
                        color: Colors.yellow,
                        startWidth: 0.1,
                        endWidth: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: 101,
                        endValue: 150,
                        color: Colors.orange,
                        startWidth: 0.1,
                        endWidth: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: 151,
                        endValue: 200,
                        color: Colors.red,
                        startWidth: 0.1,
                        endWidth: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: 201,
                        endValue: 300,
                        color: Colors.purple,
                        startWidth: 0.1,
                        endWidth: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: 301,
                        endValue: 500,
                        color: Colors.brown,
                        startWidth: 0.1,
                        endWidth: 0.1,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: aqi.toDouble(),
                        needleColor: Colors.black,
                        knobStyle: const KnobStyle(color: Colors.black),
                        needleStartWidth: 1,
                        needleEndWidth: 4,
                        lengthUnit: GaugeSizeUnit.factor,
                        needleLength: 0.8,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Container(
                          child: Text(
                            '$aqi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get color based on AQI value
  Color _getColorForAQI(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }
}
