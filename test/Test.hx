
import gif.GifEncoder;
import Color;
import gif.MedianCut;

class Test {

    static var width = 32;
    static var height = 32;
    static var delay = .25;
    static var numFrames = 8;

    static var gradient:Array<Int> = Color.createGradient([0xFF0000, 0xFFFF00, 0xFF0000], [128, 128]);

    static function main() {

        var pixels = [0xFF0000, 0xFFFFFF, 0x00FF00,
                      0xFF00FF, 0x0000FF, 0xFFFF00];
        var w = 3, h = 2;
        var mcq = new MedianCut(pixels, w, h);
        var maxcubes = 6;
        var colorMap = [for (c in 0...maxcubes) [0, 0, 0]];
        var numColors = mcq.medianCut(mcq.histogram, colorMap, maxcubes);
        trace(numColors);
        trace(colorMap);
        trace(mcq.histogram.copy().splice(0, numColors));
        for (i in 0...mcq.histogram.length) if (mcq.histogram[i] > 0) trace(i + ": " + mcq.histogram[i]);

        var map = new Map();
        for (i in 0...pixels.length) {
          var rgb15 = MedianCut.RGB24_TO_RGB15(pixels[i]);
          trace(rgb15);
          var colMapIdx = mcq.histogram[rgb15];
          map[pixels[i]] = colorMap[mcq.histogram[rgb15]];
          //trace(colorMap[colMapIdx]);
        }

        var s = "";
        for (k in map.keys()) {
          s += StringTools.hex(k, 6) + " => " + map[k] + "\n";
        }
        trace(s);

        //return;

        trace("creating test.gif (" + numFrames + " frames) ...");
        trace("frames size " + width + "x" + height + " ...");

        var output = new haxe.io.BytesOutput();
        var palette_analyzer = GifPaletteAnalyzer.MEDIANCUT(33);
        var encoder = new gif.GifEncoder(width, height, 0, GifRepeat.Infinite, palette_analyzer);
        var palette_analyzer_enum = palette_analyzer.match(GifPaletteAnalyzer.AUTO) ? " (" + @:privateAccess encoder.palette_analyzer_enum + ")" : "";

        trace("using palette analyzer " + palette_analyzer + palette_analyzer_enum + " ...");

        var t0 = haxe.Timer.stamp();

        encoder.start(output);

        //add `numFrames` frames
        for (i in 0...numFrames) encoder.add(output, make_frame());

        encoder.commit(output);

        trace("elapsed " + (haxe.Timer.stamp() - t0) + "s");

        var bytes = output.getBytes();

    #if (sys || nodejs)
        sys.io.File.saveBytes("test.gif", bytes);
    #elseif js
        var imageElement :js.html.ImageElement = cast js.Browser.document.createElement("img");
        js.Browser.document.body.appendChild(imageElement);
        imageElement.src = 'data:image/gif;base64,' + haxe.crypto.Base64.encode(bytes);
    #else
        throw 'Unsupported platform for this test!';
    #end

        trace("done.");

    } //main

    static var count = 0;
    static function make_frame() {

        var red   = 0;
        var green = 0;
        var blue  = 0;

        var pixels = new haxe.io.UInt8Array(width * height * 3);
        var gradientLength = gradient.length;
        for(i in 0 ... width * height) {
            var idx = Std.int(i * gradientLength / (height * width));
            red   = (gradient[idx] >> 16) & 0xFF;
            green = (gradient[idx] >> 8) & 0xFF;
            blue  = (gradient[idx]) & 0xFF;
            pixels[i * 3 + 0] = red;
            pixels[i * 3 + 1] = green;
            pixels[i * 3 + 2] = blue;
        }

        count++;
        var head = gradient.splice(0, Std.int(gradientLength / numFrames));
        gradient = gradient.concat(head);

        var frame: GifFrame = {
            delay: delay,
            flippedY: false,
            data: pixels
        }

        return frame;

    } //make_frame

} //Test
