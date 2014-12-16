
package states;

import luxe.Color;
import luxe.Input.KeyEvent;
import luxe.Input.Key;
import luxe.Scene;
import luxe.States;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;

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
            pos: new Vector(Luxe.screen.w / 2, Luxe.screen.mid.y),
            text: 'This is the menu screen.\nPress Enter',
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            scene: scene,
            parent: background
        });

        Actuate.tween(background.pos, 0.5, { x: 0 });
    }

    override function onleave<T>(_value :T) {
        trace("LEAVE MenuScreenState");
        Actuate
            .tween(background.pos, 0.5, { x: Luxe.screen.w })
            .onComplete(function() {
                scene.empty();    
            });
    }

    override function onkeyup(e :KeyEvent) {
        if (e.keycode != Key.enter) return;
        Main.states.set('PlayScreenState');
    }
}
