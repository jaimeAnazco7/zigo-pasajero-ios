import 'package:flutter/material.dart';
import '../../utils/Extensions/dataTypeExtensions.dart';
import '../Colors.dart';
import '../Common.dart';
import '../Constants.dart';
import 'app_common.dart';

/// Default App Button
class AppButtonWidget extends StatefulWidget {
  final Function? onTap;
  final String? text;
  final double? width;
  final Color? color;
  final Color? textColor;
  final Color? disabledColor;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? splashColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final TextStyle? textStyle;
  final ShapeBorder? shapeBorder;
  final Widget? child;
  final double? elevation;
  final double? height;
  final bool? enabled;
  final bool? enableScaleAnimation;

  AppButtonWidget({
    this.onTap,
    this.text,
    this.width,
    this.color,
    this.textColor,
    this.padding,
    this.margin,
    this.textStyle,
    this.shapeBorder,
    this.child,
    this.elevation,
    this.enabled,
    this.height,
    this.disabledColor,
    this.focusColor,
    this.hoverColor,
    this.splashColor,
    this.enableScaleAnimation,
  });

  @override
  _AppButtonWidgetState createState() => _AppButtonWidgetState();
}

class _AppButtonWidgetState extends State<AppButtonWidget> with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  AnimationController? _controller;

  @override
  void initState() {
    if (widget.enableScaleAnimation.validate(value: enableAppButtonScaleAnimationGlobal)) {
      _controller = AnimationController(
        vsync: this,
        duration: Duration(
          milliseconds: appButtonScaleAnimationDurationGlobal ?? 50,
        ),
        lowerBound: 0.0,
        upperBound: 0.1,
      )..addListener(() {
          setState(() {});
        });
    }
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      _scale = 1 - _controller!.value;
    }

    if (widget.enableScaleAnimation.validate(value: enableAppButtonScaleAnimationGlobal)) {
      return Listener(
        onPointerDown: (details) {
          _controller?.forward();
        },
        onPointerUp: (details) {
          _controller?.reverse();
        },
        child: Transform.scale(
          scale: _scale,
          child: buildButton(),
        ),
      );
    } else {
      return buildButton();
    }
  }

  Widget buildButton() {
    final buttonColor = widget.color ?? appButtonBackgroundColorGlobal;
    final isEnabled = widget.enabled.validate(value: true);
    
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius(),
          // Efecto neón con sombras de brillo
          boxShadow: isEnabled && buttonColor == primaryColor
              ? [
                  // Sombra neón cyan (múltiples capas para efecto de brillo)
                  BoxShadow(
                    color: primaryColor.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ]
              : widget.elevation != null && widget.elevation! > 0
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: widget.elevation! * 2,
                        offset: Offset(0, widget.elevation!),
                      ),
                    ]
                  : null,
        ),
        child: ClipRRect(
          borderRadius: radius(),
          child: MaterialButton(
            minWidth: widget.width,
            padding: widget.padding ?? dynamicAppButtonPadding(context),
            onPressed: isEnabled ? widget.onTap as void Function()? : null,
            color: buttonColor,
            child: widget.child ??
                Text(
                  widget.text!.validate(),
                  style: widget.textStyle ??
                      boldTextStyle(
                        color: widget.textColor ?? appButtonTextStyleColor,
                      ),
                ),
            shape: widget.shapeBorder ?? defaultAppButtonShapeBorder,
            elevation: 0, // Sin elevación, usamos boxShadow para efecto neón
            animationDuration: Duration(milliseconds: 300),
            height: widget.height,
            disabledColor: widget.disabledColor ?? scaffoldSecondaryDark,
            focusColor: widget.focusColor ?? primaryColor.withOpacity(0.2),
            hoverColor: widget.hoverColor ?? primaryColor.withOpacity(0.1),
            splashColor: widget.splashColor ?? primaryColor.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}
