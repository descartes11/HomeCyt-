import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'anim.dart';

import 'icons.dart';

export 'icons.dart';

// ───────────────────────────── Icônes ─────────────────────────────

/// Icône Phosphor duotone (24 px par défaut).
class Ph extends StatelessWidget {
  const Ph(this.icon, {super.key, this.size = 24, this.color});
  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color;
    final sec = phSecondary[icon.codePoint];
    final main = Icon(icon, size: size, color: c);
    if (sec == null) return main;
    // Duotone : couche secondaire translucide (25 %) sous le tracé principal.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(sec, size: size, color: c?.withValues(alpha: 0.25)),
          main,
        ],
      ),
    );
  }
}

/// Pastille carrée contenant une icône (fond teinté).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = Tone.neutral, this.size = 40, this.iconSize, this.bg, this.fg});
  final IconData icon;
  final Tone tone;
  final double size;
  final double? iconSize;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    final (b, f) = context.pal.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg ?? b, borderRadius: AppRadius.r),
      alignment: Alignment.center,
      child: Ph(icon, size: iconSize ?? (size * 0.55).clamp(16, 40), color: fg ?? f),
    );
  }
}

/// Avatar rond avec initiales.
class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.tone = Tone.strong, this.size = 40, this.fontSize});
  final String initials;
  final Tone tone;
  final double size;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final (b, f) = context.pal.tone(tone);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: b, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(fontSize: fontSize ?? size * 0.36, fontWeight: FontWeight.w700, color: f),
      ),
    );
  }
}

// ───────────────────────────── Textes ─────────────────────────────

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color? c, double? h, double ls = 0, FontStyle? style}) =>
    TextStyle(fontFamily: kFontFamily, fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls, fontStyle: style);

/// Surtitre : 13/700 majuscules, interlettrage 0,04 em, accent-700.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: ts(13, w: FontWeight.w700, c: color ?? context.pal.link, ls: 0.52),
  );
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.size = 28});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: ts(size, w: FontWeight.w700, c: context.pal.text, ls: -0.2, h: 1.2),
  );
}

/// Titre de section 20/600 avec action optionnelle (« Voir tout »).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.size = 20, this.trailing});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final double size;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: ts(size, w: FontWeight.w600, c: context.pal.text),
          ),
        ),
        ?trailing,
        if (action != null) LinkButton(action!, onPressed: onAction),
      ],
    );
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.msg, {super.key});
  final String msg;
  @override
  Widget build(BuildContext context) {
    final c = context.pal.m700;
    return FadeUp(
      offset: 4,
      child: Row(
        children: [
          Ph(PI.warningCircle, size: 16, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              msg,
              style: ts(13, w: FontWeight.w500, c: c),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Boutons ─────────────────────────────

class _Pressable extends StatefulWidget {
  const _Pressable({required this.builder, this.onTap, this.scale = 0.98});
  final Widget Function(bool hover, bool pressed) builder;
  final VoidCallback? onTap;
  final double scale;
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _h = false, _p = false;
  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _p = true) : null,
        onTapUp: enabled ? (_) => setState(() => _p = false) : null,
        onTapCancel: enabled ? () => setState(() => _p = false) : null,
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(scale: _p ? widget.scale : 1, duration: const Duration(milliseconds: 120), child: widget.builder(_h, _p)),
      ),
    );
  }
}

/// Zone cliquable générique avec états survol / pressé et focus clavier.
class Tap extends StatelessWidget {
  const Tap({super.key, required this.child, this.onTap, this.scale = 0.98});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    enabled: onTap != null,
    actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => onTap?.call())},
    child: _Pressable(onTap: onTap, scale: scale, builder: (_, _) => child),
  );
}

enum BtnKind { primary, outline, ghost, danger, dangerOutline, neutral }

