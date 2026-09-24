import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The design's line glyphs, drawn on a 24×24 grid with round strokes.
enum LineGlyph {
  calendar([
    'M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v11A2.5 2.5 0 0 1 17.5 20h-11A2.5 2.5 0 0 1 4 17.5z',
    'M4 9.5h16', 'M8.5 4V2.8', 'M15.5 4V2.8',
    'M8.2 13.2h.01', 'M12 13.2h.01', 'M15.8 13.2h.01', 'M8.2 16.6h.01', 'M12 16.6h.01',
  ]),
  book([
    'M4 5.2A1.7 1.7 0 0 1 5.7 3.5h9.6A1.7 1.7 0 0 1 17 5.2v15.3H5.7A1.7 1.7 0 0 1 4 18.8z',
    'M17 7.5h2.3a.7.7 0 0 1 .7.7v10.6a1.7 1.7 0 0 1-1.7 1.7H17',
    'M7.4 7.8h6', 'M7.4 11.3h6', 'M7.4 14.8h3.6',
  ]),
  heart(['M12 20.2s-7.6-4.6-7.6-9.8A4.4 4.4 0 0 1 12 7.3a4.4 4.4 0 0 1 7.6 3.1c0 5.2-7.6 9.8-7.6 9.8z']),
  user([
    'M12 11.6a3.8 3.8 0 1 0 0-7.6 3.8 3.8 0 0 0 0 7.6z',
    'M4.8 20.2c.6-3.6 3.6-5.9 7.2-5.9s6.6 2.3 7.2 5.9',
  ]),
  filter(['M4 6.5h16', 'M7 12h10', 'M10 17.5h4']);

  const LineGlyph(this.paths);
  final List<String> paths;
}

/// Renders a [LineGlyph] in [color]; [filled] also fills closed shapes (the
/// favourite heart).
class LineIcon extends StatelessWidget {
  const LineIcon(this.glyph, {super.key, required this.size, required this.color, this.filled = false, this.strokeWidth = 1.9});

  final LineGlyph glyph;
  final double size;
  final Color color;
  final bool filled;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final paths = glyph.paths.map((d) => '<path d="$d"/>').join();
    final svg = '<svg viewBox="0 0 24 24" fill="${filled ? 'currentColor' : 'none'}" stroke="currentColor" '
        'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">$paths</svg>';
    return SvgPicture.string(svg, width: size, height: size, theme: SvgTheme(currentColor: color));
  }
}
