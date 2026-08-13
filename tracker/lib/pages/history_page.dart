import 'package:flutter/material.dart';
import 'package:tracker/data/repository_scope.dart';
import 'package:tracker/models/workout_session.dart';
import 'package:tracker/pages/custom/custom_app_bar.dart';

/// Lists past [WorkoutSession]s with date, gym, set count and duration.
///
/// Milestone 3 wires the list so completed workouts surface after a session is
/// ended (Checkpoint 3). Milestone 5 expands this into the full history overview
/// (§1.2) + calendar (§2.5) with per-session detail.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  Map<int, String> _gymNames = const {};
  bool _didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RepositoryScope is an inherited widget, so read it here (after initState)
    // rather than in initState.
    if (!_didLoad) {
      _didLoad = true;
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
    final stream = RepositoryScope.maybeOf(context)?.sessions.watchAll();
    return CustomScrollView(
      slivers: <Widget>[
        CustomAppBar(context, title: 'History'),
        SliverToBoxAdapter(
          child: StreamBuilder<List<WorkoutSession>>(
            stream: stream,
            initialData: const <WorkoutSession>[],
            builder: (context, snapshot) {
              final sessions = snapshot.data ?? const <WorkoutSession>[];
              if (sessions.isEmpty) {
                return const _EmptyHistory();
              }
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
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
                ),
              );
            },
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
