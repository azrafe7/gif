
import gif.GifEncoder;

class Test {

    static var width = 32;
    static var height = 32;
    static var delay = 1;
    static var numFrames = 5;

    static function main() {

        trace("creating test.gif (" + numFrames + " frames) ...");
        trace("frames' size " + width + "x" + height + " ...");

        var output = new haxe.io.BytesOutput();
        var palette_analyzer = GifPaletteAnalyzer.AUTO;
        var encoder = new gif.GifEncoder(width, height, 1, GifRepeat.Infinite, palette_analyzer);
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
        throw 'Unsupported platform!';
    #end

        trace("done.");

    } //main

    static var count = 0;
    static function make_frame() {

        var val   = 255;
        var red   = count % 3 == 0 ? val : 0; // Std.random(255);
        var green = count % 3 == 1 ? val : 0; // Std.random(255);
        var blue  = count % 3 == 2 ? val : 0; // Std.random(255);
        count++;

        //var red   = Std.random(255);
        //var green = Std.random(255);
        //var blue  = Std.random(255);

        var pixels = new haxe.io.UInt8Array(width * height * 3);
        for(i in 0 ... width * height) {
            pixels[i * 3 + 0] = red;
            pixels[i * 3 + 1] = green;
            pixels[i * 3 + 2] = blue;
        }

        var frame: GifFrame = {
            delay: delay,
            flippedY: false,
            data: pixels
        }

        return frame;

    } //make_frame

} //Test
