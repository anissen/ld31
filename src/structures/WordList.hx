
package structures;

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
