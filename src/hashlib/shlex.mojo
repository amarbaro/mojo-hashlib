"""shlex.quote, shlex.join and shlex.split (POSIX mode, no comments), byte for byte as CPython."""


@always_inline
def _safe(c: UInt8) -> Bool:
    # [A-Za-z0-9_@%+=:,./-], the set CPython leaves unquoted
    return (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 58) or c == 95 or c == 64 or c == 37 or c == 43 or c == 61 or c == 44 or (c >= 45 and c <= 47)


def _quote_into(s: StringSlice, mut out: String):
    var b = s.as_bytes()
    if len(b) == 0:
        out += "''"
        return
    var safe = True
    for c in b:
        safe = safe and _safe(c)
    if safe:
        out += s
        return
    out += "'"
    var start = 0
    for i in range(len(b)):
        if b[i] == 39:
            out += s[byte=start:i]
            out += "'\"'\"'"
            start = i + 1
    out += s[byte=start:len(b)]
    out += "'"


def quote(s: StringSlice) -> String:
    var out = String(capacity_bytes=s.byte_length() + 8)
    _quote_into(s, out)
    return out^


def join(args: Span[String, _]) -> String:
    var n = 0
    for a in args:
        n += a.byte_length() + 3
    var out = String(capacity_bytes=n)
    for i in range(len(args)):
        if i > 0:
            out += " "
        _quote_into(args[i], out)
    return out^


def split(s: StringSlice) raises -> List[String]:
    """Raises `No closing quotation` or `No escaped character`, the messages CPython uses."""
    var out = List[String]()
    var tok = List[UInt8]()
    var state = 0  # 0 between words, 1 in word, 2 in '', 3 in "", 4 after a backslash
    var back = 1  # state to return to after the escaped byte
    for c in s.as_bytes():
        if state == 4:
            if back == 3 and c != 34 and c != 92:
                tok.append(92)
            tok.append(c)
            state = back
        elif state == 2:
            if c == 39:
                state = 1
            else:
                tok.append(c)
        elif state == 3:
            if c == 34:
                state = 1
            elif c == 92:
                back = 3
                state = 4
            else:
                tok.append(c)
        elif c == 32 or (c >= 9 and c <= 10) or c == 13:
            if state == 1:
                out.append(String(unsafe_from_utf8=Span(tok)))
                tok.clear()
                state = 0
        elif c == 92:
            back = 1
            state = 4
        elif c == 39 or c == 34:
            state = 2 if c == 39 else 3
        else:
            tok.append(c)
            state = 1
    if state >= 2:
        raise Error("No escaped character" if state == 4 else "No closing quotation")
    if state == 1:
        out.append(String(unsafe_from_utf8=Span(tok)))
    return out^
