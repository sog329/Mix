import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flame/particles.dart';

void main() {
  runApp(GameWidget(game: Forge2DExample()));
}

class Forge2DExample extends Forge2DGame with HasTappables {
  @override
  Future<void> onLoad() async {
    BallTemplate? t = BallTemplate.random();
    if (t != null) {
      add(Ball(position: size / 2, template: t));
    }
    addAll(createBoundaries());
    world.setContactListener(BallContact(this));
    world.setGravity(world.gravity * 5);
    return super.onLoad();
  }

  @override
  void onTapUp(pointerId, info) {
    super.onTapUp(pointerId, info);

    BallTemplate? t = BallTemplate.random();
    if (t != null) {
      add(Ball(position: info.eventPosition.game, template: t));
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
}

class BallContact extends ContactListener {
  final Forge2DGame gameRef;

  BallContact(this.gameRef);

  @override
  void beginContact(Contact contact) {
    Object? a = contact.bodyA.userData;
    Object? b = contact.bodyB.userData;
    if (a is Ball && b is Ball) {
      if (a.template.radius == b.template.radius) {
        Vector2 p = contact.bodyA.position.y < contact.bodyB.position.y
            ? contact.bodyA.position
            : contact.bodyB.position;
        gameRef.remove(a);
        gameRef.remove(b);
        BallTemplate nowTemplate = a.template;
        BallTemplate? nextTemplate = BallTemplate.next(a.template);
        if (nextTemplate != null) {
          Ball ball = Ball(position: p, template: nextTemplate);
          gameRef.add(ball);
          gameRef.add(
            ParticleSystemComponent(
              position: contact.bodyA.position,
              particle: CircleParticle(
                radius: nowTemplate.radius,
                paint: Paint()..color = nowTemplate.color.withOpacity(.2),
              ),
            ),
          );
          gameRef.add(
            ParticleSystemComponent(
              position: contact.bodyB.position,
              particle: CircleParticle(
                radius: nowTemplate.radius,
                paint: Paint()..color = nowTemplate.color.withOpacity(.2),
              ),
            ),
          );
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
    0: BallTemplate(0, 2, Colors.accents[0]),
    1: BallTemplate(1, 2.5, Colors.accents[1]),
    2: BallTemplate(2, 3, Colors.accents[2]),
    3: BallTemplate(3, 3.5, Colors.accents[3]),
    4: BallTemplate(4, 4, Colors.accents[4]),
    5: BallTemplate(5, 4.5, Colors.accents[5]),
    6: BallTemplate(6, 5, Colors.accents[6]),
    7: BallTemplate(7, 5.5, Colors.accents[7]),
    8: BallTemplate(8, 6, Colors.accents[8]),
    9: BallTemplate(9, 6.5, Colors.accents[9]),
  };

  BallTemplate(this.id, this.radius, this.color);

  static BallTemplate? random() {
    int tmp = Random().nextInt(BallTemplate.map.length - 1);
    return BallTemplate.map[tmp];
  }

  static BallTemplate? next(BallTemplate t) {
    return BallTemplate.map[t.id + 1];
  }
}

class Ball extends BodyComponent with Tappable {
  final Vector2 position;
  final BallTemplate template;

  Ball({required this.position, required this.template}) {
    paint.color = template.color;
  }

  @override
  Body createBody() {
    final shape = CircleShape();
    shape.radius = template.radius;

    return world.createBody(BodyDef(
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
  }

  @override
  bool onTapUp(info) {
    // body.applyLinearImpulse(Vector2.random() * 5000);
    return super.onTapUp(info);
  }
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
