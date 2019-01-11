package gif;

import haxe.io.UInt8Array;

class Tools
{

  public function new() { }

  static public function rgbHistogram(pixels:UInt8Array):{ colorCounts:Map<Int, Int>, length:Int } {
    var colorCounts = new Map();
    var rgb = 0;
    var uniqueColors = 0;
    for (i in 0...Std.int(pixels.length / 3)) {
      var pos = i * 3;
      rgb = (pixels[pos] << 16) | (pixels[pos + 1] << 8) | pixels[pos + 2];
      if (!colorCounts.exists(rgb)) {
        colorCounts[rgb] = 1;
        uniqueColors++;
      } else {
        colorCounts[rgb]++;
      }
    }
    return { colorCounts: colorCounts, length: uniqueColors };
  }

  static public function u8Histogram(values:UInt8Array):{ valueCounts:Map<Int, Int>, length:Int } {
    var valueCounts = new Map();
    var uniqueValues = 0;
    for (value in values) {
      if (!valueCounts.exists(value)) {
        valueCounts[value] = 1;
        uniqueValues++;
      } else {
        valueCounts[value]++;
      }
    }
    return { valueCounts: valueCounts, length: uniqueValues };
  }
}