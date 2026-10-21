# Edge cases docs/api.md promises. Expected values come from CPython 3.14 hashlib and shlex.
from hashlib import Hasher, Sha256, Sha1, Md5, hexlify, quote, join, split


def eq[T: Equatable & Writable](got: T, want: T, what: String) raises:
    if got != want:
        raise Error("FAIL " + what + ": got " + String(got) + ", want " + String(want))


def oneshot[algo: Int](data: Span[UInt8, _]) -> String:
    var h = Hasher[algo]()
    h.update(data)
    return h.hexdigest()


def pieces[algo: Int](data: Span[UInt8, _], what: String) raises:
    var want = oneshot[algo](data)
    for cut in range(len(data) + 1):  # every two-piece split
        var h = Hasher[algo]()
        h.update(data[0:cut])
        h.update(data[cut:len(data)])
        eq(h.hexdigest(), want, what + " cut " + String(cut))
    var one = Hasher[algo]()  # byte at a time: always the partial-block path
    for i in range(len(data)):
        one.update(data[i:i + 1])
    eq(one.hexdigest(), want, what + " bytewise")


def split_is(s: String, want: List[String]) raises:
    var got = split(s)
    eq(len(got), len(want), "split count of " + s)
    for i in range(len(want)):
        eq(got[i], want[i], "split token " + String(i) + " of " + s)


def split_raises(s: String, msg: String) raises:
    try:
        _ = split(s)
    except e:
        eq(String(e), msg, "split error of " + s)
        return
    raise Error("FAIL split of " + s + " did not raise")


def main() raises:
    # known vectors
    eq(oneshot[Sha256.algo]("".as_bytes()), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "sha256 empty")
    eq(oneshot[Sha1.algo]("".as_bytes()), "da39a3ee5e6b4b0d3255bfef95601890afd80709", "sha1 empty")
    eq(oneshot[Md5.algo]("".as_bytes()), "d41d8cd98f00b204e9800998ecf8427e", "md5 empty")
    var million = Sha256()
    var a = List[UInt8](length=1000, fill=97)
    for _ in range(1000):
        million.update(a)
    eq(million.hexdigest(), "cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0", "sha256 of a million a")

    # update takes bytes or a string, and splitting the input never changes the digest
    var h = Sha256()
    h.update("abc")
    eq(h.hexdigest(), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "sha256 abc from a string")
    for n in [0, 1, 55, 56, 57, 63, 64, 65, 119, 120, 127, 128, 129, 200]:
        var data = List[UInt8](length=n, fill=0)
        for i in range(n):
            data[i] = UInt8(i * 31 + 7)
        pieces[Sha256.algo](data, "sha256 len " + String(n))
        pieces[Sha1.algo](data, "sha1 len " + String(n))
        pieces[Md5.algo](data, "md5 len " + String(n))

    # digest does not consume the hasher
    var g = Md5()
    g.update("a")
    eq(g.hexdigest(), g.hexdigest(), "md5 digest twice")
    g.update("bc")
    eq(g.hexdigest(), "900150983cd24fb0d6963f7d28e17f72", "md5 update after digest")
    var d = g.digest()
    eq(Int(d[0]), 0x90, "digest first byte")
    eq(Int(d[15]), 0x72, "digest last byte")
    eq(Sha256.digest_size, 32, "sha256 digest_size")
    eq(Sha1.digest_size, 20, "sha1 digest_size")
    eq(Md5.digest_size, 16, "md5 digest_size")
    var bytes4: List[UInt8] = [0, 15, 16, 255]
    eq(hexlify(Span(bytes4)), "000f10ff", "hexlify")

    # shlex.quote
    eq(quote(""), "''", "quote empty")
    eq(quote("a-b_c.d/e:f=g@h%i+j,k"), "a-b_c.d/e:f=g@h%i+j,k", "quote safe set")
    eq(quote("it's"), "'it'\"'\"'s'", "quote single quote")
    eq(quote("''"), "''\"'\"''\"'\"''", "quote two single quotes")
    eq(quote("çé"), "'çé'", "quote non-ASCII")
    eq(quote("a b"), "'a b'", "quote space")

    # shlex.join
    eq(join(List[String]()), "", "join empty list")
    eq(join(["a b", "", "x"]), "'a b' '' x", "join mixed")

    # shlex.split
    split_is("", List[String]())
    split_is("   ", List[String]())
    split_is("''", [""])
    split_is('""', [""])
    split_is("a\\\\", ["a\\"])
    split_is('"a\\q\\"\\\\"', ['a\\q"\\'])
    split_is("'a'\"b\"c", ["abc"])
    split_is("a\tb\nc\r\nd", ["a", "b", "c", "d"])
    split_is("x='1 2'", ["x=1 2"])
    split_is("é 日本", ["é", "日本"])
    split_raises("a\\", "No escaped character")
    split_raises("'x", "No closing quotation")
    split_raises('"x\\', "No escaped character")
    print("api: ok")
