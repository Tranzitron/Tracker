import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';
import 'package:tracker/pages/custom/custom_route.dart';
import 'package:tracker/pages/history/history_calendar.dart';
import 'package:tracker/pages/history/session_detail_page.dart';

enum _HistoryMode { list, calendar }

/// History overview (Plan.md §1.2) + calendar (Plan.md §2.5).
///
/// Toggles between a chronological session list and an interactive month
/// calendar; either way a session resolves to its full [SessionDetailPage]
/// (Checkpoint 5).
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<int, String> _gymNames = const {};
  Stream<List<WorkoutSession>>? _stream;
  bool _didLoad = false;
  _HistoryMode _mode = _HistoryMode.list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it here (after initState).
    // Cache the watch stream once so rebuilds don't resubscribe the query.
    if (!_didLoad) {
      _didLoad = true;
      _stream = RepositoryScope.maybeOf(context)?.sessions.watchAll();
      _loadGyms();
    }
  }

  Future<void> _loadGyms() async {
    final repo = RepositoryScope.maybeOf(context);
    final gyms = await repo?.gyms.getAll() ?? const [];
    if (!mounted) return;
    setState(() {
      _gymNames = {for (final g in gyms) g.id: g.name};
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'History'),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SegmentedButton<_HistoryMode>(
                  segments: const [
                    ButtonSegment(
                      value: _HistoryMode.list,
                      label: Text('List'),
                      icon: Icon(Icons.list_sharp),
                    ),
                    ButtonSegment(
                      value: _HistoryMode.calendar,
                      label: Text('Calendar'),
                      icon: Icon(Icons.calendar_month_sharp),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<WorkoutSession>>(
                  stream: _stream,
                  initialData: const <WorkoutSession>[],
                  builder: (context, snapshot) {
                    final sessions = snapshot.data ?? const <WorkoutSession>[];
                    if (sessions.isEmpty) {
                      return const _EmptyHistory();
                    }
                    if (_mode == _HistoryMode.calendar) {
                      return HistoryCalendar(
                        sessions: sessions,
                        gymNames: _gymNames,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final session in sessions)
                          _SessionTile(
                            session: session,
                            gymName: session.gymId == null
                                ? null
                                : _gymNames[session.gymId],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.history, size: 48),
          SizedBox(height: 12),
          Text('No workouts logged yet'),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.gymName});

  final WorkoutSession session;
  final String? gymName;

  @override
  Widget build(BuildContext context) {
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_run_sharp),
        title: Text(session.title),
        subtitle: Text(
          '${_date(session.startTime)}'
          '${gymName != null ? ' · $gymName' : ''}'
          '\n${session.sets.length} set(s) · ${_dur(duration)}',
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_sharp),
        onTap: () => pushTo(
          context,
          SessionDetailPage(session: session, gymName: gymName),
        ),
      ),
    );
  }

  String _date(DateTime dt) {
    final d = dt.toLocal();
    return '${d.year}-${_p(d.month)}-${_p(d.day)} ${_p(d.hour)}:${_p(d.minute)}';
  }

  String _dur(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String _p(int v) => v.toString().padLeft(2, '0');
}
