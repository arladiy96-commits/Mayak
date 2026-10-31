import 'package:flutter_test/flutter_test.dart';
import 'package:mayak/main.dart';

void main() {
  test('TripPlan survives storage round trip', () {
    final plan = TripPlan(
      id: 'demo',
      isDriver: true,
      from: 'Бесколь',
      to: 'Петропавловск',
      departure: DateTime(2027, 1, 2, 9, 30),
      seats: 3,
      price: 2000,
      note: 'Заеду по пути',
    );

    final restored = TripPlan.fromJson(plan.toJson());
    expect(restored.from, 'Бесколь');
    expect(restored.to, 'Петропавловск');
    expect(restored.seats, 3);
    expect(restored.price, 2000);
    expect(restored.note, 'Заеду по пути');
  });
}
