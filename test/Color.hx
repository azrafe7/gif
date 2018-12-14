
class Color {

    static public function rgbToHsl(rgb:RGB):HSL {
        var r = rgb.r / 255.0, g = rgb.g / 255.0, b = rgb.b / 255.0;
        var max = Math.max(Math.max(r, g), b);
        var min = Math.min(Math.min(r, g), b);
        var d = max - min;
        var h = 0.0;
        if (d == 0) h = 0.0;
        else if (max == r) h = ((g - b) / d) % 6;
        else if (max == g) h = (b - r) / d + 2;
        else if (max == b) h = (r - g) / d + 4;
        var l = (min + max) / 2;
        var s = d == 0 ? 0 : d / (1 - Math.abs(2 * l - 1));
        return {h: (360 + h * 60) % 360, s: s, l: l};
    } // rgbToHsl

    static public function hslToRgb(hsl:HSL):RGB {
        var c = (1 - Math.abs(2 * hsl.l - 1)) * hsl.s;
        var hp = hsl.h / 60.0;
        var x = c * (1 - Math.abs((hp % 2) - 1));
        var rgb = null;
        if (Math.isNaN(hsl.h)) rgb = [0., 0, 0];
        else if (hp <= 1) rgb = [c, x, 0];
        else if (hp <= 2) rgb = [x, c, 0];
        else if (hp <= 3) rgb = [0, c, x];
        else if (hp <= 4) rgb = [0, x, c];
        else if (hp <= 5) rgb = [x, 0, c];
        else if (hp <= 6) rgb = [c, 0, x];
        var m = hsl.l - c * 0.5;
        return {
            r: Math.round(255 * (rgb[0] + m)),
            g: Math.round(255 * (rgb[1] + m)),
            b: Math.round(255 * (rgb[2] + m))
        };
    } // hslToRgb

    static public function intToRgb(rgb:Int):RGB {
        return {
            r: (rgb & 0xFF0000) >> 16,
            g: (rgb & 0x00FF00) >> 8,
            b: (rgb & 0x0000FF)
        };
    } // intToRgb

    static public function rgbToInt(rgb:RGB):Int {
        return (rgb.r << 16) | (rgb.g << 8) | rgb.b;
    } // rgbToInt

    static public function createGradient(rgbColors:Array<Int>, steps:Array<Int>):Array<Int> {
        var gradient = [];
        for(i in 0...rgbColors.length - 1) {
            var rgb = intToRgb(rgbColors[i]);
            var startHsl = rgbToHsl(rgb);
            rgb = intToRgb(rgbColors[i + 1]);
            var endHsl = rgbToHsl(rgb);

            var currSteps = steps[i];

            var diffH = (endHsl.h - startHsl.h) % 360;
            var shortestH = (2 * diffH) % 360 - diffH;
            var stepH = shortestH / (currSteps - 1);

            var stepS = (endHsl.s - startHsl.s) / (currSteps - 1);
            var stepL = (endHsl.l - startHsl.l) / (currSteps - 1);

            for(step in 0...currSteps)
            {
                var interpolatedHsl:Color.HSL = {
                    h: (360 + startHsl.h + (stepH * step)) % 360,
                    s: startHsl.s + (stepS * step),
                    l: startHsl.l + (stepL * step)
                };
                rgb = hslToRgb(interpolatedHsl);
                gradient.push(rgbToInt(rgb));
            }
        }

        return gradient;
    } // createGradient
} // Color

@:structInit
class RGB {
  public var r:Int; // [0, 255]
  public var g:Int; // [0, 255]
  public var b:Int; // [0, 255]
}

@:structInit
class HSL {
  public var h:Float; // [0, 360]
  public var s:Float; // [0, 1]
  public var l:Float; // [0, 1]
}