/// Bouton du design system : plein (accent-700), contour (accent-200), texte, magenta.
class Btn extends StatelessWidget {
  const Btn(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.kind = BtnKind.primary,
    this.height = 48,
    this.expand = false,
    this.busy = false,
    this.fontSize = 16,
    this.padding = 20,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final BtnKind kind;
  final double height;
  final bool expand;
  final bool busy;
  final double fontSize;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Pressable(
      onTap: busy ? null : onPressed,
      builder: (hover, pressed) {
        late Color bg, fg;
        Border? border;
        switch (kind) {
          case BtnKind.primary:
            bg = pressed ? p.btnPressed : (hover ? (p.dark ? AppColors.a300 : AppColors.a800) : p.btn);
            fg = p.onBtn;
          case BtnKind.outline:
            bg = pressed ? p.a200 : (hover ? p.a100 : p.card);
            fg = p.link;
            border = Border.all(color: p.outline);
          case BtnKind.ghost:
            bg = pressed ? p.a200 : (hover ? p.a100 : Colors.transparent);
            fg = p.link;
          case BtnKind.danger:
            bg = pressed ? AppColors.m800 : (hover ? AppColors.m700 : p.magenta);
            fg = AppColors.n100;
          case BtnKind.dangerOutline:
            bg = pressed ? p.m200 : (hover ? p.m100 : p.card);
            fg = p.m700;
            border = Border.all(color: p.dark ? AppColors.m800 : AppColors.m300);
          case BtnKind.neutral:
            bg = pressed ? p.chipHover : (hover ? p.chipHover : p.chip);
            fg = p.strong;
        }
        if (onPressed == null && !busy) {
          bg = kind == BtnKind.ghost ? Colors.transparent : p.chip;
          fg = p.text2;
        }
        final content = Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[Spinner(color: fg), const SizedBox(width: 10)],
            if (icon != null && !busy) ...[Ph(icon!, size: fontSize + 4, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: ts(fontSize, w: FontWeight.w600, c: fg),
              ),
            ),
            if (trailingIcon != null) ...[const SizedBox(width: 8), Ph(trailingIcon!, size: fontSize + 4, color: fg)],
          ],
        );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: height,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.r, border: border),
          child: content,
        );
      },
    );
  }
}

