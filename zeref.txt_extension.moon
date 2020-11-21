script_name = "TXT Extension"
script_description = "Can change your text from ass to txt and the reverse XD"
script_author = "Zeref"

read_lines = (filename) -> -- read text in file txt and add in one table it's lines
    if filename
        arq = io.open filename, "r"
        read = arq\read "*a"
        lines = [k for k in read\gmatch "([^\n]+)"]
        return lines
    else
        aegisub.cancel!

all_lines_index = (subs) -> -- return index of all lines in one table
    idx, k = {}, 1
    for i = 1, #subs
        l = subs[i]
        if l.class == "dialogue"
            table.insert idx, k
            k = k + 1
    return idx

replace_selecteds_lines = (subs, sel) -> -- replace previous selecteds lines with lines from txt file
    file = aegisub.dialog.open "Select text file", "", "", "Open txt file (.txt)|*.txt", false, true
    lines = read_lines file
    for _, i in ipairs sel
        l = subs[i]
        if #lines == #sel
            l.text = lines[_]
        subs[i] = l

replace_all_lines = (subs) -> -- replace previous all lines with lines from txt file
    file = aegisub.dialog.open "Select text file", "", "", "Open txt file (.txt)|*.txt", false, true
    lines, all_lines, k = read_lines(file), all_lines_index(subs), 1
    for i = 1, #subs
        l = subs[i]
        if l.class == "dialogue"
            if #lines == all_lines[#all_lines]
                l.text = lines[k]
            k = k + 1
        subs[i] = l

interface = (subs) -> -- interface
    gui = {{class: "textbox", name: "lines", x: 0, y: 0, width: 29, height: 10, text: ""}}
    lines, k = "", 1
    for i = 1, #subs
        if subs[i].class == "dialogue"
            l = subs[i]
            lines = lines .. string.format("[%s]: ", k) .. l.text .. "\n\n" -- Show all lines in textbox :O
            k = k + 1
        lines = lines\sub 1, -2
    gui[1].text = lines
    return gui

cap_lines = (subs, sel, all) -> -- capture all lines or selected lines and add in one table
    lines = {}
    if all
        lines = [subs[i].text for i = 1, #subs when subs[i].class == "dialogue"]
    else
        lines = [subs[i].text for _, i in ipairs sel]
    return lines

save_lines = (subs, sel) ->
    GUI = interface(subs)
    bx, ck = aegisub.dialog.display GUI, {"All", "Selecteds", "Remove Index"}
    v_lines, GUI[1].text = "", ck.lines
    --
    if bx == "Remove Index"
        GUI[1].text = GUI[1].text\gsub "%b[]%: ", ""
        bx, ck = aegisub.dialog.display GUI, {"All", "Selecteds", "Remove Index"}
    if bx == "All"
        filename = aegisub.dialog.save "Save Lines", "", "", "Save txt file (.txt)|.txt", false
        if filename
            file, lines = io.open(filename, "w"), cap_lines(subs, sel, true)
            if file
                for k = 1, #lines
                    v_lines = v_lines .. lines[k] .. "\n"
                v_lines = v_lines\sub 1, -2
                file\write v_lines
                file\close!
        else
            aegisub.cancel!
    elseif bx == "Selecteds"
        filename = aegisub.dialog.save "Save Lines", "", "", "Save txt file (.txt)|.txt", false
        if filename
            file, lines = io.open(filename, "w"), cap_lines(subs, sel)
            if file
                for k = 1, #lines
                    v_lines = v_lines .. lines[k] .. "\n"
                v_lines = v_lines\sub 1, -2
                file\write v_lines
                file\close!
        else
            aegisub.cancel!
    else
        aegisub.cancel!

aegisub.register_macro "Zeref Macros/TXT Extension/TXT to Ass/All Lines", script_description, replace_all_lines
aegisub.register_macro "Zeref Macros/TXT Extension/TXT to Ass/Selected Lines", script_description, replace_selecteds_lines
aegisub.register_macro "Zeref Macros/TXT Extension/Ass to TXT", script_description, save_lines