package gif;

import haxe.io.UInt8Array;

interface IPaletteQuantizer
{
    /* Analyze pixels and return a quantized palette */
    function buildPalette(pixels:UInt8Array):UInt8Array;

    /* Map rgb to index into the quantized palette */
    function map(r:Int, g:Int, b:Int):Int;
}