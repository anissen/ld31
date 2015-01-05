
package entities;

import luxe.Entity;
import luxe.Visual;
import luxe.Text;
import luxe.options.TextOptions;
import luxe.Color;
import luxe.Vector;
import luxe.NineSlice;
import luxe.tween.Actuate;

import entities.Word;

class SpeechBubble extends NineSlice {
    var sx : Int = 500;
    var sy : Int = 260;
    var text :luxe.Text;

    public function new(_target :Entity) {
        super({
            name: 'SpeechBubble',
            name_unique: true,
            texture: Luxe.resources.find_texture('assets/images/speech_bubble.png'),
            top: 10,
            left: 10,
            right: 10,
            bottom: 10,
            pos: get_corrected_pos(_target.pos),
            color: new Color(170/255,121/255,66/255,1),
            depth: 100
        });
        _target.transform.listen_pos(function(v) {
            this.pos = get_corrected_pos(v);
        });

        var unique_shader = Luxe.renderer.shaders.bitmapfont.shader.clone();
        unique_shader.set_float('thickness', 1);
        unique_shader.set_float('smoothness', 0.8);
        unique_shader.set_float('outline', 0.75);
        unique_shader.set_vector4('outline_color', new Vector(0,0,0,1));

        text = new Text({
            text: '',
            pos: new Vector(15, 35),
            font: Luxe.resources.find_font("rail"),
            shader: unique_shader,
            color: new Color(1,1,1,1),
            align: TextAlign.left,
            align_vertical: TextAlign.center,
            point_size: 46,
            parent: this,
            depth: 101
        });

        this.visible = false;
        create(new Vector(), 40, 40);
    }

    function get_corrected_pos(v :Vector) :Vector {
        return Vector.Add(v, new Vector(20, -90));
    }

    function sizechange() {
        this.size = new Vector(sx, sy);
    }

    function resize(width :Float, height :Float, duration :Float = 0.4) {
        return Actuate.tween(this, duration, { sx: width, sy: height }, true).onUpdate(sizechange);
    }

    function hide() {
        text.text = '';
        Actuate.tween(this.color, 0.4, { a: 0 }, true).ease(luxe.tween.easing.Linear.easeNone);

        resize(40, 40).onComplete(function() {
            this.visible = false;
            text.visible = false;
        });
    }

    public function show(_text :String, _duration :Float = 5) {
        text.text = _text;
        Actuate.tween(this.color, 0.3, { a: 1 }, true).ease(luxe.tween.easing.Linear.easeNone);
        resize(30 + text.geom.text_width, 20 + text.geom.text_height, 0.8);
        this.visible = true;
        text.visible = true;

        Luxe.timer.schedule(_duration, hide);
    }
}
