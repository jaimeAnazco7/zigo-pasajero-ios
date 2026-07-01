import 'package:flutter/material.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class DrawerWidget extends StatefulWidget {
  final String title;
  final String iconData;
  final IconData? icon;
  final Function() onTap;

  DrawerWidget({required this.title, required this.iconData, this.icon, required this.onTap});

  @override
  DrawerWidgetState createState() => DrawerWidgetState();
}

class DrawerWidgetState extends State<DrawerWidget> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return inkWellWidget(
      onTap: widget.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: neonSurfaceCard.withOpacity(0.65),
                    border: Border.all(color: neonAccent.withOpacity(0.35)),
                    borderRadius: radius(defaultRadius),
                  ),
                  padding: EdgeInsets.all(4),
                  child: widget.icon != null
                      ? Icon(widget.icon, color: neonAccent, size: 26)
                      : Image.asset(widget.iconData, height: 30, width: 30, color: neonAccent),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(widget.title, style: primaryTextStyle(color: Colors.white)),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: neonHighlight.withOpacity(0.65))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
