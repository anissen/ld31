
package entities;

import components.*;

import luxe.Entity;
import luxe.Input;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.tween.easing.Quad;
import luxe.Visual;
import phoenix.geometry.LineGeometry;
import luxe.options.GeometryOptions.LineGeometryOptions;
import luxe.Vector;
import luxe.Color;

import structures.LetterFrequencies;
import structures.LevelGrid;

enum Direction {
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

    var letters :Array<Letter>;
    var cursor :Visual;
    var enteringWord :Bool;
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

        letters = new Array<Letter>();
        enteringWord = false;
        currentWord = "";
        setDirection(Right);

        grid.reset();

        for (cell in grid.tiles()) {
            Luxe.draw.box({
                x: cell.x * tileSize,
                y: cell.y * tileSize,
                w: tileSize,
                h: tileSize,
                color: new Color(0.2 + 0.05 * Math.random(), 0.2 + 0.05 * Math.random(), 0.2 + 0.05 * Math.random(), 1) // new ColorHSV(255 * Math.random(), 0.5, 0.5)
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
            letters.push(new Letter({
                pos: new Vector((i + 0.5) * tileSize, (tilesY + 0.5) * tileSize),
                color: new ColorHSV(charCode * 10, 0.5, 1),
                r: tileSize / 2,
                letter: letter,
                textColor: new ColorHSV(charCode * 10, 0.1, 1)
            }));
        }

        var startX = 1;
        var startY = 3;
        cursor = new Visual({
            pos: new Vector((startX + 0.5) * tileSize, (startY + 0.5) * tileSize),
            color: new ColorHSV(30, 0.7, 1, 0.5), 
            geometry: Luxe.draw.ngon({
                sides: 3,
                r: tileSize / 2,
                angle: 270,
                solid: true
            })
        });
        cursor.geometry.vertices[2].color = new ColorHSV(60, 0.7, 1, 0.8);
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
        if (enteringWord) return;

        direction = _direction;
        var angle = switch (direction) {
            case Up:    -90;
            case Down:  90;
            case Left:  180;
            case Right: 0;
        };
        Actuate
            .tween(cursor, 0.5, { rotation_z: angle });
    }

    function findLetter(letter :String) :Null<Letter> {
        for (l in letters) {
            if (l.available && l.letter == letter) return l;
        }
        return null;
    }

    function enterLetter(letter :String) {
        var letterRep = findLetter(letter);
        if (letterRep == null) {
            this.events.fire('letter_missing', letter);
            return;   
        }

        startEnteringWord();
        currentWord += letter;
        cursor.pos.add(switch (direction) {
            case Up:    new Vector(0, -tileSize);
            case Down:  new Vector(0, tileSize);
            case Left:  new Vector(-tileSize, 0);
            case Right: new Vector(tileSize, 0);
        });
        letterRep.available = false;
        Actuate
            .tween(letterRep.pos, 0.5, { x: cursor.pos.x, y: cursor.pos.y });
        trace('enterLetter: $currentWord');
    }

    function eraseLetter() {
        currentWord = currentWord.substr(0, currentWord.length - 1);
        if (currentWord.length == 0) {
            enteringWord = false;
        }
        trace('eraseLetter: $currentWord');
    }

    function tryWord() {
        trace('tryWord: $currentWord');
        var word = currentWord.toLowerCase();

        if (!wordlist.exists(word)) {
            trace('$word is an invalid word!');
            this.events.fire('wrong_word', word);
            abortWord();
            return;
        }

        var timesUsed = wordlist.get(word);
        if (timesUsed > 0) {
            trace('$word has already been used!');
            this.events.fire('word_already_used', word);
            abortWord();
            return;   
        }

        wordlist.set(word, 1);
        
        trace('$word is a correct word!');
        
        var lettersToRemove = [];
        for (letter in letters) {
            if (!letter.available) {
                lettersToRemove.push(letter); // TODO: Is this dangerous?
            }
        }
        for (letter in lettersToRemove) {
            letters.remove(letter);
        }

        for (i in letters.length ... startingLetterCount) {
            letters.push(createNewLetter());
        }

        repositionLetters();

        currentWord = currentWord.substr(currentWord.length - 1); // start with the last letter of last word
        stopEnteringWord();
    }

    function createNewLetter() {
        var letter = getRandomLetter();
        var charCode = letter.charCodeAt(0) - "A".charCodeAt(0);
        return new Letter({
            pos: new Vector(tilesX * Math.random() * tileSize, tilesY * Math.random() * tileSize),
            color: new ColorHSV(charCode * 10, 0.5, 1),
            r: tileSize / 2,
            letter: letter,
            textColor: new ColorHSV(charCode * 10, 0.1, 1)
        });
    }

    function abortWord() {
        trace('abortWord: $currentWord');
        currentWord = "";
        stopEnteringWord();

        repositionLetters();
    }

    function repositionLetters() {
        var count = 0;
        for (letter in letters) {
            Actuate
                .tween(letter.pos, 0.5, { x: (count + 0.5) * tileSize, y: (tilesY + 0.5) * tileSize })
                .delay(0.05 * count)
                .onComplete(function() { letter.available = true; });
            count++;
        }
    }

    function startEnteringWord() {
        if (enteringWord) return;
        enteringWord = true;
        Actuate
            .tween(cursor.color, 0.3, { a: 0 })
            .ease(Quad.easeInOut);
    }

    function stopEnteringWord() {
        if (!enteringWord) return;
        enteringWord = false;
        Actuate
            .tween(cursor.color, 0.3, { a: 1 })
            .ease(Quad.easeInOut);
    }

} //Level
