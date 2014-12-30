
import entities.Level;
import luxe.States;
import luxe.Parcel;
import luxe.ParcelProgress;
import states.*;

import luxe.Input;
import luxe.Color;
import luxe.Sprite;
import luxe.Vector;
import luxe.Text;

import phoenix.Batcher.BlendMode;
import phoenix.RenderTexture;
import phoenix.Texture;
import phoenix.Batcher;
import phoenix.Shader;

class Main extends luxe.Game {
    var level :Level;
    public static var words :Array<String>;
    public static var states :States;

    var final_output: RenderTexture;
    var final_batch: Batcher;
    var final_view: Sprite;
    var final_shader: Shader;

    override function ready() {
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

        setupRenderToTexture();

        states = new States({ name:'state_machine' });
        states.add(new TitleScreenState());
        states.add(new MenuScreenState());
        states.add(new PlayScreenState());

        // states.set('TitleScreenState');
        states.set('MenuScreenState');
    }

    function setupRenderToTexture() {
        final_output = new RenderTexture(Luxe.resources, Luxe.screen.size);
        final_batch = Luxe.renderer.create_batcher({ no_add: true });
        final_shader = Luxe.loadShader('assets/shaders/full.glsl');
        final_shader.set_vector2('resolution', Luxe.screen.size );
        final_view = new Sprite({
            centered : false,
            pos : new Vector(0,0),
            size : Luxe.screen.size,
            texture : final_output,
            shader : final_shader,
            batcher : final_batch
        });
    }

    override function onprerender() {
        if (final_output == null) return;

        final_shader.set_float('time', Luxe.time);
        Luxe.renderer.target = final_output;
        Luxe.renderer.clear(new Color(0,0,0,1));
    }

    override function onpostrender() {
        if (final_batch == null) return;

        Luxe.renderer.target = null;
        Luxe.renderer.clear(new Color(1,0,0,1));
        Luxe.renderer.blend_mode(BlendMode.src_alpha, BlendMode.zero);
        final_batch.draw();
        Luxe.renderer.blend_mode();
    }

    // override function onkeyup( e:KeyEvent ) {
    //     if (e.keycode == Key.key_s) {
    //         if(final_view.shader == final_shader) {
    //             final_view.shader = Luxe.renderer.shaders.textured.shader;
    //         } else {
    //             final_view.shader = final_shader;
    //         }
    //     }
    // }

} //Main
