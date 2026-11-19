/// Planning du mois : une ligne par personne, une colonne par jour.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models.dart';
import '../planning.dart';
import '../theme.dart';
import 'widgets.dart';

const double _headerH = 58, _rowH = 46, _footerH = 40, _weekGap = 8;

class PlanningGrid extends StatefulWidget {
  const PlanningGrid({super.key, required this.state});

  final AppState state;

  @override
  State<PlanningGrid> createState() => _PlanningGridState();
}

class _PlanningGridState extends State<PlanningGrid> {
  final _scroll = ScrollController();
  String? _centeredFor;
  PointerDeviceKind _lastKind = PointerDeviceKind.touch;
  String? _anchor;
  Set<String> _base = {};
  bool _adding = true;

  AppState get s => widget.state;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final today = s.today;
    final days = kDates.where((d) => d.startsWith(s.month)).toList();
    final me = s.meIndex;
    final rows = [
      for (var i = 0; i < kPeople.length; i++)
        if (days.any((d) => baseCode(d, i) != '-')) i,
    ]..sort((a, b) => (b == me ? 1 : 0) - (a == me ? 1 : 0));
    final weekStart = <bool>[];
    for (var k = 0; k < days.length; k++) {
      weekStart.add(k > 0 && parseIso(days[k]).weekday <= parseIso(days[k - 1]).weekday);
    }

    return LayoutBuilder(builder: (context, c) {
      final nameW = c.maxWidth < 640 ? 60.0 : 180.0;
      final viewport = c.maxWidth - nameW;
      final gaps = weekStart.where((w) => w).length * _weekGap;
      final cellW = days.isEmpty ? 44.0 : ((viewport - gaps) / days.length).clamp(40.0, 54.0);
      final xs = <double>[];
      var x = 0.0;
      for (var k = 0; k < days.length; k++) {
        if (weekStart[k]) x += _weekGap;
        xs.add(x);
        x += cellW;
      }
      final contentW = x;
      _maybeCenter(days, xs, cellW, viewport, today);

      Widget dayStrip(Widget Function(int k) slot, {double height = _rowH}) => SizedBox(
            height: height,
            child: Row(children: [
              for (var k = 0; k < days.length; k++) ...[
                if (weekStart[k]) const SizedBox(width: _weekGap),
                Container(
                  width: cellW,
                  height: height,
                  color: days[k] == today ? p.todayCol : null,
                  child: slot(k),
                ),
              ],
            ]),
          );

      final names = Column(children: [
        SizedBox(
          height: _headerH,
          child: Align(
            alignment: nameW < 100 ? Alignment.center : const Alignment(-.7, 0),
            child: const Eyebrow('Équipe', color: Palette.yellow),
          ),
        ),
        for (final i in rows) _NameCell(person: kPeople[i], mine: i == me, compact: nameW < 100),
        Container(
          height: _footerH,
          decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
          alignment: nameW < 100 ? Alignment.center : const Alignment(-.7, 0),
          child: Text(nameW < 100 ? 'Bur.' : 'Au bureau', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted)),
        ),
      ]);

      final header = dayStrip(height: _headerH, (k) {
        final d = parseIso(days[k]);
        final isToday = days[k] == today;
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(DateFormat('EEEEE').format(d).toUpperCase(), style: TextStyle(fontSize: 11.5, color: p.muted)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: isToday
                ? BoxDecoration(
                    color: Palette.yellow,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [BoxShadow(color: Palette.yellow.withValues(alpha: .6), blurRadius: 10)],
                  )
                : null,
            child: Text('${d.day}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isToday ? Palette.night : p.ink)),
          ),
        ]);
      });

      Widget personRow(int i) {
        final mine = i == me;
        final strip = dayStrip((k) => _cell(days[k], i, mine));
        final row = Container(color: mine ? p.meRow : null, child: strip);
        if (!mine) return row;
        return Listener(
          onPointerDown: (e) => _down(e, days, xs, cellW),
          onPointerMove: (e) => _move(e, days, xs, cellW),
          onPointerUp: (_) => _anchor = null,
          child: row,
        );
      }