/// Lien / bouton texte accent (« Voir tout », « Mot de passe oublié ? »).
class LinkButton extends StatelessWidget {
  const LinkButton(this.label, {super.key, this.onPressed, this.icon, this.color, this.size = 14});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Pressable(
      onTap: onPressed,
      builder: (h, pr) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: pr || h ? p.a100 : Colors.transparent, borderRadius: AppRadius.r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Ph(icon!, size: size + 4, color: color ?? p.link), const SizedBox(width: 6)],
            Text(
              label,
              style: ts(size, w: FontWeight.w600, c: color ?? p.link),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton icône carré 48×48 (retour, notifications…).
class IconBtn extends StatelessWidget {
  const IconBtn(this.icon, {super.key, this.onPressed, this.tooltip, this.filled = false, this.size = 48, this.color, this.dot = false, this.bg});
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool filled;
  final double size;
  final Color? color;
  final Color? bg;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final w = _Pressable(
      onTap: onPressed,
      scale: 0.94,
      builder: (h, pr) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: size,
        height: size,
        decoration: BoxDecoration(color: pr ? p.a200 : (h ? p.a100 : (bg ?? (filled ? p.card : Colors.transparent))), borderRadius: AppRadius.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Ph(icon, color: color ?? p.strong),
            if (dot)
              Positioned(
                top: size * 0.2,
                right: size * 0.22,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: p.strong,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.card, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

// ───────────────────────────── Badges / puces ─────────────────────────────

/// Badge de statut : toujours icône + libellé (12/600).
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.icon, this.tone = Tone.neutral, this.height = 26, this.fontSize = 12});
  final String label;
  final IconData? icon;
  final Tone tone;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final (b, f) = context.pal.tone(tone);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: height,
      padding: EdgeInsets.only(left: icon != null ? 8 : 10, right: 10),
      decoration: BoxDecoration(color: b, borderRadius: AppRadius.r),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Ph(icon!, size: fontSize + 4, color: f), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(fontSize, w: FontWeight.w600, c: f),
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce de filtre / choix (sélectionnée : accent-200 / accent-800).
class ChoiceChipX extends StatelessWidget {
  const ChoiceChipX(this.label, {super.key, required this.selected, this.onTap, this.icon, this.height = 40});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Pressable(
      onTap: onTap,
      builder: (h, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        padding: EdgeInsets.only(left: icon != null ? 10 : 14, right: 14),
        decoration: BoxDecoration(
          color: selected ? p.a200 : (h ? p.a100 : p.card),
          borderRadius: AppRadius.r,
          border: Border.all(color: selected ? p.a200 : p.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Ph(icon!, size: 18, color: selected ? p.a800 : p.strong), const SizedBox(width: 6)],
            Text(
              label,
              style: ts(14, w: FontWeight.w600, c: selected ? p.a800 : p.strong),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rangée de puces défilante horizontalement.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children, this.wrap = false});
  final List<Widget> children;
  final bool wrap;
  @override
  Widget build(BuildContext context) {
    if (wrap) return Wrap(spacing: 8, runSpacing: 8, children: children);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 8), children[i]],
        ],
      ),
    );
  }
}

/// Contrôle segmenté : piste neutral-200, option active neutral-100 + ombre sm.
class Segmented<T> extends StatelessWidget {
  const Segmented({super.key, required this.options, required this.value, required this.onChanged, this.height = 40});
  final List<(T, String, IconData?)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.chip, borderRadius: AppRadius.r),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Tap(
                onTap: () => onChanged(o.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: kEase,
                  height: height,
                  decoration: BoxDecoration(
                    color: o.$1 == value ? p.card : Colors.transparent,
                    borderRadius: AppRadius.rs,
                    boxShadow: o.$1 == value ? AppShadows.sm : null,
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (o.$3 != null) ...[Ph(o.$3!, size: 18, color: o.$1 == value ? p.text : p.text2), const SizedBox(width: 6)],
                      Text(
                        o.$2,
                        style: ts(14, w: FontWeight.w600, c: o.$1 == value ? p.text : p.text2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Surfaces ─────────────────────────────

/// Carte : fond neutral-100, rayon 2, sans ombre ni bordure.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.color, this.border, this.shadow});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget box(bool h) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      decoration: BoxDecoration(
        color: h && onTap != null ? Color.alphaBlend(p.a100.withValues(alpha: 0.6), color ?? p.card) : (color ?? p.card),
        borderRadius: AppRadius.r,
        border: border,
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return box(false);
    return _Pressable(onTap: onTap, scale: 0.99, builder: (h, _) => box(h));
  }
}

/// Carte sélectionnable (profil, cité, urgence, chambre…).
class SelectCard extends StatelessWidget {
  const SelectCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.extra,
    required this.selected,
    required this.onTap,
    this.tone = Tone.neutral,
    this.radio = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? extra;
  final bool selected;
  final VoidCallback onTap;
  final Tone tone;
  final bool radio;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _Pressable(
      onTap: onTap,
      scale: 0.99,
      builder: (h, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(selected ? 15 : 16),
        decoration: BoxDecoration(
          color: selected ? p.a100 : p.card,
          borderRadius: AppRadius.r,
          border: Border.all(color: selected ? p.btn : (h ? p.a200 : p.line), width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: selected ? p.btn : p.tone(tone).$1, borderRadius: AppRadius.r),
              alignment: Alignment.center,
              child: Ph(icon, size: 26, color: selected ? p.onBtn : p.tone(tone).$2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ts(16, w: FontWeight.w700, c: p.text),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: ts(13, w: FontWeight.w500, c: p.text2, h: 1.4),
                    ),
                  ],
                  if (extra != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      extra!,
                      style: ts(13, w: FontWeight.w500, c: p.text2),
                    ),
                  ],
                ],
              ),
            ),
            if (radio) ...[
              const SizedBox(width: 8),
              Ph(selected ? PI.radioButton : PI.circle, color: selected ? p.btn : (p.dark ? AppColors.n500 : AppColors.n600)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bloc vide (aucun résultat).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.text});
  final IconData icon;
  final String title;
  final String? text;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return FadeUp(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            IconTile(icon, size: 64, iconSize: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: ts(16, w: FontWeight.w700, c: p.text),
            ),
            if (text != null) ...[
              const SizedBox(height: 4),
              Text(
                text!,
                textAlign: TextAlign.center,
                style: ts(14, c: p.text2, h: 1.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'information (hors ligne, succès…).
class Banner2 extends StatelessWidget {
  const Banner2(this.text, {super.key, required this.icon, this.tone = Tone.magSoft});
  final String text;
  final IconData icon;
  final Tone tone;
  @override
  Widget build(BuildContext context) {
    final (b, f) = context.pal.tone(tone);
    return FadeUp(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: b, borderRadius: AppRadius.r),
        child: Row(
          children: [
            Ph(icon, color: f),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: ts(14, w: FontWeight.w500, c: f, h: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Note d'information grisée avec icône.
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = PI.info});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Ph(icon, size: 18, color: p.text2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: ts(13, w: FontWeight.w500, c: p.text2, h: 1.45),
          ),
        ),
      ],
    );
  }
}

/// Barre de progression (rayon 2).
class Progress extends StatelessWidget {
  const Progress(this.value, {super.key, this.height = 6, this.color, this.track});
  final double value;
  final double height;
  final Color? color, track;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: height,
      decoration: BoxDecoration(color: track ?? p.chip, borderRadius: AppRadius.r),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: const Duration(milliseconds: 700),
        curve: kEase,
        builder: (_, v, _) => FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(color: color ?? p.btn, borderRadius: AppRadius.r),
          ),
        ),
      ),
    );
  }
}

