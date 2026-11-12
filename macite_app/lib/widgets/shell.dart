import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'ui.dart';

class NavItem {
  const NavItem(this.key, this.icon, this.label, {this.count});
  final String key;
  final IconData icon;
  final String label;
  final int? count;
}

/// Navigation mobile : 80 px, indicateur 64×32 accent-200, libellé actif 600.
class MobileNavBar extends StatelessWidget {
  const MobileNavBar({super.key, required this.items, required this.active, required this.onTap});
  final List<NavItem> items;
  final String active;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: 80 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(top: 12, bottom: MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: p.card,
        boxShadow: [BoxShadow(color: p.line, offset: const Offset(0, -1))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final it in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: it.key == active,
                label: it.label,
                child: Tap(
                  onTap: () => onTap(it.key),
                  scale: 0.95,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: kEase,
                        width: 64,
                        height: 32,
                        decoration: BoxDecoration(color: it.key == active ? p.navIndicator : Colors.transparent, borderRadius: AppRadius.r),
                        alignment: Alignment.center,
                        child: Ph(it.icon, color: it.key == active ? p.text : p.text2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        it.label,
                        overflow: TextOverflow.ellipsis,
                        style: ts(12, w: it.key == active ? FontWeight.w600 : FontWeight.w500, c: it.key == active ? p.text : p.text2),
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

/// Barre latérale « ordinateur » (260 px).
class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.items, required this.active, required this.onTap, required this.footerTitle, required this.footerText});
  final List<NavItem> items;
  final String active;
  final ValueChanged<String> onTap;
  final String footerTitle, footerText;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: 260,
      color: p.card,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.only(left: 8, bottom: 24), child: Logo()),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SideItem(item: it, active: it.key == active, onTap: () => onTap(it.key)),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.bg, borderRadius: AppRadius.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  footerTitle,
                  style: ts(14, w: FontWeight.w700, c: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  footerText,
                  style: ts(13, w: FontWeight.w500, c: p.text2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatefulWidget {
  const _SideItem({required this.item, required this.active, required this.onTap});
  final NavItem item;
  final bool active;
  final VoidCallback onTap;
  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final a = widget.active;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Tap(
        onTap: widget.onTap,
        scale: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: a ? p.a100 : (_h ? p.bg : Colors.transparent), borderRadius: AppRadius.r),
          child: Row(
            children: [
              Ph(widget.item.icon, size: 22, color: a ? p.a700 : p.text2),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.item.label,
                  overflow: TextOverflow.ellipsis,
                  style: ts(15, w: a ? FontWeight.w600 : FontWeight.w500, c: a ? p.a800 : p.strong),
                ),
              ),
              if ((widget.item.count ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: p.m200, borderRadius: AppRadius.r),
                  child: Text(
                    '${widget.item.count}',
                    style: ts(12, w: FontWeight.w700, c: p.m700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête « ordinateur » : recherche, notifications, utilisateur.
class DesktopHeader extends StatelessWidget {
  const DesktopHeader({
    super.key,
    required this.initials,
    required this.name,
    this.searchHint = 'Rechercher…',
    this.onSearch,
    this.searchController,
    this.onBell,
    this.bellDot = true,
    this.avatarTone = Tone.strong,
  });
  final String initials, name, searchHint;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;
  final VoidCallback? onBell;
  final bool bellDot;
  final Tone avatarTone;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: Row(
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: p.card, borderRadius: AppRadius.r),
                child: Row(
                  children: [
                    Ph(PI.magnifyingGlass, size: 20, color: p.text2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: onSearch == null
                          ? Text(searchHint, style: ts(15, c: p.text2))
                          : TextField(
                              controller: searchController,
                              onChanged: onSearch,
                              style: ts(15, c: p.text),
                              decoration: InputDecoration.collapsed(
                                hintText: searchHint,
                                hintStyle: ts(15, c: p.text2),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Spacer(),
          IconBtn(PI.bell, onPressed: onBell, dot: bellDot, tooltip: 'Notifications'),
          const SizedBox(width: 12),
          Avatar(initials, size: 36, tone: avatarTone),
          const SizedBox(width: 10),
          Text(
            name,
            style: ts(15, w: FontWeight.w600, c: p.text),
          ),
          const SizedBox(width: 4),
          Ph(PI.caretDown, size: 18, color: p.text2),
        ],
      ),
    );
  }
}