      final footer = Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
        child: dayStrip(height: _footerH - 1, (k) {
          var work = 0, total = 0, ferie = false;
          for (final i in rows) {
            if (baseCode(days[k], i) == '-') continue;
            total++;
            final code = effectiveCode(days[k], i, s.overrides);
            if (code == 'F') ferie = true;
            if (kAtWork.contains(code)) work++;
          }
          final full = !ferie && work == total && total > 0;
          return Center(
            child: full
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(color: Palette.accent, borderRadius: BorderRadius.circular(6)),
                    child: Text('$work', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Palette.accentInk)),
                  )
                : Text(ferie ? '–' : '$work',
                    style: TextStyle(fontSize: 12, color: p.muted.withValues(alpha: ferie || work == 0 ? .5 : 1))),
          );
        }),
      );

      return Panel(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: nameW,
              decoration: BoxDecoration(border: Border(right: BorderSide(color: p.line))),
              child: names,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentW,
                  child: Column(children: [header, for (final i in rows) personRow(i), footer]),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }

  /// Centre la grille sur aujourd'hui à l'ouverture et à chaque changement de mois.
  void _maybeCenter(List<String> days, List<double> xs, double cellW, double viewport, String today) {
    final token = '${s.month}|${s.recenter}';
    if (_centeredFor == token) return;
    _centeredFor = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final k = days.indexOf(today);
      final max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo(k < 0 ? 0 : (xs[k] - (viewport - cellW) / 2).clamp(0.0, max));
    });
  }

  int? _indexAt(double dx, List<double> xs, double cellW) {
    for (var k = 0; k < xs.length; k++) {
      if (dx >= xs[k] && dx < xs[k] + cellW) return k;
    }
    return null;
  }

  void _down(PointerDownEvent e, List<String> days, List<double> xs, double cellW) {
    _lastKind = e.kind;
    if (e.kind != PointerDeviceKind.mouse || e.buttons != kPrimaryMouseButton) return;
    final k = _indexAt(e.localPosition.dx, xs, cellW);
    if (k == null || !s.canSelect(days[k])) return;
    final d = days[k];
    final keys = HardwareKeyboard.instance;
    if (keys.isShiftPressed && s.selection.isNotEmpty) {
      final all = [...s.selection, d]..sort();
      s.setSelection([...s.selection, ...kDates.where((x) => x.compareTo(all.first) >= 0 && x.compareTo(all.last) <= 0)]);
      return;
    }
    final multi = keys.isControlPressed || keys.isMetaPressed;
    _anchor = d;
    _base = multi ? {...s.selection} : {};
    _adding = !(s.selection.contains(d) && (multi || s.selection.length == 1));
    _dragTo(d);
  }

  void _move(PointerMoveEvent e, List<String> days, List<double> xs, double cellW) {
    if (_anchor == null) return;
    final k = _indexAt(e.localPosition.dx, xs, cellW);
    if (k != null) _dragTo(days[k]);
  }

  void _dragTo(String d) {
    final a = _anchor!.compareTo(d) <= 0 ? _anchor! : d;
    final b = _anchor!.compareTo(d) <= 0 ? d : _anchor!;
    final range = kDates.where((x) => x.compareTo(a) >= 0 && x.compareTo(b) <= 0 && s.canSelect(x));
    final next = {..._base};
    _adding ? next.addAll(range) : next.removeAll(range);
    s.setSelection(next);
  }

  Widget _cell(String date, int i, bool mine) {
    final p = context.pal;
    final code = effectiveCode(date, i, s.overrides);
    final base = baseCode(date, i);
    final o = s.overrides[absenceId(date, kPeople[i].name)];
    final posed = o != null && !kLocked.contains(base);
    final editable = mine && !kLocked.contains(base);
    final selected = editable && s.selection.contains(date);
    final label = '${kPeople[i].name}, ${DateFormat('EEE d MMM').format(parseIso(date))} : '
        '${kStatusLabel[code] ?? code}${o != null && o.note.isNotEmpty ? ' · ${o.note}' : ''}';

    Widget box = Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
      decoration: BoxDecoration(
        color: code == 'F' ? null : p.status(code),
        borderRadius: BorderRadius.circular(7),
        border: selected
            ? Border.all(color: p.sel, width: 3)
            : (code == 'F' ? Border.all(color: p.fer) : null),
        boxShadow: code == 'K' ? [BoxShadow(color: Palette.pink.withValues(alpha: .55), blurRadius: 12)] : null,
      ),
      child: Stack(children: [
        if (code == 'F') Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: CustomPaint(painter: HatchPainter(p.fer)))),
        if (code == 'X' || code == 'C')
          Positioned(left: 8, right: 8, bottom: 6, child: Container(height: 3, decoration: BoxDecoration(color: Colors.black.withValues(alpha: .35), borderRadius: BorderRadius.circular(2)))),
        if (posed)
          Positioned(right: 4, top: 4, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Palette.night, shape: BoxShape.circle))),
      ]),
    );
    box = Tooltip(message: label, child: box);
    if (!editable) return Semantics(label: label, child: box);
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // À la souris, le clic est déjà géré par le glisser (Listener).
            if (_lastKind != PointerDeviceKind.mouse) s.toggle(date);
          },
          child: box,
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  const _NameCell({required this.person, required this.mine, required this.compact});

  final Person person;
  final bool mine, compact;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      height: _rowH,
      padding: EdgeInsets.only(left: compact ? 0 : 16, right: compact ? 0 : 10),
      decoration: BoxDecoration(
        color: mine ? p.meRow : null,
        border: mine ? const Border(left: BorderSide(color: Palette.accent, width: 3)) : null,
      ),
      child: Row(mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
        Avatar(person, size: 28),
        if (!compact) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mine ? '${person.name} (toi)' : person.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: p.ink, height: 1.15)),
              Text(person.school, style: TextStyle(fontSize: 11.5, color: p.muted)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// Légende des couleurs.
class Legend extends StatelessWidget {
  const Legend({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget item(Widget swatch, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          swatch,
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, color: p.muted)),
        ]);
    Widget sw(Color c, {Widget? child, BoxBorder? border}) => Container(
          width: 14,
          height: 14,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4), border: border),
          child: child,
        );
    return Wrap(spacing: 16, runSpacing: 6, children: [
      item(sw(p.ent), 'Entreprise'),
      item(sw(p.eco), 'École'),
      item(sw(p.eco, child: Align(alignment: Alignment.bottomCenter, child: Container(margin: const EdgeInsets.fromLTRB(3, 0, 3, 2), height: 2, color: Colors.black38))), 'Examen / cours'),
      item(sw(p.cge), 'Congé'),
      item(sw(p.tt), 'Télétravail'),
      item(sw(Colors.transparent, border: Border.all(color: p.fer), child: CustomPaint(painter: HatchPainter(p.fer))), 'Férié'),
      item(sw(p.ent, child: Align(alignment: const Alignment(.6, -.6), child: Container(width: 4, height: 4, decoration: BoxDecoration(color: p.ink.withValues(alpha: .6), shape: BoxShape.circle)))), 'Modifié dans l\'app'),
    ]);
  }
}
