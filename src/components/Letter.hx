
package components;

import luxe.Visual;
import luxe.Text;
import luxe.Color;
import luxe.Vector;

class Letter extends Visual {
    var text :Text;
    public var available :Bool;
    public var letter (default, null) :String;

    public function new(_options: { pos :Vector, r :Float, color :Color, letter :String, textColor :Color }) {
        super({
            name: 'Letter',
            name_unique: true,
            pos: _options.pos,
            color: _options.color,
            geometry: Luxe.draw.circle({
                r: _options.r
            })
        });
        
        text = new Text({
            text: _options.letter,
            color: _options.textColor,
            align: center, 
            align_vertical: center,
            point_size: 36,
            parent: this
        });

        letter = _options.letter;
        available = true;
    }
}
