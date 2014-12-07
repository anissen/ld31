
package entities;

import luxe.Entity;
import luxe.Vector;
import luxe.Color;

import structures.WordList;

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
    // direction: Direction,
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

enum Direction {
    Up;
    Down;
    Left;
    Right;
}

class Word extends Entity {
    var firstLetter :String;
    var word (get, never) :String;
    var currentWord :String;
    var positions :Array<Pos>;
    var direction :Direction;
    var wordlist :WordList;
    var letters :Array<Letter>;
    var enteringWord :Bool;

    public function new() {
        super({ name: 'Word' });

        wordlist = new WordList();
        letters = new Array<Letter>();
        positions = new Array<Pos>();
    }

    public function reset() {
        firstLetter = "";
        currentWord = "";
        enteringWord = false;
        letters = [];
        positions = [];
        wordlist.reset();
    }

    function get_word() {
        return (firstLetter + currentWord).toLowerCase();
    }

    function startWord( _direction :Direction) {
        enteringWord = true;
        direction = _direction;

        this.events.fire('word.start_word', { word: word, letters: letters, start: positions[0] });
    }

    public function addLetter(_letter :String, _letterRep :Letter, _x :Int, _y :Int, _direction :Direction) {
        currentWord += _letter;
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

        currentWord = "";
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
            currentWord = "";
            letters = [];
            positions = [];
            return;
        }

        if (wordlist.usageCount(word) > 0) {
            trace('$word has already been used!');
            this.events.fire('word.already_used', { word: word, letters: letters, start: positions[0] });
            currentWord = "";
            letters = [];
            positions = [];
            return;   
        }

        trace('$word is correct!');

        wordlist.use(word);

        this.events.fire('word.correct', { word: word, letters: (letters :Array<Letter>), end: positions[positions.length - 1] });

        // start with the last letter of last word
        firstLetter = word.substr(word.length - 1);
        currentWord = "";
        letters = [];
        positions = [];
    }

    public function erase() {
        if (currentWord.length == 0) {
            enteringWord = false;
            return;
        }
        
        trace('erase: $word');
        currentWord = currentWord.substr(0, currentWord.length - 1);
        this.events.fire('word.erase', { erasedLetter: letters.pop(), end: positions.pop() });
    }

    public function is_entering_word() {
        return enteringWord;
    }
}
