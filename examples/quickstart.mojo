from hashlib import Sha256, Md5, quote, join, split


def main() raises:
    # hash in pieces; hexdigest can be read at any point and the hasher keeps going
    var h = Sha256()
    h.update("python train.py ")
    h.update("--seed 1")
    print(h.hexdigest())

    var m = Md5()
    m.update("abc")
    print(m.hexdigest())

    # build a shell command line safely, and take one apart again
    var argv: List[String] = ["sh", "-c", "echo $X; exit 3"]
    var line = join(argv)
    print(line)
    for word in split(line):
        print(word)
    print(quote("it's"))
