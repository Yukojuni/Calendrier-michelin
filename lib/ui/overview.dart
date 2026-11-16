/// Encart « Aujourd'hui » et carte personnelle.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../planning.dart';
import '../theme.dart';
import 'widgets.dart';

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class TodayPanel extends StatelessWidget {
  const TodayPanel({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final day = referenceDay(state.today);
    final isToday = day == state.today;
    final work = <int>[], school = <int>[], away = <int>[];
    var ferie = false, n = 0;
    for (var i = 0; i < kPeople.length; i++) {
      final c = effectiveCode(day, i, state.overrides);
      if (c == '-') continue;
      n++;
      if (c == 'F') ferie = true;
      if (kAtWork.contains(c)) {
        work.add(i);
      } else if (kAtSchool.contains(c)) {
        school.add(i);
      } else if (kAway.contains(c)) {
        away.add(i);
      }
    }
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Eyebrow(isToday ? "Aujourd'hui" : 'Prochain jour ouvré'),
        const SizedBox(height: 2),
        Text(capitalize(DateFormat('EEEE d MMMM').format(parseIso(day))), style: display(24, color: p.ink)),
        const SizedBox(height: 14),
        if (ferie)
          Text('Jour férié : tout le monde se repose.', style: TextStyle(color: p.muted))
        else ...[
          Wrap(spacing: 28, runSpacing: 12, children: [
            _Group(label: 'Au bureau', color: p.ent, people: work),
            _Group(label: "À l'école", color: p.eco, people: school),
            _Group(label: 'Congé · télétravail', color: p.cge, people: away),
          ]),
          if (work.length == n && n > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Palette.accent, borderRadius: BorderRadius.circular(99)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded, size: 15, color: Palette.accentInk),
                SizedBox(width: 4),
                Text("Toute l'équipe au bureau",
                    style: TextStyle(color: Palette.accentInk, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ]),
            ),
          ],
        ],
      ]),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.color, required this.people});

  final String label;
  final Color color;
  final List<int> people;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        StatusDot(color, size: 9),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12.5, color: p.muted)),
        const SizedBox(width: 5),
        Text('${people.length}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.ink)),
      ]),
      const SizedBox(height: 6),
      SizedBox(
        height: 34,
        width: people.isEmpty ? 34 : 34 + (people.length - 1) * 26,
        child: Stack(children: [
          if (people.isEmpty) const Avatar(null, size: 34, placeholder: '–'),
          for (var k = 0; k < people.length; k++)
            Positioned(left: k * 26.0, child: Avatar(kPeople[people[k]], size: 34, ring: p.surface)),
        ]),
      ),
    ]);
  }
}

class MePanel extends StatelessWidget {
  const MePanel({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final i = state.meIndex;
    if (i < 0) {
      return Panel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('Bienvenue'),
          const SizedBox(height: 4),
          Text('Qui es-tu ?', style: display(20, color: p.ink)),
          const SizedBox(height: 8),
          Text('Choisis ton nom pour poser tes congés directement dans le planning.', style: TextStyle(color: p.muted)),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final person in kPeople)
              ActionChip(
                avatar: Avatar(person, size: 24),
                label: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                shape: const StadiumBorder(),
                side: BorderSide(color: p.line),
                backgroundColor: p.surface,
                onPressed: () => state.setMe(person.name),
              ),
          ]),
        ]),
      );
    }
    final person = kPeople[i];
    final today = state.today;
    var conges = 0, upcoming = 0, tt = 0;
    for (final d in kDates) {
      final c = effectiveCode(d, i, state.overrides);
      if (c == 'K') {
        conges++;
        if (d.compareTo(today) >= 0) upcoming++;
      } else if (c == 't' || c == 'T') {
        tt++;
      }
    }
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(person, size: 44),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(person.name, style: display(18, color: p.ink)),
            Text('${person.school} · alternance', style: TextStyle(color: p.muted, fontSize: 12.5)),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Kpi(value: conges, label: 'jours de congé')),
          const SizedBox(width: 8),
          Expanded(child: _Kpi(value: upcoming, label: 'à venir')),
          const SizedBox(width: 8),
          Expanded(child: _Kpi(value: tt, label: 'télétravail')),
        ]),
      ]),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: p.sunk, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: display(24, color: p.ink)),
        Text(label, style: TextStyle(fontSize: 12, color: p.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
