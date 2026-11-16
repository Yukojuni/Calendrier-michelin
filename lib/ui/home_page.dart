/// Page principale.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models.dart';
import '../planning.dart';
import '../theme.dart';
import 'overview.dart';
import 'planning_grid.dart';
import 'quentin_card.dart';
import 'widgets.dart';

String fmtDay(String iso) => DateFormat('EEE d MMM').format(parseIso(iso)).replaceAll('.', '');

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.state});

  final AppState state;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _quentin = QuentinInfo.compute();

  AppState get s => widget.state;

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(milliseconds: 2600)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final p = context.pal;
        return Scaffold(
          appBar: PreferredSize(preferredSize: const Size.fromHeight(60), child: _TopBar(state: s)),
          body: Stack(children: [
            SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                    child: LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth >= 860;
                      Widget pair(Widget a, Widget b, {int fa = 1, int fb = 1, bool equal = false}) => wide
                          ? (equal ? IntrinsicHeight.new : (({required Widget child}) => child))(
                              child: Row(crossAxisAlignment: equal ? CrossAxisAlignment.stretch : CrossAxisAlignment.start, children: [
                                Expanded(flex: fa, child: a),
                                const SizedBox(width: 16),
                                Expanded(flex: fb, child: b),
                              ]),
                            )
                          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 16), b]);
                      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        pair(TodayPanel(state: s), MePanel(state: s), fa: 13, fb: 10, equal: true),
                        if (_quentin != null) ...[
                          const SizedBox(height: 16),
                          QuentinCard(state: s, info: _quentin),
                        ],
                        const SizedBox(height: 26),
                        _MonthHeader(state: s),
                        const SizedBox(height: 6),
                        Text(
                          s.meIndex < 0
                              ? 'Choisis ton nom en haut à droite pour pouvoir poser des absences.'
                              : 'Touche tes jours (ou glisse à la souris pour en prendre plusieurs), puis choisis Congé ou Télétravail en bas.',
                          style: TextStyle(color: p.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        PlanningGrid(state: s),
                        const SizedBox(height: 12),
                        const Legend(),
                        const SizedBox(height: 24),
                        pair(_MyAbsences(state: s, onToast: _toast), _PeriodForm(state: s, onToast: _toast)),
                        const SizedBox(height: 24),
                        Text("Planning d'origine importé du document partagé de l'équipe (nov. 2026 → août 2028).",
                            style: TextStyle(color: p.muted, fontSize: 12)),
                      ]);
                    }),
                  ),
                ),
              ),
            ),
            if (s.selection.isNotEmpty && s.meIndex >= 0)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
                child: Center(child: _ActionBar(state: s, onToast: _toast)),
              ),
          ]),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final i = state.meIndex;
    final narrow = MediaQuery.of(context).size.width < 560;
    return Material(
      color: p.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  CustomPaint(size: Size.square(narrow ? 30 : 34), painter: _LogoPainter()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Le Guide des ', style: display(narrow ? 17 : 19, weight: FontWeight.w800, color: p.ink)),
                        Container(
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.accent, width: 4))),
                          child: Text('Congés', style: display(narrow ? 17 : 19, weight: FontWeight.w800, color: p.ink)),
                        ),
                      ]),
                    ),
                  ),
                  if (!narrow) ...[
                    Icon(Icons.circle, size: 8, color: state.store.isShared ? p.cge : const Color(0xFFE0B400)),
                    const SizedBox(width: 6),
                    Text(state.store.description, style: TextStyle(fontSize: 12, color: p.muted)),
                    const SizedBox(width: 12),
                  ],
                  PopupMenuButton<String>(
                    tooltip: 'Choisir qui tu es',
                    onSelected: state.setMe,
                    position: PopupMenuPosition.under,
                    itemBuilder: (_) => [
                      for (final person in kPeople)
                        PopupMenuItem(
                          value: person.name,
                          child: Row(children: [
                            Avatar(person),
                            const SizedBox(width: 10),
                            Text(person.name, style: TextStyle(fontWeight: person.name == state.me ? FontWeight.w700 : FontWeight.w500)),
                            const Spacer(),
                            Text(person.school, style: TextStyle(fontSize: 12, color: p.muted)),
                          ]),
                        ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                      decoration: BoxDecoration(border: Border.all(color: p.line), borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Avatar(i < 0 ? null : kPeople[i]),
                        const SizedBox(width: 8),
                        Text(i < 0 ? 'Qui es-tu ?' : kPeople[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero), r = size.shortestSide / 2;
    canvas.drawCircle(c, r * .9, Paint()..color = Palette.navy);
    final stud = Paint()..color = const Color(0xFF33416A);
    for (final o in [Offset(0, -r * .78), Offset(0, r * .78), Offset(-r * .78, 0), Offset(r * .78, 0)]) {
      canvas.drawCircle(c + o, r * .1, stud);
    }
    canvas.drawCircle(c, r * .55, Paint()..color = Palette.accent);
    final ink = Paint()..color = Palette.navy;
    canvas.drawCircle(c.translate(-r * .18, -r * .08), r * .085, ink);
    canvas.drawCircle(c.translate(r * .18, -r * .08), r * .085, ink);
    final smile = Path()
      ..moveTo(c.dx - r * .22, c.dy + r * .13)
      ..quadraticBezierTo(c.dx, c.dy + r * .36, c.dx + r * .22, c.dy + r * .13);
    canvas.drawPath(smile, Paint()
      ..color = Palette.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .09
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final k = kMonths.indexOf(state.month);
    final title = capitalize(DateFormat('MMMM y').format(parseIso('${state.month}-15')));
    final side = OutlinedButton.styleFrom(
      side: BorderSide(color: p.line),
      backgroundColor: p.surface,
      foregroundColor: p.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    final narrow = MediaQuery.of(context).size.width < 480;
    final heading = Text(title, style: display(narrow ? 24 : 26, color: p.ink), maxLines: 1, overflow: TextOverflow.ellipsis);
    final controls = Row(mainAxisSize: MainAxisSize.min, children: [
      OutlinedButton(style: side, onPressed: state.goToday, child: const Text("Aujourd'hui", style: TextStyle(fontWeight: FontWeight.w600))),
      const SizedBox(width: 8),
      IconButton.outlined(
        style: side,
        tooltip: 'Mois précédent',
        onPressed: k > 0 ? () => state.shiftMonth(-1) : null,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      const SizedBox(width: 4),
      IconButton.outlined(
        style: side,
        tooltip: 'Mois suivant',
        onPressed: k < kMonths.length - 1 ? () => state.shiftMonth(1) : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ]);
    if (narrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading, const SizedBox(height: 8), controls]);
    }
    return Row(children: [Expanded(child: heading), controls]);
  }
}

class _ActionBar extends StatefulWidget {
  const _ActionBar({required this.state, required this.onToast});

  final AppState state;
  final void Function(String) onToast;

  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _commit(AbsenceKind? kind) async {
    final s = widget.state;
    final sel = s.selection.toList()..sort();
    setState(() => _busy = true);
    try {
      final n = await s.apply(sel, kind, note: _note.text);
      s.clearSelection();
      widget.onToast(switch (kind) {
        AbsenceKind.conge => '$n jour${n > 1 ? 's' : ''} de congé posé${n > 1 ? 's' : ''}. Bonne route !',
        null => "Planning d'origine rétabli",
        _ => '${kind.label} enregistré',
      });
    } catch (_) {
      widget.onToast("L'enregistrement a échoué, réessaie dans un instant");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFFF4F6FA) : Palette.navy;
    final fg = dark ? Palette.navy : Colors.white;
    final soft = fg.withValues(alpha: .1);
    final sel = widget.state.selection.toList()..sort();
    final n = sel.length;
    final narrow = MediaQuery.of(context).size.width < 600;

    Widget btn(String label, AbsenceKind? kind, {Color? dot, bool primary = false}) => FilledButton(
          onPressed: _busy ? null : () => _commit(kind),
          style: FilledButton.styleFrom(
            backgroundColor: primary ? Palette.accent : soft,
            foregroundColor: primary ? Palette.accentInk : fg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (dot != null) ...[StatusDot(dot, size: 8), const SizedBox(width: 6)],
            Text(label),
          ]),
        );

    final p = context.pal;
    final count = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('$n jour${n > 1 ? 's' : ''} sélectionné${n > 1 ? 's' : ''}', style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
      Text(n > 1 ? '${fmtDay(sel.first)} → ${fmtDay(sel.last)}' : fmtDay(sel.first),
          style: TextStyle(color: fg.withValues(alpha: .7), fontSize: 12)),
    ]);
    final note = SizedBox(
      width: narrow ? double.infinity : 180,
      child: TextField(
        controller: _note,
        maxLength: 80,
        style: TextStyle(color: fg, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          counterText: '',
          hintText: 'Petit mot (facultatif)',
          hintStyle: TextStyle(color: fg.withValues(alpha: .55)),
          filled: true,
          fillColor: soft,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
    final actions = Wrap(spacing: 6, runSpacing: 6, children: [
      btn('Poser en congé', AbsenceKind.conge, primary: true),
      btn('Télétravail', AbsenceKind.tt, dot: p.tt),
      btn('Bureau', AbsenceKind.bureau, dot: p.ent),
      btn('Rétablir', null),
    ]);
    final close = IconButton(
      tooltip: 'Annuler la sélection',
      onPressed: widget.state.clearSelection,
      icon: Icon(Icons.close_rounded, color: fg.withValues(alpha: .7)),
    );

    return Material(
      color: bg,
      elevation: 12,
      shadowColor: Colors.black54,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: narrow
            ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: count), close]),
                const SizedBox(height: 8),
                note,
                const SizedBox(height: 8),
                actions,
              ])
            : Row(mainAxisSize: MainAxisSize.min, children: [
                count,
                const SizedBox(width: 12),
                note,
                const SizedBox(width: 10),
                actions,
                close,
              ]),
      ),
    );
  }
}

