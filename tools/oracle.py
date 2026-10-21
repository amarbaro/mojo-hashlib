"""Oracle: hashlib (sha256, sha1, md5) over fixed byte inputs, and
shlex.quote / shlex.join / shlex.split over fixed strings. One result per line."""
import hashlib, random, shlex
r = random.Random(1)
blobs = [b"", b"a", b"abc", b"\x00", b"\x00" * 55, b"\x00" * 56, b"\x00" * 63, b"\x00" * 64, b"\x00" * 65,
         "çé日本".encode(), b"python train.py --seed 1"] + [bytes(r.randrange(256) for _ in range(n)) for n in (1, 100, 1000, 100000)]
for i, b in enumerate(blobs):
    for algo in ("sha256", "sha1", "md5"):
        print("hash", algo, i, len(b), hashlib.new(algo, b).hexdigest())
words = ["", "a", "a b", "it's", 'say "hi"', "$HOME", "a\tb", "a\nb", "çé", "--flag=1", "*.py", "`x`", "a'b\"c", "~", "#x", "=", "-"]
for w in words: print("quote", w.encode().hex(), shlex.quote(w))
for argv in (["python", "train.py"], ["sh", "-c", "echo $X; exit 3"], ["a b", "it's"], [""], ["x"] * 3):
    print("join", "|".join(a.encode().hex() for a in argv), shlex.join(argv))
for s in ["a b c", "a 'b c' d", 'a "b c" d', "a\\ b", "'it'\\''s'", '"$X"', "  lead  trail  ", "a#b", "unterminated 'x"]:
    try: out = "|".join(x.encode().hex() for x in shlex.split(s))
    except ValueError as e: out = "ERR " + str(e)
    print("split", s.encode().hex(), out)
