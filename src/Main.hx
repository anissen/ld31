
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

    override function ready() {
        // Luxe.renderer.clear_color.rgb(0xfdfffc);

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

        level = new Level();
    }

} //Main
