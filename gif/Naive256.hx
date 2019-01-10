package gif;

import haxe.io.UInt8Array;


/** Analyze pixels' colors and build the color table.
    Does no color-quantization/palette-reduction, naively maps different pixel colors to an index
    (assuming unique colors to be <= 256). */
class Naive256 implements IPaletteQuantizer
{
    var rgbToIndex:Map<Int, Int>; // maps rgb to quantized palette index


    public function new() { }

    public function buildPalette(pixels:UInt8Array):UInt8Array
    {
        rgbToIndex = new Map<Int, Int>(); // maps rgb to index
        var indexToRgb = []; // reverse look-up

        // analyze pixels
        var nextIndex = 0;
        var k = 0;
        for (i in 0...Std.int(pixels.length / 3))
        {
            var rgb = (pixels[k++] << 16) | (pixels[k++] << 8) | pixels[k++];
            var index = rgbToIndex[rgb];
            if (index == null) {
                index = nextIndex++;
                rgbToIndex[rgb] = index;
                indexToRgb[index] = rgb;
            }
        }

        var colorTab = new UInt8Array(nextIndex * 3);

        // build color table
        k = 0;
        if (indexToRgb.length > 256) throw "More than 256 unique colors (" + indexToRgb.length + " found)";
        for (rgb in indexToRgb) {
            colorTab[k++] = (rgb >> 16) & 0xFF;
            colorTab[k++] = (rgb >> 8) & 0xFF;
            colorTab[k++] = rgb & 0xFF;
        }

        return colorTab;
    }

    public function map(r:Int, g:Int, b:Int):Int
    {
        var rgb = r << 16 | g << 8 | b;
        return rgbToIndex[rgb];
    }
}
