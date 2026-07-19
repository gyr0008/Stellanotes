// 星空图谱力导向布局引擎

import 'dart:math';

class StarNode {
  final int id;
  final String label;
  final String type; // 'diary' | 'todo' | 'tag'
  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double mass;
  bool pinned = false;

  StarNode({
    required this.id,
    required this.label,
    required this.type,
    required this.x,
    required this.y,
    double? mass,
  }) : mass = mass ?? 1.0;
}

class StarLink {
  final int sourceId;
  final int targetId;
  final double strength; // 0-1，关联强度

  StarLink({
    required this.sourceId,
    required this.targetId,
    this.strength = 0.5,
  });
}

class ForceLayout {
  final List<StarNode> nodes;
  final List<StarLink> links;

  // 力参数
  double repulsionForce = 800;    // 节点间斥力
  double attractionForce = 0.01;  // 连线引力
  double centerForce = 0.02;      // 向心力
  double damping = 0.85;          // 阻尼（速度衰减）
  double minVelocity = 0.01;      // 最小速度阈值

  // 画布中心
  double centerX = 0;
  double centerY = 0;

  ForceLayout({
    required this.nodes,
    required this.links,
  });

  /// 执行一步模拟
  void tick() {
    _applyRepulsion();
    _applyAttraction();
    _applyCenterForce();
    _updatePositions();
  }

  /// 执行多步直到稳定
  void simulate({int steps = 300}) {
    for (int i = 0; i < steps; i++) {
      tick();
      // 逐渐降低斥力，帮助收敛
      repulsionForce *= 0.999;
    }
  }

  void _applyRepulsion() {
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];

        double dx = b.x - a.x;
        double dy = b.y - a.y;
        double dist = sqrt(dx * dx + dy * dy);

        if (dist < 1) {
          dx = Random().nextDouble() - 0.5;
          dy = Random().nextDouble() - 0.5;
          dist = sqrt(dx * dx + dy * dy);
        }

        final force = repulsionForce / (dist * dist);
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;

        if (!a.pinned) {
          a.vx -= fx / a.mass;
          a.vy -= fy / a.mass;
        }
        if (!b.pinned) {
          b.vx += fx / b.mass;
          b.vy += fy / b.mass;
        }
      }
    }
  }

  void _applyAttraction() {
    for (final link in links) {
      final source = nodes.firstWhere((n) => n.id == link.sourceId);
      final target = nodes.firstWhere((n) => n.id == link.targetId);

      double dx = target.x - source.x;
      double dy = target.y - source.y;
      double dist = sqrt(dx * dx + dy * dy);

      if (dist < 1) continue;

      final force = dist * attractionForce * link.strength;
      final fx = (dx / dist) * force;
      final fy = (dy / dist) * force;

      if (!source.pinned) {
        source.vx += fx / source.mass;
        source.vy += fy / source.mass;
      }
      if (!target.pinned) {
        target.vx -= fx / target.mass;
        target.vy -= fy / target.mass;
      }
    }
  }

  void _applyCenterForce() {
    for (final node in nodes) {
      if (node.pinned) continue;

      node.vx += (centerX - node.x) * centerForce;
      node.vy += (centerY - node.y) * centerForce;
    }
  }

  void _updatePositions() {
    for (final node in nodes) {
      if (node.pinned) continue;

      node.vx *= damping;
      node.vy *= damping;

      // 速度限制
      final speed = sqrt(node.vx * node.vx + node.vy * node.vy);
      if (speed > 10) {
        node.vx = (node.vx / speed) * 10;
        node.vy = (node.vy / speed) * 10;
      }

      node.x += node.vx;
      node.y += node.vy;
    }
  }

  /// 判断系统是否已稳定
  bool get isStable {
    for (final node in nodes) {
      if (node.pinned) continue;
      final speed = sqrt(node.vx * node.vx + node.vy * node.vy);
      if (speed > minVelocity) return false;
    }
    return true;
  }
}
