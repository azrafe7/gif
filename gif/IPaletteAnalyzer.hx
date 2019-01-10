package gif;

import haxe.io.UInt8Array;

interface IPaletteAnalyzer
{
    function analyze(thepic:UInt8Array):UInt8Array;
    function map(r:Int, g:Int, b:Int):Int;
}