class _MyAbsences extends StatelessWidget {
  const _MyAbsences({required this.state, required this.onToast});

  final AppState state;
  final void Function(String) onToast;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final groups = groupAbsences(state.myAbsences);
    Widget empty(String t) => Text(t, style: TextStyle(color: p.muted));
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Mes absences', style: display(17, color: p.ink)),
        const SizedBox(height: 4),
        Text("Congés et télétravail posés dans l'app.", style: TextStyle(color: p.muted, fontSize: 13)),
        const SizedBox(height: 14),
        if (state.meIndex < 0)
          empty('Choisis ton nom pour voir tes absences.')
        else if (groups.isEmpty)
          empty("Rien de posé pour l'instant. Sélectionne des jours dans ta ligne du planning.")
        else
          for (var g = 0; g < groups.length; g++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(border: g == 0 ? null : Border(top: BorderSide(color: p.line))),
              child: Row(children: [
                StatusDot(p.status(groups[g].first.kind.code), round: true),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      groups[g].length > 1
                          ? '${fmtDay(groups[g].first.date)} → ${fmtDay(groups[g].last.date)}'
                          : fmtDay(groups[g].first.date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${groups[g].first.kind.label} · ${groups[g].length} jour${groups[g].length > 1 ? 's' : ''}'
                      '${groups[g].first.note.isNotEmpty ? ' · ${groups[g].first.note}' : ''}',
                      style: TextStyle(color: p.muted, fontSize: 12.5),
                    ),
                  ]),
                ),
                TextButton(onPressed: () => state.goToMonth(groups[g].first.date.substring(0, 7)), child: const Text('Voir')),
                TextButton(
                  onPressed: () async {
                    await state.removeAll(groups[g]);
                    onToast('Absence retirée');
                  },
                  child: const Text('Retirer'),
                ),
              ]),
            ),
      ]),
    );
  }
}

