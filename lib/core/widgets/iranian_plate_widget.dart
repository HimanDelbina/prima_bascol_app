import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';
import '../utils/plate_formatter.dart';

class IranianPlateWidget extends StatelessWidget {
  final String? plateDisplay;
  final String? plateNumber;
  final IranianPlateModel? plateModel;
  final double scale;
  final bool compact;

  const IranianPlateWidget({
    super.key,
    this.plateDisplay,
    this.plateNumber,
    this.plateModel,
    this.scale = 1.0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final rawPlate = plateNumber ?? plateDisplay;
    final s = compact ? 0.85 : scale;
    final model = plateModel ?? PlateFormatter.parsePlate(rawPlate);

    if (model == null || !model.isValid) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          rawPlate ?? "---",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13 * s,
            color: Colors.grey.shade800,
          ),
        ),
      );
    }

    return Container(
      height: 38 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: Colors.black87, width: 1.5 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left Blue Strip (I.R. IRAN)
            Container(
              width: 18 * s,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusSm - 1.5),
                  bottomLeft: Radius.circular(AppDimensions.radiusSm - 1.5),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, size: 8 * s, color: Colors.white),
                  Text(
                    "I.R.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 5 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "IRAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 4 * s,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Part 1 (2 digits)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              child: Text(
                model.part1,
                style: TextStyle(
                  fontSize: 15 * s,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Letter
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4 * s),
              child: Text(
                model.letter,
                style: TextStyle(
                  fontSize: 14 * s,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Part 2 (3 digits)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              child: Text(
                model.part2,
                style: TextStyle(
                  fontSize: 15 * s,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Vertical Divider
            Container(
              width: 1.2 * s,
              height: double.infinity,
              color: Colors.black87,
            ),
            // Iran Code Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ایران",
                    style: TextStyle(
                      fontSize: 7 * s,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    model.iranCode,
                    style: TextStyle(
                      fontSize: 13 * s,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
