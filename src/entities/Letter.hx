
package entities;

import luxe.Visual;
import luxe.Text;
import luxe.Color;
import luxe.Vector;

import entities.Word;

class Letter extends Visual {
    var text :Text;
    public var letter (default, null) :String;
    public var direction :Direction;
    public var gridPos :{ x :Int, y :Int };
    public var track :Visual;

    public function new(_options: { pos :Vector, r :Float, color :Color, letter :String, textColor :Color, borderColor :Vector  }) {
        super({
            name: 'Letter',
            name_unique: true,
            pos: _options.pos,
            color: _options.color,
            geometry: Luxe.draw.circle({
                r: _options.r
            })
        });

        var unique_shader = Luxe.renderer.shaders.bitmapfont.shader.clone();
        unique_shader.set_float('thickness', 1);
        unique_shader.set_float('smoothness', 0.8);
        unique_shader.set_float('outline', 0.75);
        unique_shader.set_vector4('outline_color', _options.borderColor);

        text = new Text({
            text: _options.letter,
            font: Luxe.resources.find_font("rail"),
            shader: unique_shader,
            color: _options.textColor,
            align: center,
            align_vertical: center,
            point_size: 46,
            parent: this
        });

        letter = _options.letter;
    }

    public function hide() {
        this.visible = false;
        text.visible = false;
    }
}