/// Indicateur d'étapes (3 segments).
class StepBar extends StatelessWidget {
  const StepBar(this.step, {super.key, this.total = 3, this.labels});
  final int step;
  final int total;
  final List<String>? labels;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        for (var i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: kEase,
                  height: 4,
                  decoration: BoxDecoration(color: step >= i ? p.btn : p.faint, borderRadius: AppRadius.r),
                ),
                if (labels != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    labels![i - 1],
                    style: ts(13, w: step >= i ? FontWeight.w600 : FontWeight.w500, c: step >= i ? p.text : p.text2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Points de pagination (actif : 24 px, accent-700).
class Dots extends StatelessWidget {
  const Dots({super.key, required this.count, required this.index, this.onPick, this.activeWidth = 24});
  final int count;
  final int index;
  final ValueChanged<int>? onPick;
  final double activeWidth;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Tap(
              onTap: onPick == null ? null : () => onPick!(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: kEase,
                width: i == index ? activeWidth : 8,
                height: 8,
                decoration: BoxDecoration(color: i == index ? p.btn : p.faint, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Interrupteur du design system (piste accent-700 quand actif).
class SwitchX extends StatelessWidget {
  const SwitchX({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      toggled: value,
      child: Tap(
        onTap: () => onChanged(!value),
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: value ? p.btn : p.faint, borderRadius: BorderRadius.circular(14)),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: kEase,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: value ? p.onBtn : (p.dark ? AppColors.n300 : AppColors.n700), shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

/// Emplacement photo vide (à remplacer par une vraie image, ClipRRect rayon 2).
class ImageSlot extends StatelessWidget {
  const ImageSlot(this.label, {super.key, this.height, this.width, this.circle = false, this.icon = PI.image, this.compact = false});
  final String label;
  final double? height, width;
  final bool circle;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: p.chip, borderRadius: circle ? null : AppRadius.r, shape: circle ? BoxShape.circle : BoxShape.rectangle),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _Hatch(p.dark ? AppColors.n700 : AppColors.n300),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: compact || circle
                ? Ph(icon, size: 22, color: p.text2)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Ph(icon, size: 26, color: p.text2),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ts(12, w: FontWeight.w500, c: p.text2),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Hatch extends CustomPainter {
  _Hatch(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_Hatch old) => old.color != color;
}

/// Ligne d'information : icône + libellé + valeur.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value, this.trailing, this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Ph(icon, color: p.text2),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ts(13, w: FontWeight.w500, c: p.text2),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: ts(15, w: FontWeight.w600, c: p.text),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
    return onTap == null ? row : Tap(onTap: onTap, child: row);
  }
}

/// Paire libellé / valeur (récapitulatifs).
class KV extends StatelessWidget {
  const KV(this.label, this.value, {super.key, this.valueColor, this.bold = true});
  final String label, value;
  final Color? valueColor;
  final bool bold;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ts(14, w: FontWeight.w500, c: p.text2),
            ),
          ),
          Text(
            value,
            style: ts(15, w: bold ? FontWeight.w700 : FontWeight.w500, c: valueColor ?? p.text),
          ),
        ],
      ),
    );
  }
}

/// Séparateur interne 1 px neutral-200.
class Hr extends StatelessWidget {
  const Hr({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: EdgeInsets.only(left: indent),
    color: context.pal.divider,
  );
}

/// Colonne avec séparateurs internes.
class Separated extends StatelessWidget {
  const Separated({super.key, required this.children, this.indent = 0});
  final List<Widget> children;
  final double indent;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) Hr(indent: indent), children[i]],
    ],
  );
}

