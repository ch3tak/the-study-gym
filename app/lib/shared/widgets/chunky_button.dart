import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The Duolingo-style "3D" button: a flat top face sitting on a darker slab
/// that acts as a drop shadow. Pressing it drops the top face down onto the
/// slab. No blur shadows anywhere — depth comes purely from this offset.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.trailing,
    this.height = 56,
    this.fullWidth = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final Widget? trailing;
  final double height;
  final bool fullWidth;
  final bool enabled;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.enabled && widget.onPressed != null;
    final buttonColor = widget.color ?? colors.accent;
    final baseColor = active ? buttonColor : colors.notStartedLight;
    final slabColor = active
        ? HSLColor.fromColor(buttonColor)
            .withLightness(
              (HSLColor.fromColor(buttonColor).lightness - 0.13).clamp(0.0, 1.0),
            )
            .toColor()
        : colors.border;
    final textColor = active ? (widget.textColor ?? colors.accentInk) : colors.inkFaint;

    const slabHeight = 5.0;

    return GestureDetector(
      onTapDown: active ? (_) => setState(() => _pressed = true) : null,
      onTapUp: active
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: active ? () => setState(() => _pressed = false) : null,
      child: SizedBox(
        width: widget.fullWidth ? double.infinity : null,
        height: widget.height + slabHeight,
        child: Stack(
          children: [
            Positioned.fill(
              top: slabHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: slabColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              top: _pressed ? slabHeight : 0,
              left: 0,
              right: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: textColor, size: 22),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: textColor,
                              fontSize: 16,
                            ),
                      ),
                      if (widget.trailing != null) ...[
                        const SizedBox(width: 8),
                        widget.trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
