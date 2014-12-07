
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
import luxe.Particles;
import luxe.Sprite;

import phoenix.Batcher;

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
    var direction :Direction;
    var word :Word;
    var goal :Pos;
    var viaPoints :Array<Pos>;

    var train :Visual;
    var trainTrackIndex :Int;
    var trainFirstMoveInterval = 30;
    var trainInitialMoveInterval = 2;
    var trainMoveInterval :Int;

    var infoText :Text;

    var gameOver :Bool;

    var particles :ParticleSystem;

    var trainTimer :snow.utils.Timer;

    var level :Int;
    var levels = [
        {
            title: 'Level One',
            start: { x: 3, y: 3 },
            goal:  { x: 7, y: 3 },
            via: []
        },
        {
            title: 'Level Two',
            start: { x: 1, y: 3 },
            goal:  { x: 10, y: 5 },
            via: []
        },
        {
            title: 'Level Three',
            start: { x: 1, y: 1 },
            via: [ { x: 4, y: 4} ],
            goal:  { x: 8, y: 6 }
        },
        {
            title: 'Level Four',
            start: { x: 8, y: 5 },
            goal:  { x: 10, y: 5 },
            via: [ { x: 1, y: 2} ]
        },
        {
            title: 'Level Five',
            start: { x: 3, y: 6 },
            goal:  { x: 1, y: 5 },
            via: [ { x: 4, y: 2}, { x: 1, y: 2} ]
        }
    ];

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
            if (data.word.length < 3) notify("Too short");
        });
        word.events.listen('word.already_used', function(data :AlreadyUsedWordEvent) {
            Luxe.camera.shake(10);
            setCursor(data.start, true);
            availableLetters = availableLetters.concat(data.letters);
            repositionLetters();
            notify("Already used");
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

                var isVia = false;
                var viaPointsToRemove = [];
                for (via in viaPoints) {
                    if (letter.gridPos.x == via.x && letter.gridPos.y == via.y) {
                        viaPointsToRemove.push(via);
                        isVia = true;
                    }
                }
                for (via in viaPointsToRemove) {
                    viaPoints.remove(via);
                }
                if (viaPoints.length == 0) {
                    if (letter.gridPos.x == goal.x && letter.gridPos.y == goal.y) {
                        gameOver = true;
                        level++;
                        if (level < levels.length) {
                            notify("Level completed! Press any key.");
                        } else {
                            notify("You won the game!");
                        }
                    }
                }
                if (isVia && !gameOver) notify("You got a via point!");
                // var acceptableRange = 0;
                // if (Math.abs(cursorPos.x - goal.x) + Math.abs(cursorPos.y - goal.y) <= acceptableRange) {
                //     gameOver = true;
                //     level++;
                //     notify("You won! Press any key.");
                // }
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

            for (i in availableLetters.length ... startingLetterCount) {
                availableLetters.push(createNewLetter());
            }
            repositionLetters();
            cursorPos = { x: data.end.x, y: data.end.y };
            cursorPos = getNextPos();
            setCursor(cursorPos, true);
        });
    }

    function newLevel(levelData :{ title :String, start :Pos, goal :Pos, via :Array<Pos> }) {
        gameOver = false;
        if (trainTimer != null) trainTimer.stop();

        if (availableLetters != null) for (l in availableLetters) l.destroy();
        availableLetters = new Array<Letter>();

        if (track != null) for (t in track) t.destroy();
        track = new Array<Letter>();

        word.reset();
        cursorPos = { x: 0, y: 0 };

        grid.reset();

        for (cell in grid.tiles()) {
            Luxe.draw.box({
                x: cell.pos.x - tileSize / 2,
                y: cell.pos.y - tileSize / 2,
                w: tileSize,
                h: tileSize,
                color: new Color(0.1 + 0.05 * Math.random(), 0.1 + 0.05 * Math.random(), 0.1 + 0.05 * Math.random(), 1) // new ColorHSV(255 * Math.random(), 0.5, 0.5)
            });
        }

        if (infoText != null) infoText.destroy();
        infoText = null;

        for (i in 0 ... startingLetterCount) {
            availableLetters.push(createNewLetter());
        }
        repositionLetters();

        var start = levelData.start;
        goal = levelData.goal;
        cursorPos.x = start.x;
        cursorPos.y = start.y;
        if (cursor != null) cursor.destroy();
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

        viaPoints = levelData.via;
        for (via in levelData.via) {
            createViaLetter(grid.getPos(via.x, via.y));            
        }

        setDirection(Right);

        trainMoveInterval = trainInitialMoveInterval;

        if (train != null) train.destroy();
        train = new Visual({
            origin: new Vector(tileSize / 2, tileSize / 2 + 20),
            size: new Vector(130, 130),
            texture: Luxe.resources.find_texture("assets/images/train.png"),
            pos: grid.getPos(start.x, start.y),
            color: new ColorHSV(0, 0, 1, 1)
        });
        trainTrackIndex = 0;

        trainTimer = Luxe.timer.schedule(trainFirstMoveInterval, function() {
            notify('Cho choo!', true);
            moveTrain();
        });

        setupParticles();

        notify(levelData.title);
    }

    function setupParticles() {
        if (particles != null) particles.destroy();

        particles = new ParticleSystem({name:'particles'});

        particles.add_emitter({
            name : 'smoke',
            particle_image : Luxe.resources.find_texture('assets/particles/smoke.png'),
            start_color: new Color(255, 255, 255, 1),
            end_color: new Color(255, 255, 255, 0),
            start_size: new Vector(16,16),
            end_size: new Vector(32,32),
            gravity: new Vector(0, -30),
            life: 5.0,
            end_speed: 0,
            depth: 3,
            group: 5,
            emit_time: 0.5,
            pos_offset: new Vector(25, -25),
            pos_random: new Vector(2, 2)
        });
        
        particles.stop();

        particles.pos = train.pos.clone();
        train.transform.listen_pos(function(_) {
            particles.pos = train.pos.clone();
        });

        Luxe.renderer.batcher.add_group(5,
            function(b:Batcher){
                Luxe.renderer.blend_mode(BlendMode.src_alpha, BlendMode.one);
            },
            function(b:Batcher){
                Luxe.renderer.blend_mode();
            }
        );
    }

    function moveTrain() {
        if (gameOver) return;
        if (trainTrackIndex >= track.length) {
            gameOver = true;
            notify("You lost! Press any key.", true);
            level = 0;
            particles.stop();
            return;
        }

        particles.start();

        var trainTrackLetter = track[trainTrackIndex];
        
        var trackHSV = trainTrackLetter.color.clone().toColorHSV();
        train.color
            .tween(trainMoveInterval, { h: trackHSV.h, v: trackHSV.v, s: trackHSV.s })
            .ease(Linear.easeNone);

        trainTrackLetter.color
            .tween(trainMoveInterval, { v: 1, s: 0 })
            .ease(Linear.easeNone);

        Actuate
            .tween(train.pos, trainMoveInterval, { x: trainTrackLetter.pos.x, y: trainTrackLetter.pos.y })
            .ease(Linear.easeNone);
        trainTrackIndex++;
        Luxe.timer.schedule(trainMoveInterval, moveTrain);
    }

    override function init() {
        level = 0;
        reset();
    }

    function getRandomLetter() :String {
        if (vowelCount() < 3) {
            return letterFrequencies.randomVowel();
        } else if (consonantCount() < 5) {
            return letterFrequencies.randomConsonant();
        }
        return letterFrequencies.randomLetter();
    }

    function vowelCount() {
        var count = 0;
        for (l in availableLetters) {
            var isVowel = (['A', 'E', 'I', 'J', 'O', 'Q', 'U', 'Y'].indexOf(l.letter) > -1);
            if (isVowel) count++;
        }
        return count;
    }

    function consonantCount() {
        return availableLetters.length - vowelCount();
    }

    public function reset() {
        newLevel(levels[level % levels.length]);
    }

    function setDirection(_direction :Direction) {
        if (word.is_entering_word()) return;

        if (track.length > 0) {
            var lastDirection = track[track.length - 1].direction;
            var validDir = switch (_direction) {
                case Up: lastDirection != Down;
                case Down: lastDirection != Up;
                case Left: lastDirection != Right;
                case Right: lastDirection != Left;
            };
            if (!validDir) {
                notify('No going back');
                return;
            }
        }

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
        var nextPos = getNextPos();
        if (nextPos.x < 0 || nextPos.x >= tilesX || nextPos.y < 0 || nextPos.y >= tilesY) {
            Luxe.camera.shake(1);
            this.events.fire('outside_bounds');
            notify('Stay inside the map please');
            return;
        }

        var letterRep = findLetter(letter);
        if (letterRep == null) {
            Luxe.camera.shake(1);
            notify('No "$letter"');
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

    function notify(text: String, warn :Bool = false) {
        var count = 0;
        for (l in availableLetters) {
            var pos = grid.getPos(count++, tilesY + 1);
            Actuate
                .tween(l.pos, 0.3, { y: pos.y })
                .delay(0.03 * count);
        }

        var unique_shader = Luxe.renderer.shaders.bitmapfont.shader.clone(); // .font.shader.clone();
        unique_shader.set_float('thickness', 1);
        unique_shader.set_float('smoothness', 0.8);
        unique_shader.set_float('outline', 0.75);
        unique_shader.set_vector4('outline_color', (warn ? new Vector(0.8, 0.0, 0.0, 1.0) : new Vector(0.0, 0.0, 0.8, 1.0)));

        if (infoText != null) infoText.destroy();
        infoText = new Text({
            pos: new Vector(Luxe.screen.w / 2, (tilesY + 1 + 0.5) * tileSize),
            text: text,
            font: Luxe.resources.find_font("rail"),
            shader: unique_shader,
            color: new ColorHSV(0, 0, 1),
            align: center,
            align_vertical: center,
            point_size: 64
        });
        Actuate
            .tween(infoText.pos, 0.3, { y: (tilesY + 0.5) * tileSize })
            .delay(0.2);

        Luxe.timer.schedule(0.9, function () {
            repositionLetters();
        });
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

    function createViaLetter(pos :Vector) {
        return new Letter({
            pos: pos,
            color: new ColorHSV(200, 0.6, 1),
            r: tileSize / 4,
            letter: '',
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
        if (gameOver) return;
        if (infoText != null) infoText.destroy();

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
        if (gameOver) {
            reset();
            return;
        }
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