/// Contraint la largeur et centre le contenu (écrans larges).
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.max = 640});
  final Widget child;
  final double max;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: max),
      child: child,
    ),
  );
}

/// Affiche un message de confirmation (SnackBar n900, icône check).
void showToast(BuildContext context, String msg, {IconData icon = PI.checkCircle}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      duration: const Duration(milliseconds: 3500),
      width: context.isWide ? 480 : null,
      content: Row(
        children: [
          Ph(icon, color: AppColors.a300, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: ts(14, w: FontWeight.w500, c: AppColors.n100, h: 1.4),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pied de page fixe portant le bouton d'action principal (mobile).
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    // viewInsets = hauteur du clavier : la barre (bouton, champ du chat) remonte au-dessus de lui.
    final bottom = MediaQuery.paddingOf(context).bottom + MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      decoration: BoxDecoration(
        color: p.card,
        boxShadow: [BoxShadow(color: p.line, offset: const Offset(0, -1))],
      ),
      child: child,
    );
  }
}

/// Barre supérieure mobile d'un écran de détail.
class DetailBar extends StatelessWidget {
  const DetailBar({super.key, required this.title, this.onBack, this.backIcon = PI.arrowLeft, this.actions = const [], this.trailingText});
  final String title;
  final VoidCallback? onBack;
  final IconData backIcon;
  final List<Widget> actions;
  final String? trailingText;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          if (onBack != null) IconBtn(backIcon, onPressed: onBack, tooltip: 'Retour'),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: ts(20, w: FontWeight.w600, c: p.text),
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText!,
              style: ts(13, w: FontWeight.w600, c: p.text2),
            ),
          ...actions,
        ],
      ),
    );
  }
}

/// Fil d'Ariane des écrans « ordinateur » (← Retour / Titre).
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.backLabel, required this.onBack, this.current});
  final String backLabel;
  final VoidCallback onBack;
  final String? current;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        LinkButton(backLabel, icon: PI.arrowLeft, onPressed: onBack, color: p.text2),
        if (current != null) ...[
          Text('/', style: ts(14, c: p.faint)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              current!,
              overflow: TextOverflow.ellipsis,
              style: ts(14, w: FontWeight.w600, c: p.text),
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo MaCité (image + nom).
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 36, this.showName = true, this.fontSize = 20, this.color});
  final double size;
  final bool showName;
  final double fontSize;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/images/logo-mark.png', width: size, height: size, fit: BoxFit.contain),
      if (showName) ...[
        const SizedBox(width: 10),
        Text(
          'MaCité',
          style: ts(fontSize, w: FontWeight.w700, c: color ?? context.pal.text),
        ),
      ],
    ],
  );
}
