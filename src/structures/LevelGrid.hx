
package structures;

import luxe.Vector;

typedef CellData = { x: Int, y: Int, pos: Vector, letter: String, hasBonus: Bool };

class LevelGrid {
    var tilesX :Int;
    var tilesY :Int;
    var tileSize :Int;
    var grid :Map<String, CellData>;

    public function new(_tilesX :Int, _tilesY :Int, _tileSize :Int) {
        tilesX = _tilesX;
        tilesY = _tilesY;
        tileSize = _tileSize;
        grid = new Map<String, CellData>();
    }

    public function reset() {
        for (x in 0 ... tilesX) {
            for (y in 0 ... tilesY) {
                resetCell(x, y);
            }
        }
    }

    function resetCell(x :Int, y: Int) {
        grid['$x,$y'] = { x: x, y: y, pos: getPos(x, y), letter: '', hasBonus: true };
    }

    public function setLetterOnCell(x :Int, y: Int, letter: String) {
        grid['$x,$y'].letter = letter;
    }

    public function setBonusOnCell(x :Int, y: Int, bonus: Bool) {
        grid['$x,$y'].hasBonus = bonus;
    }

    public function tiles() {
        return grid.iterator();
    }

    public function getPos(x :Int, y: Int) {
        return new Vector((x + 0.5) * tileSize, (y + 0.5) * tileSize);
    }
}
