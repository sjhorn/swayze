import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:swayze/src/widgets/shortcuts/shortcuts.dart';

class _MockHardwareKeyboard extends Mock implements HardwareKeyboard {}

void main() {
  group('AnyCharacterActivator', () {
    test('should reject any KeyUpEvent', () {
      const activator = AnyCharacterActivator();

      final hardwareKeyboard = _MockHardwareKeyboard();
      when(() => hardwareKeyboard.logicalKeysPressed)
          .thenReturn({LogicalKeyboardKey.keyA});

      expect(
        activator.accepts(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.keyA,
            logicalKey: LogicalKeyboardKey.keyA,
            timeStamp: Duration.zero,
          ),
          hardwareKeyboard,
        ),
        isFalse,
      );
    });

    test('should reject if character is null or empty', () {
      const activator = AnyCharacterActivator();

      final hardwareKeyboard = _MockHardwareKeyboard();
      when(() => hardwareKeyboard.logicalKeysPressed)
          .thenReturn({LogicalKeyboardKey.shift});

      expect(
        activator.accepts(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.shiftLeft,
            logicalKey: LogicalKeyboardKey.shiftLeft,
            timeStamp: Duration.zero,
          ),
          hardwareKeyboard,
        ),
        isFalse,
      );
    });

    test('should reject any arrow key', () {
      const activator = AnyCharacterActivator();
      final hardwareKeyboard = _MockHardwareKeyboard();
      const keyDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
        timeStamp: Duration.zero,
      );

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.arrowDown},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.arrowUp},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.arrowLeft},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.arrowRight},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);
    });

    test('should reject any control key', () {
      const activator = AnyCharacterActivator();
      final hardwareKeyboard = _MockHardwareKeyboard();
      const keyDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.shiftLeft,
        logicalKey: LogicalKeyboardKey.shiftLeft,
        timeStamp: Duration.zero,
      );

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.controlLeft},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.controlRight},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.metaLeft},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.metaRight},
      );
      expect(activator.accepts(keyDownEvent, hardwareKeyboard), isFalse);
    });

    test('should reject delete and fn+backspace', () {
      const activator = AnyCharacterActivator();
      final hardwareKeyboard = _MockHardwareKeyboard();
      const backspaceEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.backspace,
        logicalKey: LogicalKeyboardKey.backspace,
        timeStamp: Duration.zero,
      );
      const deleteEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.delete,
        logicalKey: LogicalKeyboardKey.delete,
        timeStamp: Duration.zero,
      );

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.backspace},
      );
      expect(activator.accepts(backspaceEvent, hardwareKeyboard), isFalse);

      when(() => hardwareKeyboard.logicalKeysPressed).thenReturn(
        {LogicalKeyboardKey.fn, LogicalKeyboardKey.delete},
      );
      expect(activator.accepts(deleteEvent, hardwareKeyboard), isFalse);
    });

    test('should accept if its a valid character', () {
      const activator = AnyCharacterActivator();
      final rawKeyboard = _MockHardwareKeyboard();
      when(() => rawKeyboard.logicalKeysPressed)
          .thenReturn({LogicalKeyboardKey.keyA});

      const keyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyA,
        logicalKey: LogicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
        character: 'a',
      );
      expect(activator.accepts(keyEvent, rawKeyboard), isTrue);
    });
  });
}
