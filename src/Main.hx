
import entities.Level;
import luxe.States;
import luxe.Parcel;
import luxe.ParcelProgress;
import states.*;

class Main extends luxe.Game {
    var level :Level;
    public static var words :Array<String>;
    public static var states :States;
    var step :Int = 0;

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

        states = new States({ name:'state_machine' });
        states.add(new TitleScreenState());
        states.add(new MenuScreenState());
        states.add(new PlayScreenState());

        // states.set('TitleScreenState');
        states.set('MenuScreenState');
    }

} //Main
