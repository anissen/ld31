
package entities;

import luxe.Entity;
import luxe.Input;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.tween.easing.Linear;
import luxe.tween.easing.Quad;
import luxe.Visual;
import phoenix.geometry.LineGeometry;
import luxe.options.GeometryOptions.LineGeometryOptions;
import luxe.Vector;
import luxe.Color;

import structures.LetterFrequencies;
import structures.LevelGrid;

import entities.Word;

class Cursor {

}

class Level extends Entity {
    var letterFrequencies :LetterFrequencies;
    var grid :LevelGrid;
    var tilesX = 12;
    var tilesY = 7;
    var tileSize = 80;
    var startingLetterCount = 12;

    var track :Array<Letter>;
    var availableLetters :Array<Letter>;
    var cursor :Visual;
    var cursorPos :{ x: Int, y :Int };
    var lastUsedDirection :Direction;
    var direction :Direction;
    var word :Word;

    var train :Visual;
    var trainTrackIndex :Int;
    var trainFirstMoveInterval = 30;
    var trainInitialMoveInterval = 15;
    var trainMoveInterval :Int;

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
            setCursor(data.end, false);
            repositionLetters();
        });
        word.events.listen('word.correct', function(data :CorrectWordEvent) {
            if (track.length > 0) {
                track[track.length - 1].hide();
            }

            for (letter in data.letters) {
                if (letter != data.letters[data.letters.length - 1]) {
                    letter.hide();
                }
                letter.direction = direction;
                letter.track = new Visual({
                    origin: new Vector(tileSize / 2, tileSize / 2),
                    size: new Vector(130, 130),
                    texture: Luxe.resources.find_texture("assets/images/track_straight.png"),
                    rotation_z: ((direction == Left || direction == Right) ? 90 : 0),
                    parent: letter,
                    color: letter.color
                });
            }

            track = track.concat(data.letters);
            for (i in 1 ... track.length) {
                var last = track[i - 1];
                var t = track[i];
                if (last.direction == t.direction) continue;

                // Corner
                last.track.texture = Luxe.resources.find_texture("assets/images/track_bend.png");

                // Reversed because direction left means coming from the right
                var first = switch (last.direction) {
                    case Up: 'U';
                    case Down: 'D';
                    case Left: 'R';
                    case Right: 'L';
                };
                var second = switch (t.direction) {
                    case Up: 'U';
                    case Down: 'D';
                    case Left: 'L';
                    case Right: 'R';
                };

                last.track.rotation_z = switch (first + second) {
                    case 'UR': 0;
                    case 'UL': 90;
                    case 'DR': 270;
                    case 'DL': 180;
                    case 'LU': 180;
                    case 'LD': 90;
                    case 'RU': 270;
                    case 'RD': 0;
                    default: 0;
                };
            }

            lastUsedDirection = direction;

            for (i in availableLetters.length ... startingLetterCount) {
                availableLetters.push(createNewLetter());
            }
            repositionLetters();
            cursorPos = { x: data.end.x, y: data.end.y };
            cursorPos = getNextPos();
            setCursor(cursorPos, true);
            
            var goalX = (tilesX - 2);
            var goalY = (tilesY - 2);
            if (Math.abs(cursorPos.x - goalX) + Math.abs(cursorPos.y - goalY) == 1) {
                trace('you won!');
            }
        });
    }

    function newLevel(start :Pos, goal :Pos, removeTiles :Array<Pos>) {
        availableLetters = new Array<Letter>();
        track = new Array<Letter>();
        word.reset();
        cursorPos = { x: 0, y: 0 };

        grid.reset();
        for (t in removeTiles) {
            grid.removeCell(t.x, t.y);
        }

        for (cell in grid.tiles()) {
            Luxe.draw.box({
                x: cell.pos.x - tileSize / 2,
                y: cell.pos.y - tileSize / 2,
                w: tileSize,
                h: tileSize,
                color: new Color(0.1 + 0.05 * Math.random(), 0.1 + 0.05 * Math.random(), 0.1 + 0.05 * Math.random(), 1) // new ColorHSV(255 * Math.random(), 0.5, 0.5)
            });
        }

        for (i in 0 ... startingLetterCount) {
            availableLetters.push(createNewLetter());
        }
        repositionLetters();

        cursorPos.x = start.x;
        cursorPos.y = start.y;
        cursor = new Visual({
            pos: grid.getPos(start.x, start.y),
            color: new ColorHSV(30, 0.7, 1, 0.5), 
            geometry: Luxe.draw.ngon({
                sides: 3,
                r: tileSize / 2,
                angle: 270,
                solid: true
            })
        });
        cursor.geometry.vertices[2].color = new ColorHSV(60, 0.7, 1, 0.8);

        createStartLetter(grid.getPos(start.x, start.y));
        createStartLetter(grid.getPos(goal.x, goal.y));

        setDirection(Right);

        trainMoveInterval = trainInitialMoveInterval;

        train = new Visual({
            origin: new Vector(tileSize / 2, tileSize / 2 - 40),
            size: new Vector(130, 130),
            texture: Luxe.resources.find_texture("assets/images/train.png"),
            pos: grid.getPos(start.x, start.y),
            color: new ColorHSV(0, 0, 1, 1)
        });
        trainTrackIndex = 0;

        Luxe.timer.schedule(trainFirstMoveInterval, function() {
            moveTrain();
        });
    }

    function moveTrain() {
        if (trainTrackIndex >= track.length) {
            trace('You lose!');
            return;
        }
        if (trainMoveInterval > 3) {
            trainMoveInterval -= 1;
        }

        var trainTrackLetter = track[trainTrackIndex];
        
        var trackHSV = trainTrackLetter.color.clone().toColorHSV();
        train.color
            .tween(trainMoveInterval, { h: trackHSV.h, v: trackHSV.v, s: trackHSV.s })
            .ease(Linear.easeNone);

        trainTrackLetter.color
            .tween(trainMoveInterval, { v: 1, s: 0 })
            .ease(Linear.easeNone);

        Actuate
            .tween(train.pos, trainMoveInterval / 10, { x: trainTrackLetter.pos.x, y: trainTrackLetter.pos.y });
        trainTrackIndex++;
        Luxe.timer.schedule(trainMoveInterval, moveTrain);
    }

    override function init() {
        // TODO: Be able to pass level data in
        var start = { x: 1, y: 3};
        var goal  = { x: tilesX - 2, y: tilesY - 2 };
        newLevel(start, goal, [{ x: start.x + 1, y: start.y }, { x: start.x + 1, y: start.y + 1 }]);
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
        setCursor(cursorPos, true);
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
            Luxe.camera.shake(1);
            this.events.fire('letter_missing', letter);
            return;
        }

        availableLetters.remove(letterRep);

        word.addLetter(letter, letterRep, cursorPos.x, cursorPos.y, direction);
        cursorPos = getNextPos();
        
        var pos = grid.getPos(cursorPos.x, cursorPos.y);
        letterRep.gridPos = { x: cursorPos.x, y: cursorPos.y };
        Actuate
            .tween(letterRep.pos, 0.5, { x: pos.x, y: pos.y });
        setCursor(cursorPos, true);
        
        repositionLetters();
    }

    function addLetter() {

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

    function createStartLetter(pos :Vector) {
        return new Letter({
            pos: pos,
            color: new ColorHSV(10, 0.6, 1),
            r: tileSize / 3,
            letter: ' ',
            textColor: new ColorHSV(10, 0.1, 1),
            borderColor: new Vector(0, 0, 0, 1)
        });
    }

    function getNextPos() {
        var tempPos = { x: cursorPos.x, y: cursorPos.y };
        switch (direction) {
            case Up:    tempPos.y -= 1;
            case Down:  tempPos.y += 1;
            case Left:  tempPos.x -= 1;
            case Right: tempPos.x += 1;
        };
        return tempPos;
    }

    function setCursor(pos :Pos, visible :Bool) {
        cursorPos = { x: pos.x, y: pos.y };
        var angle = switch (direction) {
            case Right: 0;
            case Down:  90;
            case Left:  180;
            case Up:    270;
        };
        var nextPos = getNextPos();
        var visualCursorPos = grid.getPos(nextPos.x, nextPos.y);
        Actuate
            .tween(cursor.pos, 0.5, { x: visualCursorPos.x, y: visualCursorPos.y });
        Actuate
            .tween(cursor, 0.5, { rotation_z: angle });
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
