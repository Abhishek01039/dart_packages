import 'package:state_queue/state_queue.dart';
import 'package:state_queue_test/state_queue_test.dart';
import 'package:test/test.dart';

class _TestBloc extends StateQueue<int> {
  _TestBloc() : super(0);

  void incr() {
    run((state) async* {
      yield state + 1;
    });
  }

  void decr() {
    run((state) async* {
      yield state - 1;
    });
  }
}

void main() {
  test('Forwards exception from `build`', () {
    expect(
      () async {
        await runBlocTest<_TestBloc, int>(
          build: () => throw Exception('Build failure'),
        );
      },
      // ignore: avoid_annotating_with_dynamic
      throwsA((dynamic e) => e.toString() == 'Exception: Build failure'),
    );
  });

  test('Forwards exception from `act`', () {
    expect(
      () async {
        await runBlocTest<_TestBloc, int>(
          build: () => _TestBloc(),
          act: (_) => throw Exception('Act failure'),
        );
      },
      // ignore: avoid_annotating_with_dynamic
      throwsA((dynamic e) => e.toString() == 'Exception: Act failure'),
    );
  });

  test('Errors with too many states', () {
    expect(
      () async {
        await runBlocTest<_TestBloc, int>(
          build: () => _TestBloc(),
          expect: <int>[0, 1],
        );
      },
      throwsA(
        // ignore: avoid_annotating_with_dynamic
        (dynamic e) =>
            e is TestFailure && e.message!.contains('shorter than expected'),
      ),
    );
  });

  test('Errors with too few states', () {
    expect(
      () async {
        await runBlocTest<_TestBloc, int>(
          build: () => _TestBloc(),
          act: (b) {
            b
              ..incr()
              ..incr()
              ..incr();
          },
          expect: <int>[0, 1],
        );
      },
      throwsA(
        // ignore: avoid_annotating_with_dynamic
        (dynamic e) =>
            e is TestFailure && e.message!.contains('longer than expected'),
      ),
    );
  });

  test('Errors with wrong states', () {
    expect(
      () async {
        await runBlocTest<_TestBloc, int>(
          build: () => _TestBloc(),
          act: (b) {
            b.incr();
          },
          expect: <int>[0, 7],
        );
      },
      throwsA(
        // ignore: avoid_annotating_with_dynamic
        (dynamic e) =>
            e is TestFailure &&
            e.message!.contains('at location [1] is <1> instead of <7>'),
      ),
    );
  });

  blocTest<_TestBloc, int>(
    'Increment state when incr is called',
    build: () => _TestBloc(),
    act: (bloc) => bloc..incr(),
    expect: <int>[0, 1],
  );

  blocTest<_TestBloc, int>(
    'Decrement state when decr is called',
    build: () => _TestBloc(),
    act: (bloc) => bloc..decr(),
    expect: <int>[0, -1],
  );
}
