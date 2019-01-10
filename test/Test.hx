
import gif.GifEncoder;
import Color;
import gif.MedianCut;

class Test {

    static var width = 32;
    static var height = 32;
    static var delay = .25;
    static var numFrames = 8;

    //static var paletteAnalyzer = GifPaletteAnalyzer.AUTO;
    static var palette_analyzer = GifPaletteAnalyzer.MEDIANCUT();
    //static var palette_analyzer = GifPaletteAnalyzer.NEUQUANT();
    //static var palette_analyzer = GifPaletteAnalyzer.NAIVE256;

    static var gradient:Array<Int> = Color.createGradient([0xFF0000, 0xFFFF00, 0xFF0000], [128, 128]);

    static function main() {

        trace("creating test.gif (" + numFrames + " frames) ...");
        trace("frames size " + width + "x" + height + " ...");

        var output = new haxe.io.BytesOutput();
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
