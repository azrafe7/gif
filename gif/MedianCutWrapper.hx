package gif;

import haxe.io.Int32Array;
import haxe.io.UInt8Array;

class MedianCutWrapper implements IPaletteAnalyzer {

    var maxColors:Int;

    var rgbMap:Map<Int, Int>;
    var rgb2index = new Map<Int, Int>(); // maps rgb to index

    public function new(?maxColors:Int)
    {
        this.maxColors = (maxColors != null) ? maxColors : 256;
        if (this.maxColors < 1 || this.maxColors > 256) throw "maxColors must be in the range [1-256]";
    }

    public function analyze(pixels:UInt8Array):UInt8Array
    {
        var pixelCount = Std.int(pixels.length / 3);
        var pixelArray:Array<Int> = [];
        for (i in 0...pixelCount) {
          var pos = i * 3;
          pixelArray[i] = (pixels[pos] << 16) | (pixels[pos + 1] << 8) | pixels[pos + 2];
        }
        var mcq = new MedianCut(pixelArray, pixelCount, 1);
        var colorMap = [for (c in 0...maxColors) [0, 0, 0]];
        var numColors = MedianCut.medianCut(mcq.histogram, colorMap, maxColors);
        //trace(numColors);
        //trace(colorMap);
        //trace(mcq.histogram.copy().splice(0, numColors));
        //for (i in 0...mcq.histogram.length) if (mcq.histogram[i] > 0) trace(i + ": " + mcq.histogram[i]);

        rgbMap = new Map();
        rgb2index = new Map();
        var originalUniqueColors = 0;
        for (i in 0...pixelArray.length) {
          var rgb15 = MedianCut.RGB24_TO_RGB15(pixelArray[i]);
          //trace(rgb15);
          var colMapIdx = mcq.histogram[rgb15];
          var mappedRgb = colorMap[colMapIdx];
          var rgb = (mappedRgb[0] << 16) | (mappedRgb[1] << 8) | mappedRgb[2];
          if (!rgbMap.exists(pixelArray[i])) originalUniqueColors++;
          rgbMap[pixelArray[i]] = rgb;
          rgb2index[pixelArray[i]] = colMapIdx;
          //trace(colorMap[colMapIdx]);
        }

        trace(colorMap.length);
        var colorTab = new UInt8Array(colorMap.length * 3);
        var paletteUniqueColors = 0;
        for (i in 0...colorMap.length) {
          if (colorMap[i].join("") != "000") paletteUniqueColors++;
          var pos = i * 3;
          colorTab[pos] = colorMap[i][0];
          colorTab[pos + 1] = colorMap[i][1];
          colorTab[pos + 2] = colorMap[i][2];
        }

        trace("unique " + paletteUniqueColors + " / " + originalUniqueColors);

        return colorTab;
    }

    public function map(r:Int, g:Int, b:Int):Int
    {
        //var rgb15 = MedianCut.RGB24_TO_RGB15(r << 16 | g << 8 | b);
        //return rgbMap[rgb15];
        var rgb = r << 16 | g << 8 | b;
        return rgb2index[rgb];
    }
}
