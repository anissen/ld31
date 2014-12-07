
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

class Cursor {

}

class WordList {
    var wordlist :Map<String, Int>;
    
    public function new() {
        wordlist = new Map<String, Int>();
    }

    public function reset() {
        for (word in Main.words) {
            wordlist.set(word, 0);
        }
    }

    public function isValid(word :String) {
        return wordlist.exists(word);
    }

    public function usageCount(word :String) {
        return wordlist.get(word);
    }

    public function use(word :String) {
        return wordlist.set(word, usageCount(word) + 1);
    }
}

typedef Pos = {
    x: Int,
    y: Int
}
typedef StartWordEvent = { 
    word: String,
    start: Pos,
    letters: Array<Letter> 
};
typedef AbortWordEvent = { 
    word: String,
    start: Pos,
    letters: Array<Letter> 
};
typedef CorrectWordEvent = { 
    word: String, 
    end: Pos,
    letters: Array<Letter> 
};
typedef EraseWordEvent = { 
    word: String,
    end: Pos,
    erasedLetter: Letter
};
typedef WrongWordEvent = { 
    word: String, 
    start: Pos,
    letters: Array<Letter>
};
typedef AlreadyUsedWordEvent = { 
    word: String, 
    start: Pos,
    letters: Array<Letter>
};

class Word extends Entity {
    var firstLetter :String;
    var word (get, null) :String;
    var positions :Array<Pos>;
    var direction :Direction;
    var wordlist :WordList;
    var letters :Array<Letter>;
    // var firstWord :Bool;
    var enteringWord :Bool;

    public function new() {
        super({ name: 'Word' });

        wordlist = new WordList();
        letters = new Array<Letter>();
        positions = new Array<Pos>();
    }

    public function reset() {
        firstLetter = "";
        word = "";
        enteringWord = false;
        letters = [];
        positions = [];
        wordlist.reset();
    }

    function get_word() {
        return (firstLetter + word).toLowerCase();
    }

    function startWord( _direction :Direction) {
        enteringWord = true;
        direction = _direction;

        this.events.fire('word.start_word', { word: word, letters: letters, start: positions[0] });
    }

    public function addLetter(_letter :String, _letterRep :Letter, _x :Int, _y :Int, _direction :Direction) {
        word += _letter;
        letters.push(_letterRep);
        positions.push({ x: _x, y: _y });

        if (!enteringWord) {
            startWord(_direction);
        }

        trace('enterLetter: $word');
    }

    public function abort() {
        if (!enteringWord) return;
        enteringWord = false;

        trace('abortWord: $word');

        this.events.fire('word.abort', { word: word, letters: letters, start: positions[0] });

        word = "";
        letters = [];
        positions = [];
    }

    public function submit() {
        if (!enteringWord) return;
        enteringWord = false;

        trace('tryWord: $word');

        if (!wordlist.isValid(word)) {
            trace('$word is an invalid word!');
            this.events.fire('word.wrong', { word: word, letters: letters, start: positions[0] });
            word = "";
            letters = [];
            positions = [];
            return;
        }

        if (wordlist.usageCount(word) > 0) {
            trace('$word has already been used!');
            this.events.fire('word.already_used', { word: word, letters: letters, start: positions[0] });
            word = "";
            letters = [];
            positions = [];
            return;   
        }

        wordlist.use(word);

        this.events.fire('word.correct', { word: word, letters: (letters :Array<Letter>), end: positions[positions.length - 1] });

        // start with the last letter of last word
        firstLetter = word.substr(word.length - 1);
        word = "";
        letters = [];
        positions = [];
    }

    public function erase() {
        if (word.length == 0) {
            enteringWord = false;
            return;
        }
        
        trace('erase: $word');
        word = word.substr(0, word.length - 1);
        this.events.fire('word.erase', { erasedLetter: letters.pop(), end: positions.pop() });
    }

