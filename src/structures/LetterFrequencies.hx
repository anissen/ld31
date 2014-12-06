
package structures;

class LetterFrequencies {
    var en = [
        14810   => "A",
        2715    => "B",
        4943    => "C",
        7874    => "D",
        21912   => "E",
        4200    => "F",
        3693    => "G",
        10795   => "H",
        13318   => "I",
        188     => "J",
        1257    => "K",
        7253    => "L",
        4761    => "M",
        12666   => "N",
        14003   => "O",
        3316    => "P",
        205     => "Q",
        10977   => "R",
        11450   => "S",
        16587   => "T",
        5246    => "U",
        2019    => "V",
        3819    => "W",
        315     => "X",
        3853    => "Y",
        128     => "Z"
    ];
    var en_total_weight :Int = 0;

    public function new() {
        for (frequency in en.keys()) en_total_weight += frequency;
    }

    public function randomLetter() :String {
        var random_frequency = Math.random() * en_total_weight;
        var frequency_count = 0;
        for (frequency in en.keys()) {
            frequency_count += frequency;
            if (frequency_count >= random_frequency) {
                return en.get(frequency);
            }
        }
        return "?";
    }
}
