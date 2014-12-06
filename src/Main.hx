
import entities.Level;
import luxe.Input;
import luxe.Text;
import luxe.Vector;
import luxe.Color;

import luxe.Parcel;
import luxe.ParcelProgress;

class Main extends luxe.Game {
    var level :Level;
    public static var words :Array<String>;
    var wordGuessText :Text;

    override function ready() {
        Luxe.renderer.clear_color.rgb(0xfdfffc);

        var json_asset = Luxe.loadJSON("assets/parcel.json");

        var preload = new Parcel();
        preload.from_json(json_asset.json);

        new ParcelProgress({
            parcel      : preload,
            background  : Luxe.renderer.clear_color,
            oncomplete  : assets_loaded
        });

        preload.load();

    } //ready

    function assets_loaded(_) {
        // var wordlist = Luxe.resources.find_text('assets/wordlists/en.txt');
        // trace('text length: ' + wordlist.text.length);

        var wordList = Luxe.resources.find_text('assets/wordlists/en.txt');
        words = wordList.text.split("\n");

        wordGuessText = new Text({
            // no_scene: true,
            text: "",
            pos: new Vector(Luxe.screen.w / 2, Luxe.screen.h - 100),
            color: new Color().rgb(0xffffff),
            point_size: 46,
            align: center, 
            align_vertical: center
        });

        level = new Level();
        level.events.listen('spelling_word', function(data: { word :String, correct :Bool, alreadyUsed :Bool }) {
            wordGuessText.scale.set_xy(1, 1);

            wordGuessText.text = data.word;
            wordGuessText.color.set(0, 0, 0);
            var color :Dynamic = (data.correct ? (data.alreadyUsed ? { r: 0, g: 0, b: 0.7 } : { r: 0, g: 0.7, b: 0 } ) : { r: 0.7, g: 0, b: 0 });
            wordGuessText.color
                .tween(0.2, color)
                .ease(luxe.tween.easing.Quad.easeInOut);
        });

        level.events.listen('guessed_word', function(data: { word :String, correct :Bool, alreadyUsed :Bool }) {
            luxe.tween.Actuate
                .tween(wordGuessText.scale, 0.3, { x: 0, y: 0 })
                .ease(luxe.tween.easing.Elastic.easeInOut);
        });
    }

    override function onkeyup(e :KeyEvent) {
        switch (e.keycode) {
            case Key.key_f: app.app.window.fullscreen = !app.app.window.fullscreen;
            case Key.key_r: level.reset();
            case Key.escape: Luxe.shutdown();
        }
    } //onkeyup

} //Main
