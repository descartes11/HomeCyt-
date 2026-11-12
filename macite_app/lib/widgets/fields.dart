import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'ui.dart';

/// Champ du design system : libellé 13 au-dessus, fond neutral-100,
/// focus 2 px accent, erreur bordure + message accent-2-700.
class AppField extends StatefulWidget {
  const AppField({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.icon,
    this.hint,
    this.error,
    this.helper,
    this.obscure = false,
    this.keyboardType,
    this.suffixText,
    this.maxLines = 1,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.labelTrailing,
    this.autofocus = false,
    this.valid = false,
  });

  final String? label;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final IconData? icon;
  final String? hint;
  final String? error;
  final String? helper;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? suffixText;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final Widget? labelTrailing;
  final bool autofocus;
  final bool valid;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  final _focus = FocusNode();
  late final TextEditingController _own = TextEditingController(text: widget.initialValue ?? '');
  bool _show = false;

  TextEditingController get _c => widget.controller ?? _own;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final err = widget.error != null;
    final focused = _focus.hasFocus;
    final borderColor = err ? p.magenta : (focused ? p.accent : (widget.valid ? p.a500 : p.line));
    final bw = err || focused || widget.valid ? 2.0 : 1.0;
    final iconColor = err ? p.m700 : (focused ? p.accent : p.text2);
    final multi = widget.maxLines > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label!,
                  style: ts(13, w: FontWeight.w600, c: err ? p.m700 : p.text),
                ),
              ),
              ?widget.labelTrailing,
            ],
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: BoxConstraints(minHeight: multi ? 96 : 48),
          padding: EdgeInsets.fromLTRB(16 - bw + 1, multi ? 10 : 0, widget.obscure ? 4 : 16 - bw + 1, multi ? 10 : 0),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: AppRadius.r,
            border: Border.all(color: borderColor, width: bw),
          ),
          child: Row(
            crossAxisAlignment: multi ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[Ph(widget.icon!, color: iconColor), const SizedBox(width: 12)],
              Expanded(
                child: TextField(
                  controller: _c,
                  focusNode: _focus,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  obscureText: widget.obscure && !_show,
                  keyboardType: multi ? TextInputType.multiline : widget.keyboardType,
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  minLines: multi ? 3 : 1,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.textCapitalization,
                  style: ts(16, c: p.text, h: 1.4),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: multi ? 4 : 13),
                    hintText: widget.hint,
                    hintStyle: ts(16, c: p.text2, h: 1.4),
                  ),
                ),
              ),
              if (widget.suffixText != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    widget.suffixText!,
                    style: ts(14, w: FontWeight.w600, c: p.text2),
                  ),
                ),
              if (widget.obscure)
                IconBtn(
                  _show ? PI.eyeSlash : PI.eye,
                  size: 40,
                  color: p.text2,
                  tooltip: 'Afficher le mot de passe',
                  onPressed: () => setState(() => _show = !_show),
                ),
            ],
          ),
        ),
        if (err) ...[const SizedBox(height: 8), ErrorText(widget.error!)],
        if (!err && widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: ts(13, w: FontWeight.w500, c: p.text2, h: 1.4),
          ),
        ],
      ],
    );
  }
}

/// Liste déroulante stylée comme un champ.
class AppSelect<T> extends StatelessWidget {
  const AppSelect({super.key, this.label, required this.value, required this.items, required this.onChanged, this.icon, this.hint, this.error});
  final String? label;
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  final String? hint;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final err = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: ts(13, w: FontWeight.w600, c: err ? p.m700 : p.text),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 48,
          padding: EdgeInsets.only(left: err ? 14 : 15, right: 8),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: AppRadius.r,
            border: Border.all(color: err ? p.magenta : p.line, width: err ? 2 : 1),
          ),
          child: Row(
            children: [
              if (icon != null) ...[Ph(icon!, color: err ? p.m700 : p.text2), const SizedBox(width: 12)],
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    dropdownColor: p.card,
                    borderRadius: AppRadius.r,
                    icon: Ph(PI.caretDown, size: 20, color: p.text2),
                    hint: Text(hint ?? '', style: ts(16, c: p.text2)),
                    style: ts(16, c: p.text),
                    items: [
                      for (final it in items)
                        DropdownMenuItem(
                          value: it.$1,
                          child: Text(it.$2, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (err) ...[const SizedBox(height: 8), ErrorText(error!)],
      ],
    );
  }
}

/// Case à cocher avec libellé.
class CheckLine extends StatelessWidget {
  const CheckLine({super.key, required this.value, required this.onChanged, required this.label, this.error = false});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Tap(
      onTap: () => onChanged(!value),
      scale: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Ph(value ? PI.checkSquare : PI.square, color: value ? p.btn : (error ? p.m700 : p.text2)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: ts(14, w: FontWeight.w500, c: p.text, h: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// N'accepte que les chiffres et les espaces.
final digitsSpaces = FilteringTextInputFormatter.allow(RegExp(r'[\d\s]'));
