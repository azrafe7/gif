package gif;

import haxe.io.UInt8Array;


/** Analyze pixels' colors and build the color table.
    Does no color-quantization/palette-reduction, naively maps different pixel colors to an index
    (assuming unique colors to be <= 256). */
class Naive256 implements IPaletteAnalyzer
{
    var indexedPixels:Array<Int> = [];
    var rgb2index = new Map<Int, Int>(); // maps rgb to index

    public function new() { }

    public function analyze(pixels:UInt8Array):UInt8Array
    {
        rgb2index = new Map<Int, Int>(); // maps rgb to index
        var index2rgb = []; // reverse look-up

        // analyze pixels
        var nextIndex = 0;
        var k = 0;
        for (i in 0...pixels.length)
        {
            var rgb = (pixels[k++] << 16) | (pixels[k++] << 8) | pixels[k++];
            var index = rgb2index[rgb];
            if (index == null) {
                index = nextIndex++;
                rgb2index[rgb] = index;
                index2rgb[index] = rgb;
            }
            indexedPixels[i] = index;
        }

        var colorTab = new UInt8Array(nextIndex * 3);

        // build color table
        k = 0;
        for (rgb in index2rgb) {
            colorTab[k++] = (rgb >> 16) & 0xFF;
            colorTab[k++] = (rgb >> 8) & 0xFF;
            colorTab[k++] = rgb & 0xFF;
        }

        return colorTab;
    }

    public function map(r:Int, g:Int, b:Int):Int
    {
        var rgb = r << 16 | g << 8 | b;
        return rgb2index[rgb];
    }
}
