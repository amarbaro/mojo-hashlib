from hashlib import Sha256, quote, join, split


def main() raises:
    var h = Sha256()
    h.update("python train.py ")
    h.update("--seed 1")
    print(h.hexdigest())
    var line = join(["sh", "-c", "echo $X; exit 3"])
    print(line, split(line).__len__(), quote("it's"))
