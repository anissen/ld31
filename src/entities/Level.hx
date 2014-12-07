
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
    var startingLetterCount = 12;

    var placedLetters :Array<Letter>;
    var availableLetters :Array<Letter>;
    var cursor :Visual;
    var cursorPos :{ x: Int, y :Int };
    var wordStartedAt :{ x: Int, y: Int };
    var enteringWord :Bool;
    var direction :Direction;
    var currentWord :String;
    var firstWord :Bool;

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

        placedLetters = new Array<Letter>();
        availableLetters = new Array<Letter>();
        enteringWord = false;
        currentWord = "";
        cursorPos = { x: 0, y: 0 };
        wordStartedAt = { x: 0, y: 0 };
        firstWord = true;

        grid.reset();

        for (cell in grid.tiles()) {
            var box = Luxe.draw.box({
                x: cell.pos.x - tileSize / 2,
                y: cell.pos.y - tileSize / 2,
                w: tileSize,
                h: tileSize,
                color: new Color(0.2 + 0.05 * Math.random(), 0.2 + 0.05 * Math.random(), 0.2 + 0.05 * Math.random(), 1) // new ColorHSV(255 * Math.random(), 0.5, 0.5)
            });
        }

        for (i in 0 ... startingLetterCount) {
            availableLetters.push(createNewLetter());
        }
        repositionLetters();

        var startX = 1;
        var startY = 3;
        cursorPos.x = startX;
        cursorPos.y = startY;
        cursor = new Visual({
            pos: grid.getPos(startX, startY),
            color: new ColorHSV(30, 0.7, 1, 0.5), 
            geometry: Luxe.draw.ngon({
                sides: 3,
                r: tileSize / 2,
                angle: 270,
                solid: true
            })
        });
        cursor.geometry.vertices[2].color = new ColorHSV(60, 0.7, 1, 0.8);

        setDirection(Right);

    }

    function getRandomLetter() :String {
        return letterFrequencies.randomLetter();
    }

    public function reset() {
        init();
    }

    override function onkeyup(e :KeyEvent) {
        switch (e.keycode) {
            // case Key.up:    setDirection(Up);
            // case Key.down:  setDirection(Down);
            // case Key.left:  setDirection(Left);
            // case Key.right: setDirection(Right);
            case Key.space: setDirection(switch (direction) {
                case Up: Right;
                case Right: Down;
                case Down: Left;
                case Left: Up;
            });
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
            case Right: 0;
            case Down:  90;
            case Left:  180;
            case Up:    270;
        }; 
        Actuate
            .tween(cursor, 0.5, { rotation_z: angle });
    }

    function findLetter(letter :String) :Null<Letter> {
        for (l in availableLetters) {
            if (l.letter == letter) return l;
        }
        return null;
    }

    function enterLetter(letter :String) {
        var letterRep = findLetter(letter);
        if (letterRep == null) {
            this.events.fire('letter_missing', letter);
            return;   
        }

        // this.events.fire('place_letter', letterRep);
        availableLetters.remove(letterRep);
        placedLetters.push(letterRep);

        repositionLetters();

        startEnteringWord();

        switch (direction) {
            case Up:    cursorPos.y -= 1;
            case Down:  cursorPos.y += 1;
            case Left:  cursorPos.x -= 1;
            case Right: cursorPos.x += 1;
        };

        currentWord += letter;
        var pos = grid.getPos(cursorPos.x, cursorPos.y);
        letterRep.gridPos = { x: cursorPos.x, y: cursorPos.y };
        Actuate
            .tween(letterRep.pos, 0.5, { x: pos.x, y: pos.y });
        Actuate
            .tween(cursor.pos, 0.5, { x: pos.x, y: pos.y });

        trace('enterLetter: $currentWord');
    }

    function eraseLetter() {
        if (currentWord.length == 0) return;

        // this.events.fire('remove_letter', letter);
        currentWord = currentWord.substr(0, currentWord.length - 1);
        if (currentWord.length == 0) {
            stopEnteringWord();
        }

        availableLetters.push(placedLetters.pop());

        repositionLetters();

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

        firstWord = false;

        for (letter in placedLetters) {
            letter.color.tween(0.5, { v: 0.3 });
        }

        placedLetters = [];
        for (i in availableLetters.length ... startingLetterCount) {
            availableLetters.push(createNewLetter());
        }

        repositionLetters();

        // start with the last letter of last word
        currentWord = currentWord.substr(currentWord.length - 1);
        stopEnteringWord();
    }

    function createNewLetter() {
        var letter = getRandomLetter();
        var charCode = letter.charCodeAt(0) - "A".charCodeAt(0);
        var textColor = new ColorHSV(charCode * 10, 0.1, 1);
        var borderColor = new Vector(0, 0, 0, 1);
        var isVowel = (['A', 'E', 'I', 'J', 'O', 'Q', 'U', 'Y'].indexOf(letter) > -1);
        if (isVowel) {
            borderColor = new Vector(0.6, 0, 0, 1);
        }
        return new Letter({
            pos: grid.getPos(tilesX + 1, tilesY),
            color: new ColorHSV(charCode * 10, 0.6, 1),
            r: tileSize / 2,
            letter: letter,
            textColor: textColor,
            borderColor: borderColor
        });
    }

    function abortWord() {
        trace('abortWord: $currentWord');
        
        // Start from first letter unless it's the first word
        currentWord = (firstWord ? "" : currentWord.substr(0, 1));

        stopEnteringWord();

        cursorPos = { x: wordStartedAt.x, y: wordStartedAt.y };
        cursor.pos = grid.getPos(wordStartedAt.x, wordStartedAt.y);

        availableLetters = availableLetters.concat(placedLetters);
        placedLetters = [];

        repositionLetters();
    }

    function repositionLetters() {
        availableLetters.sort(function(a :Letter, b :Letter) {
            if (a.letter < b.letter) return -1;
            if (a.letter > b.letter) return 1;
            return 0;
        });

        var count = 0;
        for (letter in availableLetters) {
            var pos = grid.getPos(count, tilesY);
            Actuate
                .tween(letter.pos, 0.5, { x: pos.x, y: pos.y })
                .delay(0.03 * count);
            count++;
        }
    }

    function startEnteringWord() {
        if (enteringWord) return;
        wordStartedAt = { x: cursorPos.x, y: cursorPos.y };
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