    public function is_entering_word() {
        return enteringWord;
    }
}

class Level extends Entity {
    var letterFrequencies :LetterFrequencies;
    var grid :LevelGrid;
    var tilesX = 12;
    var tilesY = 7;
    var tileSize = 80;
    var startingLetterCount = 12;

    var availableLetters :Array<Letter>;
    var cursor :Visual;
    var cursorPos :{ x: Int, y :Int };
    var direction :Direction;
    var word :Word;

    public function new() {
        super({ name: 'Level' });

        letterFrequencies = new LetterFrequencies();
        grid = new LevelGrid(tilesX, tilesY, tileSize);
        word = new Word();
        setupWordEvents();
    }

    function setupWordEvents() {
        word.events.listen('word.start_word', function(data :StartWordEvent) {
            setCursor(data.start, false);
        });
        word.events.listen('word.wrong', function(data :WrongWordEvent) {
            Luxe.camera.shake(10);
            setCursor(data.start, true);
            availableLetters = availableLetters.concat(data.letters);
            repositionLetters();
        });
        word.events.listen('word.already_used', function(data :AlreadyUsedWordEvent) {
            Luxe.camera.shake(10);
            setCursor(data.start, true);
            availableLetters = availableLetters.concat(data.letters);
            repositionLetters();
        });
        word.events.listen('word.abort', function(data :AbortWordEvent) {
            setCursor(data.start, true);
            availableLetters = availableLetters.concat(data.letters);
            repositionLetters();
        });
        word.events.listen('word.erase', function(data :EraseWordEvent) {
            availableLetters.push(data.erasedLetter);
            cursorPos = { x: data.end.x, y: data.end.y };
            repositionLetters();
        });
        word.events.listen('word.correct', function(data :CorrectWordEvent) {
            for (letter in data.letters) {
                letter.color.tween(0.5, { v: 0.3 });
            }

            for (i in availableLetters.length ... startingLetterCount) {
                availableLetters.push(createNewLetter());
            }
            repositionLetters();
            setCursor(data.end, true);
        });
    }

    override function init() {
        availableLetters = new Array<Letter>();
        word.reset();
        cursorPos = { x: 0, y: 0 };

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

    function setDirection(_direction :Direction) {
        if (word.is_entering_word()) return;

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

        availableLetters.remove(letterRep);

        switch (direction) {
            case Up:    cursorPos.y -= 1;
            case Down:  cursorPos.y += 1;
            case Left:  cursorPos.x -= 1;
            case Right: cursorPos.x += 1;
        };

        word.addLetter(letter, letterRep, cursorPos.x, cursorPos.y, direction);
        var pos = grid.getPos(cursorPos.x, cursorPos.y);
        letterRep.gridPos = { x: cursorPos.x, y: cursorPos.y };
        Actuate
            .tween(letterRep.pos, 0.5, { x: pos.x, y: pos.y });
        Actuate
            .tween(cursor.pos, 0.5, { x: pos.x, y: pos.y });

        repositionLetters();
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

    function setCursor(pos :Pos, visible :Bool) {
        cursorPos = { x: pos.x, y: pos.y };
        cursor.pos = grid.getPos(pos.x, pos.y);
        showCursor(visible);
    }

    function showCursor(visible :Bool) {
        Actuate
            .tween(cursor.color, 0.3, { a: (visible ? 1 : 0) })
            .ease(Quad.easeInOut);
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

    override function onkeyup(e :KeyEvent) {
        switch (e.keycode) {
            case Key.up:    setDirection(Up);
            case Key.down:  setDirection(Down);
            case Key.left:  setDirection(Left);
            case Key.right: setDirection(Right);
            case Key.space: setDirection(switch (direction) {
                case Up: Right;
                case Right: Down;
                case Down: Left;
                case Left: Up;
            });
            case Key.backspace: word.erase();
            case Key.enter: word.submit();
            case Key.escape: word.abort();
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

} //Level
