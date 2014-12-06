
package entities;

import components.*;

import luxe.Entity;
import luxe.Input;
import luxe.Text;
import phoenix.geometry.LineGeometry;
import luxe.options.GeometryOptions.LineGeometryOptions;
import luxe.Vector;
import luxe.Color;

import structures.LetterFrequencies;
import structures.LevelGrid;


class Level extends Entity {
    var letterFrequencies :LetterFrequencies;
    var wordlist :Map<String, Int>;
    var word :String = "";
    var grid :LevelGrid; // TODO: Move this to a its own class
    var tilesX = 12;
    var tilesY = 7;
    var tileSize = 80;
    var startingLetterCount = 10;

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

        grid.reset();

        for (cell in grid.tiles()) {
            Luxe.draw.box({
                x: cell.x * tileSize,
                y: cell.y * tileSize,
                w: tileSize,
                h: tileSize,
                color: new Color(0.2, 0.2, 0.2, 1) // new ColorHSV(255 * Math.random(), 0.5, 0.5)
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
            var circle = new luxe.Visual({
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
    }

    function getRandomLetter() :String {
        return letterFrequencies.randomLetter();
    }

    public function reset() {
        init();
    }
} //Main