class _SegLabel extends StatelessWidget {
  const _SegLabel(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        StatusDot(color, size: 9),
        const SizedBox(width: 6),
        Text(text, softWrap: false),
      ]);
}

class _PeriodForm extends StatefulWidget {
  const _PeriodForm({required this.state, required this.onToast});

  final AppState state;
  final void Function(String) onToast;

  @override
  State<_PeriodForm> createState() => _PeriodFormState();
}

class _PeriodFormState extends State<_PeriodForm> {
  AbsenceKind _kind = AbsenceKind.conge;
  DateTimeRange? _range;
  final _note = TextEditingController();
  String _msg = '';
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final first = parseIso(kDates.first), last = parseIso(kDates.last);
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: _range,
      currentDate: now,
      helpText: 'Choisis la période',
      saveText: 'Valider',
    );
    if (r != null) setState(() => _range = r);
  }

  Future<void> _submit() async {
    final s = widget.state;
    if (s.meIndex < 0) return setState(() => _msg = "Choisis d'abord ton nom en haut à droite.");
    final r = _range;
    if (r == null) return setState(() => _msg = 'Choisis une période.');
    final a = isoDate(r.start), b = isoDate(r.end);
    final targets = kDates.where((d) => d.compareTo(a) >= 0 && d.compareTo(b) <= 0 && s.canSelect(d)).toList();
    if (targets.isEmpty) return setState(() => _msg = 'Aucun jour en entreprise sur cette période.');
    setState(() {
      _busy = true;
      _msg = 'Enregistrement…';
    });
    try {
      final n = await s.apply(targets, _kind, note: _note.text);
      _note.clear();
      setState(() => _msg = '$n jour${n > 1 ? 's' : ''} posé${n > 1 ? 's' : ''}.');
      s.goToMonth(targets.first.substring(0, 7));
    } catch (_) {
      setState(() => _msg = "L'enregistrement a échoué, réessaie dans un instant.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final f = DateFormat('d MMM y');
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Poser une longue période', style: display(17, color: p.ink)),
        const SizedBox(height: 4),
        Text("Pratique quand ça déborde sur plusieurs mois. L'école, les fériés et les week-ends sont ignorés.",
            style: TextStyle(color: p.muted, fontSize: 13)),
        const SizedBox(height: 14),
        SegmentedButton<AbsenceKind>(
          segments: [
            ButtonSegment(value: AbsenceKind.conge, label: _SegLabel('Congé', p.cge)),
            ButtonSegment(value: AbsenceKind.tt, label: _SegLabel('Télétravail', p.tt)),
          ],
          selected: {_kind},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _kind = v.first),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickRange,
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(_range == null ? 'Choisir les dates' : 'Du ${f.format(_range!.start)} au ${f.format(_range!.end)}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: p.ink,
            side: BorderSide(color: p.line),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: 'Petit mot (facultatif)',
            hintText: 'Ski, mariage, déménagement…',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: p.ink,
            foregroundColor: p.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Poser la période', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        if (_msg.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_msg, style: TextStyle(color: p.muted, fontSize: 13)),
        ],
      ]),
    );
  }
}
