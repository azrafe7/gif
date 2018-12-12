package gif;

import haxe.io.UInt8Array;

interface IPaletteAnalyzer
{
    function analyze(thepic:UInt8Array):UInt8Array;
    function map(b:Int, g:Int, r:Int):Int;
}