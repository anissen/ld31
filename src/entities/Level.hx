
package entities;

import components.*;

import luxe.Entity;
import luxe.Input;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.Visual;
import phoenix.geometry.LineGeometry;
import luxe.options.GeometryOptions.LineGeometryOptions;
import luxe.Vector;
import luxe.Color;

import structures.LetterFrequencies;
import structures.LevelGrid;

enum Direction {
    None;
    Up;
    Down;
    Left;
    Right;
}

class Level extends Entity {
    var letterFrequencies :LetterFrequencies;
    var wordlist :Map<String, Int>;
    var word :String = "";
    var grid :LevelGrid; // TODO: Move this to a its own class
    var tilesX = 12;
    var tilesY = 7;
    var tileSize = 80;
    var startingLetterCount = 10;

    var cursor :Visual;
    var direction :Direction;
    var currentWord :String;

    public function new() {
        super({ name: 'Level' });

        letterFrequencies = new LetterFrequencies();
        grid = new LevelGrid(tilesX, tilesY, tileSize);
    }

    override function init() {
        wordlist = new Map<String, Int>();
        for (word in Main.words) {
            wordlist.set(word, 0);
        }

        currentWord = "";
        setDirection(Right);

        grid.reset();

        for (cell in grid.tiles()) {
            Luxe.draw.box({
                x: cell.x * tileSize,
                y: cell.y * tileSize,
                w: tileSize,
                h: tileSize,
                color: new Color(0.2 + 0.1 * Math.random(), 0.2 + 0.1 * Math.random(), 0.2 + 0.1 * Math.random(), 1) // new ColorHSV(255 * Math.random(), 0.5, 0.5)
            });
        }

        var startingLetters = [ for (i in 0 ... startingLetterCount) getRandomLetter() ];
        startingLetters.sort(function(a :String, b :String) {
            if (a < b) return -1;
            if (a > b) return 1;
            return 0;
        });
        for (i in 0 ... startingLetterCount) {
            var letter = startingLetters[i];
            var charCode = letter.charCodeAt(0) - "A".charCodeAt(0);
            var circle = new Visual({
                pos: new Vector((i + 0.5) * tileSize, (tilesY + 0.5) * tileSize),
                color: new ColorHSV(charCode * 10, 0.5, 1),
                geometry: Luxe.draw.circle({
                    r: tileSize / 2
                })
            });
            new Text({
                text: letter,
                color: new ColorHSV(charCode * 10, 0.1, 1),
                align: center, 
                align_vertical: center,
                point_size: 36,
                parent: circle
            });
        }

        var startX = 1;
        var startY = 3;
        cursor = new Visual({
            pos: new Vector((startX + 0.5) * tileSize, (startY + 0.5) * tileSize),
            color: new ColorHSV(30, 0.7, 1), 
            geometry: Luxe.draw.ngon({
                sides: 3,
                r: tileSize / 2,
                angle: 270,
                solid: true
            })
        });
        trace(cursor.geometry.vertices);
        cursor.geometry.vertices[2].color = new ColorHSV(60, 0.7, 1);
    }

    function getRandomLetter() :String {
        return letterFrequencies.randomLetter();
    }

    public function reset() {
        init();
    }

    override function onkeyup(e :KeyEvent) {
        switch (e.keycode) {
            case Key.up:    setDirection(Up);
            case Key.down:  setDirection(Down);
            case Key.left:  setDirection(Left);
            case Key.right: setDirection(Right);
            case Key.backspace: eraseLetter();
            case Key.enter: tryWord();
            case Key.escape: abortWord();
            case Key.key_a: enterLetter("A");
            case Key.key_b: enterLetter("B");
            case Key.key_c: enterLetter("C");
            case Key.key_d: enterLetter("D");
            case Key.key_e: enterLetter("E");
            case Key.key_f: enterLetter("F");
            case Key.key_g: enterLetter("G");
            case Key.key_h: enterLetter("H");
            case Key.key_i: enterLetter("I");
            case Key.key_j: enterLetter("J");
            case Key.key_k: enterLetter("K");
            case Key.key_l: enterLetter("L");
            case Key.key_m: enterLetter("M");
            case Key.key_n: enterLetter("N");
            case Key.key_o: enterLetter("O");
            case Key.key_p: enterLetter("P");
            case Key.key_q: enterLetter("Q");
            case Key.key_r: enterLetter("R");
            case Key.key_s: enterLetter("S");
            case Key.key_t: enterLetter("T");
            case Key.key_u: enterLetter("U");
            case Key.key_v: enterLetter("V");
            case Key.key_w: enterLetter("W");
            case Key.key_x: enterLetter("X");
            case Key.key_y: enterLetter("Y");
            case Key.key_z: enterLetter("Z");
        }
    }

    function setDirection(_direction :Direction) {
        direction = _direction;
        var angle = switch (direction) {
            case None:  0;
            case Up:    -90;
            case Down:  90;
            case Left:  180;
            case Right: 0;
        };
        Actuate
            .tween(cursor, 0.5, { rotation_z: angle });
    }

    function enterLetter(letter :String) {
        currentWord += letter;
        trace('enterLetter: $currentWord');
    }

    function eraseLetter() {
        currentWord = currentWord.substr(0, currentWord.length - 1);
        trace('eraseLetter: $currentWord');
    }

    function tryWord() {
        trace('tryWord: $currentWord');
    }

    function abortWord() {
        trace('abortWord: $currentWord');
        currentWord = "";
    }

} //Level
