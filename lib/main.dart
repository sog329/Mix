import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame_forge2d/flame_forge2d.dart' hide Particle;
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: Forge2DExample()));
}

class Forge2DExample extends Forge2DGame with HasTappables, ContactListener {
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
          // BloomParticle(gameRef).show(p, nowTemplate.radius/100);
          //particle
          // add(
          //   ParticleSystemComponent(
          //     position: contact.bodyA.position,
          //     particle: CircleParticle(
          //       radius: nowTemplate.radius,
          //       paint: Paint()..color = nowTemplate.color.withOpacity(.3),
          //     ),
          //   ),
          // );
          // add(
          //   ParticleSystemComponent(
          //     position: contact.bodyB.position,
          //     particle: CircleParticle(
          //       radius: nowTemplate.radius,
          //       paint: Paint()..color = nowTemplate.color.withOpacity(.3),
          //     ),
          //   ),
          // );
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
    0: BallTemplate(0, 2, const Color.fromARGB(255, 232, 211, 192)),
    1: BallTemplate(1, 2.5, const Color.fromARGB(255, 183, 127, 112)),
    2: BallTemplate(2, 3, const Color.fromARGB(255, 214, 195, 139)),
    3: BallTemplate(3, 3.5, const Color.fromARGB(255, 132, 155, 145)),
    4: BallTemplate(4, 4, const Color.fromARGB(255, 167, 154, 137)),
    5: BallTemplate(5, 4.5, const Color.fromARGB(255, 194, 206, 220)),
    6: BallTemplate(6, 5, const Color.fromARGB(255, 176, 177, 182)),
    7: BallTemplate(7, 5.5, const Color.fromARGB(255, 151, 151, 113)),
    8: BallTemplate(8, 6, const Color.fromARGB(255, 145, 173, 158)),
    9: BallTemplate(9, 6.5, const Color.fromARGB(255, 104, 103, 137)),
  };

  BallTemplate(this.id, this.radius, this.color);

  static BallTemplate? random() {
    int tmp = Random().nextInt(BallTemplate.map.length - 1);
    return BallTemplate.map[tmp];
  }

  static BallTemplate? next(BallTemplate t) {
    return BallTemplate.map[t.id + 1];
  }

  static Color lastColor(BallTemplate t) {
    BallTemplate? tmp = map[t.id - 1];
    return tmp == null ? Colors.white : tmp!.color;
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
      p = Curves.easeOutBack.transform(p);
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
      paint.color = Color.lerp(fromTemplate!.color, toTemplate.color, p)!;
      body.fixtures.first.shape.radius =
          fromTemplate!.radius + (toTemplate.radius - fromTemplate!.radius) * p;
    }
  }

  Ball({
    required this.position,
    this.speed,
    this.fromTemplate,
    required this.toTemplate,
  });

  @override
  Body createBody() {
    paint.color = toTemplate.color;
    paint.shader = LinearGradient(
            colors: [BallTemplate.lastColor(toTemplate), toTemplate.color])
        .createShader(
            Rect.fromCircle(center: Offset.zero, radius: toTemplate.radius));
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

class BloomParticle {
  final Forge2DGame gameRef;

  BloomParticle(this.gameRef);

  static final List<Color> bloomColors = [
    Colors.amberAccent,
    Colors.pink,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.deepOrange,
  ];

  static final Random rnd = Random();

  double randomSpeed(double radius) => (2 + rnd.nextDouble() * 1) * radius;

  double randomRadius(double radius) => (2 + rnd.nextDouble() * 1) * radius;

  double randomAngle(double angle) => angle + rnd.nextDouble() * pi / 6;

  double randomTime(double radius) => 200 + rnd.nextDouble() * 0.5;

  int randomCount(double radius) => 6 + rnd.nextInt(4) + (radius ~/ 2);

  Color randomColor(double radius) =>
      bloomColors[(radius ~/ 2) % bloomColors.length];

  void show(Vector2 position, double radius) {
    final n = randomCount(radius);
    final color = randomColor(radius);
    gameRef.add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: n,
          lifespan: randomTime(radius),
          generator: (i) {
            final angle = randomAngle((2 * pi / n) * i);
            return generate(
              position: position,
              angle: Vector2(sin(angle), cos(angle)),
              radius: randomRadius(radius),
              speed: randomSpeed(radius),
              color: color,
            );
          },
        ),
      ),
    );
  }

  AcceleratedParticle generate({
    required Vector2 position,
    required Vector2 angle,
    required double speed,
    required double radius,
    required Color color,
  }) {
    return AcceleratedParticle(
      position: position,
      speed: angle * speed,
      acceleration: angle * radius,
      child: ComputedParticle(
        renderer: (canvas, particle) => canvas.drawCircle(
          Offset.zero,
          particle.progress * 5,
          Paint()
            ..color = Color.lerp(
              color,
              Colors.white,
              particle.progress * 0.1,
            )!,
        ),
      ),
    );
  }
}
