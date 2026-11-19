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
import 'vice_hero.dart';
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
  final _gridKey = GlobalKey();

  void _goToPlanning() {
    s.goToday();
    final ctx = _gridKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, alignment: .1);
    }
    if (s.meIndex < 0) _toast("Choisis d'abord qui tu es, en haut à droite");
  }

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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _TopBar(state: s),
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final wide = c.maxWidth >= 860;
                          Widget pair(Widget a, Widget b, {int fa = 1, int fb = 1, bool equal = false}) => wide
                              ? (equal ? IntrinsicHeight.new : (({required Widget child}) => child))(
                                  child: Row(
                                    crossAxisAlignment: equal ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: fa, child: a),
                                      const SizedBox(width: 16),
                                      Expanded(flex: fb, child: b),
                                    ],
                                  ),
                                )
                              : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [a, const SizedBox(height: 16), b]);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TodayHero(state: s, onMission: _goToPlanning),
                              const SizedBox(height: 20),
                              if (_quentin != null) pair(QuentinCard(state: s, info: _quentin), MePanel(state: s), fa: 16, fb: 9) else MePanel(state: s),
                              const SizedBox(height: 26),
                              _MonthHeader(state: s),
                              const SizedBox(height: 6),
                              Text(
                                s.meIndex < 0 ? 'Choisis ton nom en haut à droite pour pouvoir poser des absences.' : 'Touche n\'importe lequel de tes jours (ou glisse à la souris pour en prendre plusieurs), puis choisis son statut en bas.',
                                style: TextStyle(color: p.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 12),
                              PlanningGrid(key: _gridKey, state: s),
                              const SizedBox(height: 12),
                              const Legend(),
                              const SizedBox(height: 24),
                              pair(_MyAbsences(state: s, onToast: _toast), _PeriodForm(state: s, onToast: _toast)),
                              const SizedBox(height: 24),
                              Text(
                                "Planning d'origine importé du document partagé de l'équipe (nov. 2026 → août 2028).",
                                style: TextStyle(color: p.muted, fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (s.selection.isNotEmpty && s.meIndex >= 0)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 16 + MediaQuery.of(context).padding.bottom,
                  child: Center(
                    child: _ActionBar(state: s, onToast: _toast),
                  ),
                ),
            ],
          ),
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
      color: Palette.nightDeep,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.line)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CustomPaint(size: Size.square(narrow ? 30 : 34), painter: _LogoPainter()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'GUIDE DES ',
                                style: display(narrow ? 19 : 22, color: p.ink),
                              ),
                              TextSpan(
                                text: 'CONGÉS',
                                style: display(narrow ? 19 : 22, color: Palette.pink),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!narrow) ...[
                      Icon(Icons.circle, size: 8, color: state.offline ? const Color(0xFFE5484D) : (state.store.isShared ? Palette.cyan : Palette.yellow)),
                      const SizedBox(width: 6),
                      Text(state.offline ? 'Connexion impossible à la base' : state.store.description, style: TextStyle(fontSize: 12, color: p.muted)),
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
                            child: Row(
                              children: [
                                Avatar(person),
                                const SizedBox(width: 10),
                                Text(person.name, style: TextStyle(fontWeight: person.name == state.me ? FontWeight.w700 : FontWeight.w500)),
                                const Spacer(),
                                Text(person.school, style: TextStyle(fontSize: 12, color: p.muted)),
                              ],
                            ),
                          ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: p.line),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Avatar(i < 0 ? null : kPeople[i]),
                            const SizedBox(width: 8),
                            Text(i < 0 ? 'Qui es-tu ?' : kPeople[i].name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
    canvas.drawCircle(c, r * .9, Paint()..color = Palette.plum);
    canvas.drawCircle(
      c,
      r * .9,
      Paint()
        ..color = Palette.pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .1,
    );
    final stud = Paint()..color = const Color(0xFF5B3A8C);
    for (final o in [Offset(0, -r * .78), Offset(0, r * .78), Offset(-r * .78, 0), Offset(r * .78, 0)]) {
      canvas.drawCircle(c + o, r * .1, stud);
    }
    canvas.drawCircle(c, r * .55, Paint()..color = Palette.yellow);
    final ink = Paint()..color = Palette.navy;
    canvas.drawCircle(c.translate(-r * .18, -r * .08), r * .085, ink);
    canvas.drawCircle(c.translate(r * .18, -r * .08), r * .085, ink);
    final smile = Path()
      ..moveTo(c.dx - r * .22, c.dy + r * .13)
      ..quadraticBezierTo(c.dx, c.dy + r * .36, c.dx + r * .22, c.dy + r * .13);
    canvas.drawPath(
      smile,
      Paint()
        ..color = Palette.navy
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .09
        ..strokeCap = StrokeCap.round,
    );
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
    final heading = Text(
      title.toUpperCase(),
      style: display(narrow ? 30 : 36, color: p.ink),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          style: side,
          onPressed: state.goToday,
          child: const Text("Aujourd'hui", style: TextStyle(fontWeight: FontWeight.w600)),
        ),
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
      ],
    );
    if (narrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [heading, const SizedBox(height: 8), controls]);
    }
    return Row(
      children: [
        Expanded(child: heading),
        controls,
      ],
    );
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
    const bg = Color(0xFFFFF4FA);
    const fg = Palette.night;
    final soft = fg.withValues(alpha: .08);
    final sel = widget.state.selection.toList()..sort();
    final n = sel.length;
    final narrow = MediaQuery.of(context).size.width < 600;

    Widget btn(String label, AbsenceKind? kind, Color color) => FilledButton(
      onPressed: _busy ? null : () => _commit(kind),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: fg,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
      child: Text(label),
    );

    final count = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$n JOUR${n > 1 ? 'S' : ''} SÉLECTIONNÉ${n > 1 ? 'S' : ''}', style: display(19, color: fg)),
        Text(n > 1 ? '${fmtDay(sel.first)} → ${fmtDay(sel.last)}' : fmtDay(sel.first), style: TextStyle(color: fg.withValues(alpha: .7), fontSize: 12)),
      ],
    );
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
    final actions = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        btn('Congé', AbsenceKind.conge, Palette.pink),
        btn('Télétravail', AbsenceKind.tt, Palette.violet),
        btn('École', AbsenceKind.ecole, Palette.orange),
        btn('Bureau', AbsenceKind.bureau, Palette.cyan),
        btn('Rétablir', null, soft),
      ],
    );
    final close = IconButton(
      tooltip: 'Annuler la sélection',
      onPressed: widget.state.clearSelection,
      icon: Icon(Icons.close_rounded, color: fg.withValues(alpha: .7)),
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(color: Palette.pink, spreadRadius: 2),
          BoxShadow(color: Palette.pink.withValues(alpha: .45), blurRadius: 40, offset: const Offset(0, 12)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: narrow
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: count),
                        close,
                      ],
                    ),
                    const SizedBox(height: 8),
                    note,
                    const SizedBox(height: 8),
                    actions,
                  ],
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [count, const SizedBox(width: 12), note, const SizedBox(width: 10), actions, close]),
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes modifications', style: display(17, color: p.ink)),
          const SizedBox(height: 4),
          Text("Les jours que tu as changés par rapport au planning d'origine.", style: TextStyle(color: p.muted, fontSize: 13)),
          const SizedBox(height: 14),
          if (state.meIndex < 0)
            empty('Choisis ton nom pour voir tes modifications.')
          else if (groups.isEmpty)
            empty("Rien de changé pour l'instant. Sélectionne des jours dans ta ligne du planning.")
          else
            for (var g = 0; g < groups.length; g++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: g == 0 ? null : Border(top: BorderSide(color: p.line)),
                ),
                child: Row(
                  children: [
                    StatusDot(p.status(groups[g].first.kind.code), round: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groups[g].length > 1 ? '${fmtDay(groups[g].first.date)} → ${fmtDay(groups[g].last.date)}' : fmtDay(groups[g].first.date),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${groups[g].first.kind.label} · ${groups[g].length} jour${groups[g].length > 1 ? 's' : ''}'
                            '${groups[g].first.note.isNotEmpty ? ' · ${groups[g].first.note}' : ''}',
                            style: TextStyle(color: p.muted, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => state.goToMonth(groups[g].first.date.substring(0, 7)), child: const Text('Voir')),
                    TextButton(
                      onPressed: () async {
                        await state.removeAll(groups[g]);
                        onToast("Retour au planning d'origine");
                      },
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _SegLabel extends StatelessWidget {
  const _SegLabel(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [StatusDot(color, size: 9), const SizedBox(width: 6), Text(text, softWrap: false)]);
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
    if (targets.isEmpty) return setState(() => _msg = "Aucun jour de ton planning sur cette période.");
    setState(() {
      _busy = true;
      _msg = 'Enregistrement…';
    });
    try {
      final n = await s.apply(targets, _kind, note: _note.text);
      _note.clear();
      setState(() => _msg = '$n jour${n > 1 ? 's' : ''} en ${_kind.label.toLowerCase()}.');
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Changer une longue période', style: display(17, color: p.ink)),
          const SizedBox(height: 4),
          Text(
            'Pratique quand ça déborde sur plusieurs mois. Tous les jours ouvrés de la période prennent le statut choisi.',
            style: TextStyle(color: p.muted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (kind, color) in [(AbsenceKind.conge, p.cge), (AbsenceKind.tt, p.tt), (AbsenceKind.ecole, p.eco), (AbsenceKind.bureau, p.ent)])
                ChoiceChip(
                  label: _SegLabel(kind == AbsenceKind.bureau ? 'Bureau' : kind.label, color),
                  selected: _kind == kind,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _kind = kind),
                ),
            ],
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
            child: const Text('Appliquer à la période', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (_msg.isNotEmpty) ...[const SizedBox(height: 8), Text(_msg, style: TextStyle(color: p.muted, fontSize: 13))],
        ],
      ),
    );
  }
}
