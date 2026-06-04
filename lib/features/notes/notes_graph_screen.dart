import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';

import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../l10n/app_localizations.dart';
import 'notes_providers.dart';
import 'widgets/notes_common.dart';

/// Kraftgerichteter Graph der Notiz-Verlinkungen.
///
/// Wahl der Engine: Paket `graphview` mit `FruchtermanReingoldAlgorithm` und
/// fester Iterationszahl. Die Simulation läuft einmalig bis zur Stabilisierung
/// und löst danach kein Dauer-Repaint aus (Anforderung Abschnitt 10). Pan/Zoom
/// über `InteractiveViewer`, das Ergebnis in einer `RepaintBoundary`. Bei ~300
/// Knoten bleibt das interaktiv; für sehr große Graphen steht der lokale Graph
/// (Nachbarn bis Tiefe N) bereit.
class NotesGraphScreen extends ConsumerStatefulWidget {
  const NotesGraphScreen({super.key});

  @override
  ConsumerState<NotesGraphScreen> createState() => _NotesGraphScreenState();
}

class _NotesGraphScreenState extends ConsumerState<NotesGraphScreen> {
  final TransformationController _transform = TransformationController();
  int? _focusId;
  bool _local = false;
  int _depth = 1;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Berechnet die sichtbare Knotenmenge: alle oder (im lokalen Modus) die
  /// Nachbarn des Fokusknotens bis Tiefe [_depth].
  Set<int> _visibleNodes(NotesGraphData data) {
    if (!_local || _focusId == null) {
      return {for (final n in data.nodes) n.id};
    }
    final adjacency = <int, Set<int>>{};
    for (final (s, t) in data.edges) {
      adjacency.putIfAbsent(s, () => {}).add(t);
      adjacency.putIfAbsent(t, () => {}).add(s);
    }
    final visible = <int>{_focusId!};
    var frontier = <int>{_focusId!};
    for (var d = 0; d < _depth; d++) {
      final next = <int>{};
      for (final node in frontier) {
        next.addAll(adjacency[node] ?? const {});
      }
      next.removeWhere(visible.contains);
      visible.addAll(next);
      frontier = next;
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dataAsync = ref.watch(graphDataProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: Text(l10n.notes_graph,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: _focusId == null
                ? null
                : () => setState(() => _local = !_local),
            icon: Icon(_local ? Icons.hub_rounded : Icons.scatter_plot_rounded,
                size: 18,
                color: _focusId == null
                    ? TraumColors.onBackgroundSubtle
                    : kNotesAccent),
            label: Text(_local ? l10n.notes_local_graph : l10n.notes_full_graph,
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: _focusId == null
                        ? TraumColors.onBackgroundSubtle
                        : kNotesAccent)),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: kNotesAccent)),
        error: (e, _) =>
            NotesEmptyState(icon: Icons.error_outline, message: '$e'),
        data: (data) {
          if (data.nodes.isEmpty) {
            return NotesEmptyState(
                icon: Icons.hub_outlined, message: l10n.notes_no_notes);
          }
          return Column(
            children: [
              if (_local && _focusId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('${l10n.notes_neighbor_depth}: $_depth',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackgroundMuted,
                              fontSize: 13)),
                      Expanded(
                        child: Slider(
                          value: _depth.toDouble(),
                          min: 1,
                          max: 3,
                          divisions: 2,
                          activeColor: kNotesAccent,
                          onChanged: (v) => setState(() => _depth = v.round()),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: _buildGraph(data)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGraph(NotesGraphData data) {
    final visible = _visibleNodes(data);
    final notesById = {for (final n in data.nodes) n.id: n};

    final graph = Graph();
    final nodeById = <int, Node>{};
    for (final id in visible) {
      final node = Node.Id(id);
      nodeById[id] = node;
      graph.addNode(node);
    }
    for (final (s, t) in data.edges) {
      if (visible.contains(s) && visible.contains(t) && s != t) {
        graph.addEdge(nodeById[s]!, nodeById[t]!,
            paint: Paint()
              ..color = kNotesAccent.withValues(alpha: 0.35)
              ..strokeWidth = 1);
      }
    }

    // Feste Iterationszahl → einmalige Stabilisierung statt Dauer-Repaint.
    final algorithm = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(iterations: 600, shuffleNodes: true),
    );

    return RepaintBoundary(
      child: InteractiveViewer(
        transformationController: _transform,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(800),
        minScale: 0.05,
        maxScale: 4,
        child: GestureDetector(
          onDoubleTap: () => _transform.value = Matrix4.identity(),
          child: Padding(
            padding: const EdgeInsets.all(80),
            child: GraphView(
              graph: graph,
              algorithm: algorithm,
              paint: Paint()
                ..color = kNotesAccent.withValues(alpha: 0.35)
                ..strokeWidth = 1
                ..style = PaintingStyle.stroke,
              builder: (node) {
                final id = (node.key!.value as int);
                final note = notesById[id];
                final inDeg = data.inDegree[id] ?? 0;
                return _NodeWidget(
                  title: note?.title ?? '—',
                  inDegree: inDeg,
                  focused: id == _focusId,
                  onTap: () => context.push(Routes.noteDetailPath(id)),
                  onLongPress: () => setState(() {
                    _focusId = id;
                    _local = true;
                  }),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeWidget extends StatelessWidget {
  final String title;
  final int inDegree;
  final bool focused;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NodeWidget({
    required this.title,
    required this.inDegree,
    required this.focused,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Knotengröße skaliert mit Anzahl eingehender Links.
    final size = (22 + inDegree * 6).clamp(22, 64).toDouble();
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                kNotesAccent.withValues(alpha: focused ? 1 : 0.85),
                TraumColors.indigoBlue.withValues(alpha: focused ? 1 : 0.7),
              ]),
              shape: BoxShape.circle,
              border: focused
                  ? Border.all(color: TraumColors.onBackground, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: kNotesAccent.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: TraumColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(TraumRadius.input),
              ),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
