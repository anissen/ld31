
package states;

import luxe.Color;
import luxe.Component;
import luxe.Entity;
import luxe.options.TextOptions;
import luxe.Rectangle;
import luxe.Scene;
import luxe.Sprite;
import luxe.States;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;
import luxe.Input;

typedef ButtonOptions = {

    > luxe.options.TextOptions,

        /** Callback on click */
    @:optional var callback :Void -> Void;

}

class Button extends Text {
    var callback :Void -> Void;
    var background :Sprite;
    var height :Float;
    var width :Float;
    var mouse_over :Bool = false;

    public function new(_options: ButtonOptions) {
        var options = _options;
        if (options.align == null) options.align = TextAlign.center;
        if (options.align_vertical == null) options.align_vertical = TextAlign.center;
        if (options.point_size == null) options.point_size = 32;
        height = 80;
        width = Luxe.screen.w;

        super(options);
        callback = _options.callback;
    }

    override function init() {
        background = new Sprite({
            parent: this,
            texture: Luxe.loadTexture('assets/images/track_straight_rotated.png'),
            uv: new Rectangle(0, 0, Luxe.screen.w * (128/80), 128),
            size: new Vector(width, height),
            origin: new Vector(width / 2, height / 2),
            color: new Color(255, 255, 255, 0.05)
        });
        background.texture.clamp = repeat;
    }

    override function update(dt :Float) {
        if (mouse_over) {
            background.uv.x += 10 * dt;
        }
    }

    override function onmousemove(e: MouseEvent) {
        if (callback == null) return; // button is disabled

        if (!mouse_over && Luxe.utils.geometry.point_in_geometry(e.pos, background.geometry)) {
            mouse_over = true;
            background.color.tween(0.5, { a: 0.4 }).ease(luxe.tween.easing.Quad.easeInOut);
        } else if (mouse_over && !Luxe.utils.geometry.point_in_geometry(e.pos, background.geometry)) {
            mouse_over = false;
            background.color.tween(0.5, { a: 0.05 }).ease(luxe.tween.easing.Quad.easeInOut);
        }
    }

    override function onmousedown(e: MouseEvent) {
        if (callback == null) return; // button is disabled

        if (Luxe.utils.geometry.point_in_geometry(e.pos, background.geometry))
            callback();
    }
}

class MenuScreenState extends State {
    var scene :Scene;
    var titleText :Text;
    var background :Visual;

    public function new() {
        super({ name: 'MenuScreenState' });
        scene = new Scene('MenuScreenScene');
    }

    override function init() {
        trace("INIT MenuScreenState");
    }

    override function onenter<T>(_value :T) {
        trace("ENTER MenuScreenState");

        background = new Visual({
            pos: new Vector(-Luxe.screen.w, 0),
            size: Luxe.screen.size.clone(),
            color: new ColorHSV(200, 1, 0.1),
            scene: scene
        });

        titleText = new Text({
            pos: new Vector(Luxe.screen.w / 2, 100),
            text: 'Train of Thought',
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            point_size: 46,
            scene: scene,
            parent: background
        });

        var buttonOptions :Array<{ text :String, description :String, options :entities.Level.LevelOptions }> = [
        {
            text: 'Easy',
            description: 'Slow train, letters easier to match',
            options: {
                train_wait: 60,
                train_move_interval: 5,
                min_vowels: 4,
                min_consonants: 6,
                allow_repeated_words: true
            }
        },
        {
            text: 'Medium',
            description: '',
            options: {
                train_wait: 30,
                train_move_interval: 3,
                min_vowels: 3,
                min_consonants: 5,
                allow_repeated_words: false
            }
        },
        {
            text: 'Hard',
            description: 'Faster train, no help with letters',
            options: {
                train_wait: 15,
                train_move_interval: 1.5,
                min_vowels: 0,
                min_consonants: 0,
                allow_repeated_words: false
            }
        }];
        var yPos = 250;
        for (opts in buttonOptions) {
            var button = new Button({
                text: opts.text, 
                pos: new Vector(Luxe.screen.w / 2, yPos), 
                size: new Vector(Luxe.screen.w, 50),
                scene: scene,
                callback: function () {
                    Main.states.set('PlayScreenState', opts.options);
                }
            });
            button.transform.parent = background.transform;

            yPos += 90;
        }

        Actuate.tween(background.pos, 0.5, { x: 0 });
    }

    function play(options :entities.Level.LevelOptions) {
        Main.states.set('PlayScreenState', options);
    }

    override function onleave<T>(_value :T) {
        trace("LEAVE MenuScreenState");
        Actuate
            .tween(background.pos, 0.5, { x: Luxe.screen.w })
            .onComplete(function() {
                scene.empty();    
            });
    }
}
