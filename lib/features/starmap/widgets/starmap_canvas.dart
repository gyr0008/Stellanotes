import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/starmap_provider.dart';
import '../providers/force_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/frosted_card.dart';

/// 星空图谱画布（Phase 3 优化版）
///
/// 新增特性：
/// - 流星动画（新建记录入场）
/// - 星座聚合（按标签分组）
/// - LOD 性能优化
/// - 主题切换平滑过渡
class StarmapCanvas extends ConsumerStatefulWidget {
  const StarmapCanvas({super.key});

  @override
  ConsumerState<StarmapCanvas> createState() => _StarmapCanvasState();
}

class _StarmapCanvasState extends ConsumerState<StarmapCanvas>
    with TickerProviderStateMixin {
  ForceLayout? _layout;
  List<StarNode> _nodes = [];
  List<StarLink> _links = [];
  StarfieldTheme? _theme;
  StarfieldTheme? _previousTheme;

  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _dragStart = Offset.zero;
  Offset _dragOffset = Offset.zero;
  int? _selectedNodeId;

  late AnimationController _twinkleController;
  late AnimationController _meteorController;
  late AnimationController _themeTransitionController;

  final List<Meteor> _meteors = [];
  final Random _random = Random();
  List<Constellation> _constellations = [];
  bool _useLOD = false;

  @override
  void initState() {
    super.initState();
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _meteorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _themeTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    final data = await ref.read(starmapDataProvider.future);

    setState(() {
      _nodes = data.nodes;
      _links = data.links;
      _previousTheme = _theme;
      _theme = data.theme;
    });

    _layout = ForceLayout(nodes: _nodes, links: _links);
    _layout!.centerX = MediaQuery.of(context).size.width / 2;
    _layout!.centerY = MediaQuery.of(context).size.height / 2;

    for (final node in _nodes) {
      node.x = _layout!.centerX + (_random.nextDouble() - 0.5) * 400;
      node.y = _layout!.centerY + (_random.nextDouble() - 0.5) * 400;
    }

    _layout!.simulate(steps: 300);
    _buildConstellations();
    _useLOD = _nodes.length > 100;

    setState(() {});
    _twinkleController.repeat();
  }

  void _buildConstellations() {
    _constellations = [];
    final tagNodes = _nodes.where((n) => n.type == 'tag').toList();

    for (final tagNode in tagNodes) {
      final relatedNodeIds = <int>{};
      for (final link in _links) {
        if (link.sourceId == tagNode.id) {
          relatedNodeIds.add(link.targetId);
        } else if (link.targetId == tagNode.id) {
          relatedNodeIds.add(link.sourceId);
        }
      }

      if (relatedNodeIds.isNotEmpty) {
        _constellations.add(Constellation(
          centerNode: tagNode,
          memberNodeIds: relatedNodeIds,
          color: _theme?.tagColor.color ?? Colors.purple,
        ));
      }
    }
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _meteorController.dispose();
    _themeTransitionController.dispose();
    super.dispose();
  }

  void spawnMeteor(StarNode newNode) {
    final startX = _random.nextDouble() * MediaQuery.of(context).size.width;
    final startY = -50.0;

    setState(() {
      _meteors.add(Meteor(
        targetNode: newNode,
        startX: startX,
        startY: startY,
        progress: 0.0,
      ));
    });

    _meteorController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_theme == null || _nodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载星空数据...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return GestureDetector(
      onScaleStart: (details) {
        _dragStart = details.focalPoint;
        _dragOffset = _offset;
      },
      onScaleUpdate: (details) {
        setState(() {
          _scale = details.scale.clamp(0.2, 5.0);
          _offset = _dragOffset + details.focalPoint - _dragStart;
        });
      },
      onTapDown: (details) {
        _handleTap(details.localPosition);
      },
      onDoubleTap: () {
        _showQuickCreateDialog();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _theme!.backgroundTop,
              _theme!.backgroundBottom,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_twinkleController, _meteorController]),
          builder: (context, child) {
            return CustomPaint(
              painter: StarfieldPainter(
                nodes: _nodes,
                links: _links,
                theme: _theme!,
                previousTheme: _previousTheme,
                scale: _scale,
                offset: _offset,
                selectedNodeId: _selectedNodeId,
                twinklePhase: _twinkleController.value,
                constellations: _constellations,
                meteors: _meteors,
                meteorProgress: _meteorController.value,
                useLOD: _useLOD,
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    final worldPosition = (position - _offset) / _scale;

    StarNode? closest;
    double minDist = 30 / _scale;

    for (final node in _nodes) {
      final dist = (Offset(node.x, node.y) - worldPosition).distance;
      if (dist < minDist) {
        minDist = dist;
        closest = node;
      }
    }

    setState(() {
      _selectedNodeId = closest?.id;
    });

    if (closest != null) {
      _showNodeDetail(closest);
    }
  }

  void _showNodeDetail(StarNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FrostedCard(
        effect: _theme?.glassEffect,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  node.type == 'diary'
                      ? Icons.menu_book
                      : node.type == 'todo'
                          ? Icons.check_box
                          : Icons.label,
                  color: _getNodeColor(node),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '类型: ${node.type == 'diary' ? '日记' : node.type == 'todo' ? '待办' : '标签'}',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              '关联数: ${_links.where((l) => l.sourceId == node.id || l.targetId == node.id).length}',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('关联'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.push_pin),
                  label: const Text('固定'),
                  onPressed: () {
                    ref.read(starmapInteractionProvider.notifier).togglePinNode(node.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('快速创建'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('新建日记'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.check_box),
              title: const Text('新建待办'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNodeColor(StarNode node) {
    switch (node.type) {
      case 'diary':
        return _theme!.diaryColor.color;
      case 'todo':
        return _theme!.todoColor.color;
      case 'done_todo':
        return _theme!.doneTodoColor.color;
      case 'tag':
        return _theme!.tagColor.color;
      default:
        return Colors.white;
    }
  }
}

class Meteor {
  final StarNode targetNode;
  final double startX;
  final double startY;
  final double progress;

  Meteor({
    required this.targetNode,
    required this.startX,
    required this.startY,
    required this.progress,
  });
}

class Constellation {
  final StarNode centerNode;
  final Set<int> memberNodeIds;
  final Color color;

  Constellation({
    required this.centerNode,
    required this.memberNodeIds,
    required this.color,
  });
}

class StarfieldPainter extends CustomPainter {
  final List<StarNode> nodes;
  final List<StarLink> links;
  final StarfieldTheme theme;
  final StarfieldTheme? previousTheme;
  final double scale;
  final Offset offset;
  final int? selectedNodeId;
  final double twinklePhase;
  final List<Constellation> constellations;
  final List<Meteor> meteors;
  final double meteorProgress;
  final bool useLOD;

  StarfieldPainter({
    required this.nodes,
    required this.links,
    required this.theme,
    this.previousTheme,
    required this.scale,
    required this.offset,
    this.selectedNodeId,
    required this.twinklePhase,
    required this.constellations,
    required this.meteors,
    required this.meteorProgress,
    required this.useLOD,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    _drawConstellations(canvas);
    _drawLinks(canvas);
    _drawStars(canvas);
    _drawMeteors(canvas);

    canvas.restore();
  }

  void _drawConstellations(Canvas canvas) {
    for (final constellation in constellations) {
      final center = Offset(constellation.centerNode.x, constellation.centerNode.y);

      final glowPaint = Paint()
        ..color = constellation.color.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

      double maxDist = 0;
      for (final nodeId in constellation.memberNodeIds) {
        final node = nodes.firstWhere(
          (n) => n.id == nodeId,
          orElse: () => constellation.centerNode,
        );
        final dist = (Offset(node.x, node.y) - center).distance;
        if (dist > maxDist) maxDist = dist;
      }

      if (maxDist > 0) {
        canvas.drawCircle(center, maxDist + 30, glowPaint);
      }
    }
  }

  void _drawLinks(Canvas canvas) {
    for (final link in links) {
      final source = nodes.firstWhere(
        (n) => n.id == link.sourceId,
        orElse: () => nodes.first,
      );
      final target = nodes.firstWhere(
        (n) => n.id == link.targetId,
        orElse: () => nodes.first,
      );

      final opacity = useLOD && scale < 0.5 ? 0.3 : 1.0;

      final paint = Paint()
        ..color = theme.linkColor.withOpacity(theme.linkColor.opacity * opacity)
        ..strokeWidth = 1.5 * link.strength
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(source.x, source.y),
        Offset(target.x, target.y),
        paint,
      );
    }
  }

  void _drawStars(Canvas canvas) {
    for (final node in nodes) {
      final color = _getNodeColor(node);
      final isSelected = node.id == selectedNodeId;
      final baseRadius = _getNodeRadius(node);

      if (useLOD && scale < 0.3 && !isSelected) {
        final paint = Paint()..color = color.withOpacity(0.6);
        canvas.drawCircle(Offset(node.x, node.y), 2, paint);
        continue;
      }

      final twinkle = sin(twinklePhase * pi * 2 + node.id) * 0.3 + 0.7;
      final radius = baseRadius * (isSelected ? 1.3 : 1.0) * twinkle;

      final glowPaint = Paint()
        ..color = color.withOpacity(0.3 * twinkle)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(node.x, node.y), radius * 2, glowPaint);

      final starPaint = Paint()
        ..color = color.withOpacity(isSelected ? 1.0 : 0.9 * twinkle)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(node.x, node.y), radius, starPaint);

      if (radius > 6) {
        final rayPaint = Paint()
          ..color = color.withOpacity(0.4 * twinkle)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(node.x - radius * 1.5, node.y),
          Offset(node.x + radius * 1.5, node.y),
          rayPaint,
        );
        canvas.drawLine(
          Offset(node.x, node.y - radius * 1.5),
          Offset(node.x, node.y + radius * 1.5),
          rayPaint,
        );
      }

      if (scale > 0.5 || isSelected) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: node.label,
            style: TextStyle(
              color: Colors.white.withOpacity(isSelected ? 1.0 : 0.8),
              fontSize: 12 / scale,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(node.x + radius + 4, node.y - textPainter.height / 2),
        );
      }
    }
  }

  void _drawMeteors(Canvas canvas) {
    for (final meteor in meteors) {
      final target = Offset(meteor.targetNode.x, meteor.targetNode.y);
      final start = Offset(meteor.startX, meteor.startY);

      final currentPos = Offset(
        start.dx + (target.dx - start.dx) * meteorProgress,
        start.dy + (target.dy - start.dy) * meteorProgress,
      );

      final tailLength = 50.0;
      final tailDirection = (target - start).normalize();
      final tailStart = currentPos - tailDirection * tailLength;

      final tailPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment(tailStart.dx, tailStart.dy),
          end: Alignment(currentPos.dx, currentPos.dy),
          colors: [
            Colors.transparent,
            theme.diaryColor.color.withOpacity(0.6),
          ],
        ).createShader(Rect.fromPoints(tailStart, currentPos))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(tailStart, currentPos, tailPaint);

      final headPaint = Paint()
        ..color = theme.diaryColor.color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(currentPos, 4, headPaint);
    }
  }

  Color _getNodeColor(StarNode node) {
    switch (node.type) {
      case 'diary':
        return theme.diaryColor.color;
      case 'todo':
        return theme.todoColor.color;
      case 'done_todo':
        return theme.doneTodoColor.color;
      case 'tag':
        return theme.tagColor.color;
      default:
        return Colors.white;
    }
  }

  double _getNodeRadius(StarNode node) {
    final linkCount = links.where(
      (l) => l.sourceId == node.id || l.targetId == node.id,
    ).length;
    final baseRadius = 4.0 + linkCount * 0.5;
    return baseRadius.clamp(4.0, 12.0);
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) {
    return oldDelegate.twinklePhase != twinklePhase ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.meteorProgress != meteorProgress;
  }
}

extension VectorNormalization on Offset {
  Offset normalize() {
    final length = distance;
    if (length == 0) return Offset.zero;
    return Offset(dx / length, dy / length);
  }
}
