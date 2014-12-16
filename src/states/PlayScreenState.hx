
package states;

import entities.Level;
import luxe.Color;
import luxe.Input.KeyEvent;
import luxe.Input.Key;
import luxe.Scene;
import luxe.States;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;

class PlayScreenState extends State {
    var scene :Scene;
    var level :Level;

    public function new() {
        super({ name: 'PlayScreenState' });
        scene = new Scene('PlayScreenScene');
    }

    override function init() {
        trace("INIT PlayScreenState");
    }

    override function onenter<T>(_value :T) {
        trace("ENTER PlayScreenState");

        // level = new Level({
        //     options: {
        //         speed: 1,
        //         minimumVowels: 4,
        //         minimumConsonants: 4
        //     },
        //     scene: scene    
        // });
        level = new Level();
    }

    override function onleave<T>(_value :T) {
        trace("LEAVE PlayScreenState");
        scene.empty();    
    }

    // override function onkeyup(e :KeyEvent) {
    //     if (e.keycode != Key.enter) return;
    //     Main.states.set('PlayScreenState');
    // }
}
