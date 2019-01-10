
import gif.GifEncoder;

using StringTools;

class Test {

    static var width = 32;
    static var height = 32;
    static var delay = .25;
    static var numFrames = 8;

    static var gradient:Array<Int> = Color.createGradient([0xFF0000, 0xFFFF00, 0xFF0000], [128, 128]);
    static var filenameTemplate:String = "test_0$0 $1.gif";

    static function main() {

        var testNum = 0;
        for (palette_analyzer in [
            GifPaletteAnalyzer.AUTO,
            GifPaletteAnalyzer.NEUQUANT(GifQuality.Best),
            GifPaletteAnalyzer.MEDIANCUT(256, false),
            GifPaletteAnalyzer.NAIVE256])
        {

            var output = new haxe.io.BytesOutput();
            var encoder = new gif.GifEncoder(width, height, 0, GifRepeat.Infinite, palette_analyzer);
            var analyzer_desc = "" + palette_analyzer;

            var filename = filenameTemplate.replace("$0", Std.string(testNum++)).replace("$1", analyzer_desc);
            trace('creating "' + filename + '" (' + numFrames + ' frames) ...');
            trace("frames size " + width + "x" + height + " ...");

            trace("using palette analyzer " + analyzer_desc + " ...");

            var t0 = haxe.Timer.stamp();

            encoder.start(output);

            //add `numFrames` frames
            for (i in 0...numFrames) encoder.add(output, make_frame());

            encoder.commit(output);

            trace("elapsed " + (haxe.Timer.stamp() - t0) + "s");

            var bytes = output.getBytes();

        #if (sys || nodejs)
            sys.io.File.saveBytes(filename, bytes);
        #elseif js
            var row = js.Browser.document.getElementById("container");
            var wrapperElement:js.html.DOMElement = cast js.Browser.document.createElement("span");
            wrapperElement.innerText = analyzer_desc;
            var imageElement:js.html.ImageElement = cast js.Browser.document.createElement("img");
            imageElement.src = 'data:image/gif;base64,' + haxe.crypto.Base64.encode(bytes);
            imageElement.setAttribute("width", Std.string(width * 3));
            row.appendChild(wrapperElement);
            wrapperElement.appendChild(imageElement);
        #else
            throw 'Unsupported platform for this test!';
        #end

            trace("done.\n");
        }
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
