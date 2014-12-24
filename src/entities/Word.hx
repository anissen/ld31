
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

    public function reset(resetWordList :Bool = true) {
        firstLetter = "";
        currentWord = "";
        enteringWord = false;
        letters = [];
        positions = [];
        if (resetWordList) wordlist.reset();
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
    }

    public function abort() {
        if (!enteringWord) return;
        enteringWord = false;

        this.events.fire('word.abort', { word: word, letters: letters, start: positions[0] });

        currentWord = "";
        letters = [];
        positions = [];
    }

    public function submit(allow_reuse_words :Bool) {
        if (!enteringWord) return;
        enteringWord = false;

        if (!wordlist.isValid(word)) {
            this.events.fire('word.wrong', { word: word, letters: letters, start: positions[0] });
            currentWord = "";
            letters = [];
            positions = [];
            return;
        }

        if (!allow_reuse_words && wordlist.usageCount(word) > 0) {
            this.events.fire('word.already_used', { word: word, letters: letters, start: positions[0] });
            currentWord = "";
            letters = [];
            positions = [];
            return;   
        }

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
        
        currentWord = currentWord.substr(0, currentWord.length - 1);
        this.events.fire('word.erase', { erasedLetter: letters.pop(), end: positions.pop() });
    }

    public function is_entering_word() {
        return enteringWord;
    }
}
