require "unicode"

-- Function to_kara by Kara Effector --> https://github.com/KaraEffect0r/Kara_Effector
script_name = "Romaji to K-time"
script_description = "Divide your text in romaji for k-times according to the length of the line."
script_author = "Zeref"

math_round = (x, dec) -> if dec and dec >= 1 then 
    dec = 10 ^ math.floor(dec) 
    math.floor(x * dec + 0.5) / dec else math.floor(x + 0.5)

romaji_to_kara = (Text, Duration) ->
    romajis = {
        "kya",	"kyu",	"kyo",	"sha",	"shu",	"sho",	"cha",	"chu",	"cho",
        "nya",	"nyu",	"nyo",	"hya",	"hyu",	"hyo",	"mya",	"myu",	"myo",
        "rya",	"ryu",	"ryo",	"gya",	"gyu",	"gyo",	"bya",	"byu",	"byo",
        "pya",	"pyu",	"pyo",	"shi",	"chi",	"tsu",
        "ya",	"yu",	"yo",	"ka",	"ki",	"ku",	"ke",	"ko",	"sa",
        "su",	"se",	"so",	"ta",	"te",	"to",	"na",	"ni",	"nu",
        "ne",	"no",	"ha",	"hi",	"fu",	"he",	"ho",	"ma",	"mi",
        "mu",	"me",	"mo",	"ya",	"yu",	"yo",	"ra",	"ri",	"ru",
        "re",	"ro",	"wa",	"wi",	"we",	"wo",	"ga",	"gi",	"gu",
        "ge",	"go",	"za",	"ji",	"zu",	"ze",	"zo",	"ja",	"ju",
        "jo",	"da",	"di",	"du",	"de",	"do",	"ba",	"bi",	"bu",
        "be",	"bo",	"pa",	"pi",	"pu",	"pe",	"po",   "fo",
        "a",	"i",	"u",	"e",	"o",	"n",	"b",	"c",	"d",
        "k",	"p",	"r",	"s",	"t",	"z"
    }
    clean_text = (text) ->
        text = text\gsub("%b{}", "")\gsub("\\[Nnh]", "")\gsub("%s+", " ")
        return text
    table_concat = (Table, add) ->
        con_add, table_concat = "", ""
        for i = 1, #Table
            con_add = ""
            if add and i < #Table
                con_add = add
            table_concat = table_concat .. Table[i] .. con_add
        return table_concat
    text2word = (Text, Duration) ->
        Duration = Duration or 5000
        to_word = (text) ->
            words = [c for c in text\gmatch "%S+"]
            for k = 1, #words - 1
                words[k] = words[k] .. " "
            return words
        words_in_text = to_word(Text)
        words_in_text_dur, count_chars_in_line = {}
        text_without_space = Text\gsub " ", ""
        word_without_space
        count_chars_in_line = unicode.len(text_without_space)
        for i = 1, #words_in_text
            word_without_space = words_in_text[i]\gsub " ", ""
            words_in_text_dur[i] = math_round unicode.len(word_without_space) * Duration / count_chars_in_line, 3
        return words_in_text, words_in_text_dur
    Text = unicode.to_lower_case(Text)
    Text, num = clean_text(Text), 0
    words, times = text2word Text, Duration
    for i = 1, #words
        for k = 1, #romajis
            words[i] = words[i]\gsub "[\128-\255]*" .. romajis[k], "[%1]"
        words[i] = words[i]\gsub "%b[]", (capture) ->
            capture = capture\gsub("%[", "")\gsub("%]", "")
            return "[" .. capture .. "]"
        words[i], num = words[i]\gsub "%b[]", "%1"
        if num > 0 then
            words[i] = words[i]\gsub "%b[]", (capture) ->
                capture = capture\gsub("%[", "")\gsub("%]", "")
                return string.format "{\\k%d}%s", times[i] / (num * 10), capture
    Text = table_concat words
    return Text

master = (subs, sel) ->
    for _, i in ipairs(sel)
        l = subs[i]
        dur = l.end_time - l.start_time
        if not l.text\match "\\[kK]^*[fo]*%d+" -- Robé la captura XD
            l.text = romaji_to_kara(l.text, dur)
        subs[i] = l

aegisub.register_macro script_name, script_description, master