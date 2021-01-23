export script_name = "TXT Extension"
export script_description = "Can change your text from ass to txt and the reverse XD"
export script_author = "Zeref"

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
        if subs[i].class == "dialogue"
            table.insert idx, k
            k += 1
    return idx

replace_selected_lines = (subs, sel) -> -- replace previous selecteds lines with lines from txt file
    file = aegisub.dialog.open "Select text file", "", "", "Open txt file (.txt)|*.txt", false, true
    lines = read_lines file
    for _, i in ipairs sel
        l = subs[i]
        l.text = lines[_] if #lines == #sel
        subs[i] = l

replace_all_lines = (subs) -> -- replace previous all lines with lines from txt file
    file = aegisub.dialog.open "Select text file", "", "", "Open txt file (.txt)|*.txt", false, true
    lines, all_lines, k = read_lines(file), all_lines_index(subs), 1
    for i = 1, #subs
        if subs[i].class == "dialogue"
            subs[i].text = lines[k] if #lines == all_lines[#all_lines]
            k += 1
        subs[i] = l

interface = (subs) -> -- interface
    gui = {
        {class: "textbox", name: "lines", x: 0, y: 0, width: 29, height: 10, text: ""}
        {class: "checkbox", label: "Remove Tags?", name: "ktags", x: 0, y: 10, value: true}
    }
    lines, k = "", 1
    for i = 1, #subs
        if subs[i].class == "dialogue"
            lines ..= "[#{k}]: #{subs[i].text} \n\n" -- Show all lines in textbox :O
            k += 1
        lines = lines\sub 1, -2
    gui[1].text = lines
    return gui

kill_tags = (tags) -> -- remove tags
    tags = tags\gsub("%b{}", "")\gsub("\\N", " ")\gsub("\\n", " ")\gsub("\\h", " ")
    return tags

cap_lines = (subs, sel, all) -> -- capture all lines or selected lines and add in one table
    lines = {}
    lines = [subs[i].text for i = 1, #subs when subs[i].class == "dialogue"]
    lines = [subs[i].text for _, i in ipairs sel] unless all
    return lines

save_lines = (subs, sel) ->
    GUI = interface subs
    bx, ck = aegisub.dialog.display GUI, {"All", "Selected", "Remove Index"}
    if bx == "Remove Index"
        GUI[1].text = GUI[1].text\gsub "%b[]%: ", ""
        bx, ck = aegisub.dialog.display GUI, {"All", "Selected", "Remove Index"}
    v_lines, GUI[1].text, GUI[2].value = "", ck.lines, ck.ktags
    switch bx
        when "All"
            filename = aegisub.dialog.save "Save Lines", "", "", "Save txt file (.txt)|.txt", false
            if filename
                file, lines = io.open(filename, "w"), cap_lines(subs, sel, true)
                if file
                    for k = 1, #lines
                        v_lines ..= lines[k] .. "\n"
                    v_lines = v_lines\sub 1, -2
                    if GUI[2].value
                        file\write kill_tags(v_lines)
                    else
                        file\write v_lines
                    file\close!
            else
                aegisub.cancel!
        when "Selected"
            filename = aegisub.dialog.save "Save Lines", "", "", "Save txt file (.txt)|.txt", false
            if filename
                file, lines = io.open(filename, "w"), cap_lines(subs, sel)
                if file
                    for k = 1, #lines
                        v_lines ..= lines[k] .. "\n"
                    v_lines = v_lines\sub 1, -2
                    if GUI[2].value
                        file\write kill_tags(v_lines)
                    else
                        file\write v_lines
                    file\close!
            else
                aegisub.cancel!
        else
            aegisub.cancel!

aegisub.register_macro "TXT Extension/TXT to Ass/All Lines", script_description, replace_all_lines
aegisub.register_macro "TXT Extension/TXT to Ass/Selected Lines", script_description, replace_selected_lines
aegisub.register_macro "TXT Extension/Ass to TXT", script_description, save_lines
