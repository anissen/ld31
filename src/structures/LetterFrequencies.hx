
package structures;

class LetterFrequencies {
    var en_freq_to_letter = [
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

    var en_letter_to_score = [
        "A" => 1,
        "B" => 3,
        "C" => 3,
        "D" => 2,
        "E" => 1,
        "F" => 4,
        "G" => 2,
        "H" => 4,
        "I" => 1,
        "J" => 8,
        "K" => 5,
        "L" => 1,
        "M" => 3,
        "N" => 1,
        "O" => 1,
        "P" => 3,
        "Q" => 10,
        "R" => 1,
        "S" => 1,
        "T" => 1,
        "U" => 1,
        "V" => 4,
        "W" => 4,
        "X" => 8,
        "Y" => 4,
        "Z" => 10
    ];

    var en_vowels = [
        14810   => "A",
        21912   => "E",
        13318   => "I",
        14003   => "O",
        205     => "Q",
        5246    => "U",
        3853    => "Y",
    ];

    var en_consonants = [
        2715    => "B",
        4943    => "C",
        7874    => "D",
        4200    => "F",
        3693    => "G",
        10795   => "H",
        188     => "J",
        1257    => "K",
        7253    => "L",
        4761    => "M",
        12666   => "N",
        3316    => "P",
        10977   => "R",
        11450   => "S",
        16587   => "T",
        2019    => "V",
        3819    => "W",
        315     => "X",
        128     => "Z"
    ];

    var en_total_weight :Int = 0;
    var en_vowels_weight :Int = 0;
    var en_consonants_weight :Int = 0;

    public function new() {
        for (frequency in en_freq_to_letter.keys()) en_total_weight += frequency;
        for (frequency in en_vowels.keys()) en_vowels_weight += frequency;
        for (frequency in en_consonants.keys()) en_consonants_weight += frequency;
    }

    public function randomLetter() :String {
        var random_frequency = Math.random() * en_total_weight;
        var frequency_count = 0;
        for (frequency in en_freq_to_letter.keys()) {
            frequency_count += frequency;
            if (frequency_count >= random_frequency) {
                return en_freq_to_letter.get(frequency);
            }
        }
        return "?";
    }

    public function randomVowel() :String {
        var random_frequency = Math.random() * en_vowels_weight;
        var frequency_count = 0;
        for (frequency in en_vowels.keys()) {
            frequency_count += frequency;
            if (frequency_count >= random_frequency) {
                return en_vowels.get(frequency);
            }
        }
        return "?";
    }

    public function randomConsonant() :String {
        var random_frequency = Math.random() * en_consonants_weight;
        var frequency_count = 0;
        for (frequency in en_consonants.keys()) {
            frequency_count += frequency;
            if (frequency_count >= random_frequency) {
                return en_consonants.get(frequency);
            }
        }
        return "?";
    }

    public function getScore(word :String) {
        var score = 0;
        for (i in 0 ... word.length) {
            trace('score for ${word.charAt(i).toUpperCase()}: ${en_letter_to_score.get(word.charAt(i).toUpperCase())}');
            score += en_letter_to_score.get(word.charAt(i).toUpperCase());
        }
        return Math.floor(score * word.length);
    }
}
