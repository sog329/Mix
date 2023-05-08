import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: GameWidget(game: MixGame()),
      )));
}

class MixGame extends Forge2DGame with HasTappables, ContactListener {
  @override
  Future<void> onLoad() async {
    BallTemplate? t = BallTemplate.random();
    if (t != null) {
      add(Ball(position: size / 2, toTemplate: t));
    }
    addAll(createBoundaries());
    world.setContactListener(this);
    world.setGravity(world.gravity * 5);
    return super.onLoad();
  }

  @override
  void onTapUp(pointerId, info) {
    super.onTapUp(pointerId, info);

    BallTemplate? t = BallTemplate.random();
    if (t != null) {
      add(Ball(position: info.eventPosition.game, toTemplate: t));
    }
  }

  List<Component> createBoundaries() {
    final topLeft = Vector2.zero();
    final bottomRight = screenToWorld(camera.viewport.effectiveSize);
    final topRight = Vector2(bottomRight.x, topLeft.y);
    final bottomLeft = Vector2(topLeft.x, bottomRight.y);
    return [
      Wall(topLeft, topRight),
      Wall(topRight, bottomRight),
      Wall(bottomLeft, bottomRight),
      Wall(topLeft, bottomLeft)
    ];
  }

  @override
  void beginContact(Contact contact) {
    Object? a = contact.bodyA.userData;
    Object? b = contact.bodyB.userData;
    if (a is Ball && b is Ball) {
      if (a.toTemplate.radius == b.toTemplate.radius) {
        Vector2 p = contact.bodyA.position.y < contact.bodyB.position.y
            ? contact.bodyA.position
            : contact.bodyB.position;
        remove(a);
        remove(b);
        BallTemplate nowTemplate = a.toTemplate;
        BallTemplate? nextTemplate = BallTemplate.next(a.toTemplate);
        if (nextTemplate != null) {
          Ball ball = Ball(
              position: p,
              speed: a.body.linearVelocity + b.body.linearVelocity,
              fromTemplate: nowTemplate,
              toTemplate: nextTemplate);
          add(ball);
        }
      }
    }
  }

  @override
  void endContact(Contact contact) {}

  @override
  void postSolve(Contact contact, ContactImpulse impulse) {}

  @override
  void preSolve(Contact contact, Manifold oldManifold) {}
}

class BallTemplate {
  final int id;
  final double radius;
  final Color color;

  static final Map<int, BallTemplate> map = {
    0: BallTemplate(0, 2, Colors.primaries[0]),
    1: BallTemplate(1, 3, Colors.primaries[2]),
    2: BallTemplate(2, 4, Colors.primaries[4]),
    3: BallTemplate(3, 5, Colors.primaries[6]),
    4: BallTemplate(4, 6, Colors.primaries[8]),
    5: BallTemplate(5, 7, Colors.primaries[10]),
    6: BallTemplate(6, 8, Colors.primaries[12]),
    7: BallTemplate(7, 9, Colors.primaries[14]),

    // 0: BallTemplate(0, 2, const Color.fromARGB(255, 232, 211, 192)),
    // 1: BallTemplate(1, 2.5, const Color.fromARGB(255, 183, 127, 112)),
    // 2: BallTemplate(2, 3, const Color.fromARGB(255, 214, 195, 139)),
    // 3: BallTemplate(3, 3.5, const Color.fromARGB(255, 132, 155, 145)),
    // 4: BallTemplate(4, 4, const Color.fromARGB(255, 167, 154, 137)),
    // 5: BallTemplate(5, 4.5, const Color.fromARGB(255, 194, 206, 220)),
    // 6: BallTemplate(6, 5, const Color.fromARGB(255, 176, 177, 182)),
    // 7: BallTemplate(7, 5.5, const Color.fromARGB(255, 151, 151, 113)),
    // 8: BallTemplate(8, 6, const Color.fromARGB(255, 145, 173, 158)),
    // 9: BallTemplate(9, 6.5, const Color.fromARGB(255, 104, 103, 137)),
  };

  BallTemplate(this.id, this.radius, this.color);

  static BallTemplate? random() {
    int tmp = Random().nextInt(BallTemplate.map.length ~/ 2);
    return BallTemplate.map[tmp];
  }

  static BallTemplate? next(BallTemplate t) {
    return BallTemplate.map[t.id + 1];
  }

  static Color lastColor(BallTemplate t) {
    BallTemplate? tmp = map[t.id - 1];
    return tmp == null ? Colors.red[200]! : tmp!.color;
  }
}

mixin Percent on Component {
  int? start;
  bool end = false;

  double getPercent(int duration) {
    double p = 0;
    if (!end && start == null) {
      start = DateTime.now().millisecondsSinceEpoch;
    } else {
      int now = DateTime.now().millisecondsSinceEpoch;
      int dif = now - start!;
      p = dif / duration;
      if (p < 0 || p >= 1) {
        end = true;
        p = 1;
      }
    }
    return p;
  }
}

class Ball extends BodyComponent with Tappable, Percent {
  final Vector2 position;
  final BallTemplate toTemplate;
  late BallTemplate? fromTemplate;
  final Vector2? speed;

  @override
  void update(double dt) {
    super.update(dt);
    if (!end && fromTemplate != null) {
      double p = getPercent(500);
      _setColor(p);
      _setRadius(body.fixtures.first.shape, p);
    }
  }

  Ball({
    required this.position,
    this.speed,
    this.fromTemplate,
    required this.toTemplate,
  });

  void _setColor(double p) {
    Color from = BallTemplate.lastColor(toTemplate);
    Color c = Color.lerp(from, toTemplate.color, p)!;
    paint.shader = LinearGradient(colors: [from, c]).createShader(
        Rect.fromCircle(center: Offset.zero, radius: toTemplate.radius));
  }

  void _setRadius(Shape s, double p) {
    // p = const Cubic(0.175, 0.885, 0.32, 2).transform(p);
    p = Curves.bounceOut.transform(p);
    s.radius =
        fromTemplate!.radius + (toTemplate.radius - fromTemplate!.radius) * p;
  }

  @override
  Body createBody() {
    _setColor(1);
    final shape = CircleShape();
    shape.radius = toTemplate.radius;

    Body b = world.createBody(BodyDef(
      userData: this,
      angularDamping: 0.8,
      position: position,
      type: BodyType.dynamic,
    ))
      ..createFixture(FixtureDef(
        shape,
        restitution: 0.5, //弹性
        density: 10, // 密度
        friction: 0.4, // 摩擦力
      ));
    if (speed != null) {
      b.linearVelocity += speed!;
    }
    return b;
  }
}

@override
bool onTapUp(info) {
  // body.applyLinearImpulse(Vector2.random() * 5000);
  return true;
}

class Wall extends BodyComponent {
  final Vector2 _start;
  final Vector2 _end;

  Wall(this._start, this._end) {
    paint.color = const Color.fromARGB(0, 0, 0, 0);
  }

  @override
  Body createBody() {
    final shape = EdgeShape()..set(_start, _end);
    return world.createBody(BodyDef(
      userData: this,
      position: Vector2.zero(),
      type: BodyType.static,
    ))
      ..createFixture(FixtureDef(
        shape,
        friction: 0.3,
      ));
  }
}