
import entities.Level;
import luxe.Input;
import luxe.States;
import luxe.Text;
import luxe.Vector;
import luxe.Color;

import luxe.Parcel;
import luxe.ParcelProgress;
import states.*;

class Main extends luxe.Game {
    var level :Level;
    public static var words :Array<String>;
    public static var states :States;
    var step :Int = 0;
    var titleText :Text;
    var introText :Text;

    override function ready() {
        // Luxe.renderer.clear_color = new luxe.ColorHSV(0, 1, 0);

        var json_asset = Luxe.loadJSON("assets/parcel.json");

        var preload = new Parcel();
        preload.from_json(json_asset.json);

        new ParcelProgress({
            parcel      : preload,
            background  : Luxe.renderer.clear_color,
            oncomplete  : assets_loaded
        });

        preload.load();
    }

    function assets_loaded(_) {
        var wordList = Luxe.resources.find_text('assets/wordlists/en.txt');
        words = wordList.text.split("\n");

        luxe.tween.Actuate.defaultEase = luxe.tween.easing.Elastic.easeOut;

        states = new States({ name:'state_machine' });
        states.add(new TitleScreenState());
        states.add(new MenuScreenState());
        states.add(new PlayScreenState());

        states.set('TitleScreenState');

        /*
        var unique_shader = Luxe.renderer.shaders.bitmapfont.shader.clone();
        unique_shader.set_float('thickness', 1);
        unique_shader.set_float('smoothness', 0.8);
        unique_shader.set_float('outline', 0.75);
        unique_shader.set_vector4('outline_color', new Vector(0.0, 0.0, 0.0, 1.0));

        titleText = new Text({
            pos: Vector.Add(Luxe.screen.mid, new Vector(0, -100)),
            text: 'Train of Thought',
            font: Luxe.resources.find_font("rail"),
            shader: unique_shader,
            color: new ColorHSV(0, 0, 1),
            align: center,
            align_vertical: center,
            point_size: 64
        });

        introText = new Text({
            pos: Vector.Add(Luxe.screen.mid, new Vector(0, 100)),
            text: 'Press Enter for instructions',
            font: Luxe.resources.find_font("rail"),
            shader: unique_shader,
            color: new ColorHSV(0, 0, 0.6),
            align: center,
            align_vertical: center,
            point_size: 42
        });
        */
    }

    /*
    override function onkeyup(e :KeyEvent) {
        if (level != null) return;
        if (e.keycode != Key.enter) return;

        step++;
        var unique_shader = Luxe.renderer.shaders.bitmapfont.shader.clone(); // .font.shader.clone();
        unique_shader.set_float('thickness', 1);
        unique_shader.set_float('smoothness', 0.8);
        unique_shader.set_float('outline', 0.75);
        unique_shader.set_vector4('outline_color', new Vector(0.0, 0.0, 0.0, 1.0));
        if (step == 1) {
            titleText.destroy();
            introText.destroy();
            titleText = new Text({
                pos: Vector.Add(Luxe.screen.mid, new Vector(0, -200)),
                text: 'Instructions',
                font: Luxe.resources.find_font("rail"),
                shader: unique_shader,
                color: new ColorHSV(200, 0, 1),
                align: center,
                align_vertical: center,
                point_size: 64
            });

            introText = new Text({
                pos: Vector.Add(Luxe.screen.mid, new Vector(-80, -120)),
                text: '
                Type words to create a railway
                track to the station.

                But hurry before the train departs!

                - - -

                Press Enter for controls',
                font: Luxe.resources.find_font("rail"),
                shader: unique_shader,
                color: new ColorHSV(0, 0, 0.6),
                align: center,
                align_vertical: top,
                point_size: 42
            });
        } else if (step == 2) {
            titleText.destroy();
            introText.destroy();
            titleText = new Text({
                pos: Vector.Add(Luxe.screen.mid, new Vector(0, -200)),
                text: 'Controls',
                font: Luxe.resources.find_font("rail"),
                shader: unique_shader,
                color: new ColorHSV(100, 0, 1),
                align: center,
                align_vertical: center,
                point_size: 64
            });

            introText = new Text({
                pos: Vector.Add(Luxe.screen.mid, new Vector(-90, -150)),
                text: '
                Arrow keys - Move the cursor
                    A to Z - Type letters
                 Backspace - Erase last letter
                     Enter - Submit word
                    Escape - Scrap word

                - - -

                Press Enter to begin',
                font: Luxe.resources.find_font("rail"),
                shader: unique_shader,
                color: new ColorHSV(0, 0, 0.6),
                align: center,
                align_vertical: top,
                point_size: 42
            });
        } else {
            titleText.destroy();
            introText.destroy();
            level = new Level();
        }
    }
    */

} //Main
