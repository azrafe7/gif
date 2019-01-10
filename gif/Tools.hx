package gif;

import haxe.io.UInt8Array;

class Tools
{

  public function new() { }

  static public function histogram(pixels:UInt8Array):{ colorCounts:Map<Int, Int>, length:Int } {
    var colorCounts = new Map();
    var rgb = 0;
    var uniqueColors = 0;
    for (i in 0...Std.int(pixels.length / 3)) {
      var pos = i * 3;
      rgb = pixels[pos] | pixels[pos + 1] | pixels[pos + 2];
      if (!colorCounts.exists(rgb)) {
        colorCounts[rgb] = 1;
        uniqueColors++;
      } else {
        colorCounts[rgb]++;
      }
    }
    return { colorCounts: colorCounts, length: uniqueColors };
  }
}