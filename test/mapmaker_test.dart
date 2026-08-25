import 'package:flutter_test/flutter_test.dart';
import 'package:odd/ui/mapmaker_screen.dart';

void main() {
  test('paintGridRect fills an inclusive rectangle', () {
    const grid = [
      '.....',
      '.....',
      '.....',
      '.....',
    ];
    final next = paintGridRect(
      grid,
      col0: 1,
      row0: 1,
      col1: 3,
      row1: 2,
      tile: '#',
    );
    expect(next, const [
      '.....',
      '.###.',
      '.###.',
      '.....',
    ]);
  });

  test('paintGridRect works backwards and as a single cell', () {
    const grid = [
      '...',
      '...',
    ];
    expect(
      paintGridRect(grid, col0: 2, row0: 1, col1: 0, row1: 0, tile: 'I'),
      const [
        'III',
        'III',
      ],
    );
    expect(
      paintGridRect(grid, col0: 1, row0: 0, col1: 1, row1: 0, tile: 'C'),
      const [
        '.C.',
        '...',
      ],
    );
  });
}
