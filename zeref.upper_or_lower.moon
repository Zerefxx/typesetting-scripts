script_name = "Upper or Lower"
script_description = "It simply transforms your text to lowercase or uppercase."
script_author = "Ruan"

include "unicode.lua" -- Library unicode
sf = string.format

m1 = {"Upper", "Lower"}
m2 = {"Linhas Selecionadas", "Todas as Linhas"}

gui =  {
	{class: "label", label: "Selecione:", x: 0, y: 0},
	{class: "dropdown", name: "modos1", items: m1, value: m1[1], x: 0, y: 1},
	{class: "label", label: "Modo de aplicação:                           ", x: 0, y: 2},
	{class: "dropdown", name: "modos2", items: m2, value: m2[1], x: 0, y: 3},
	{class: "checkbox", name: "ativar", label: "Ativar Tags", x: 0, y: 4, value: true}
}

master = (subs, sel) ->
    b, s = aegisub.dialog.display gui, {"Aplicar", "Cancelar"}
    gui[2].value = s.modos1
	gui[4].value = s.modos2
	gui[5].value = s.ativar
    if b == "Aplicar" and gui[2].value == m1[1] and gui[4].value == m2[1]
        for _, i in ipairs sel
			l = subs[i]
			if gui[5].value == false
				if l.text\match "%b{}"
					l.text = l.text\gsub "(%b{})([^%{]*)", (x, y) ->
						y = unicode.to_upper_case y
						return sf "%s", x .. y
				else
					l.text = sf "%s", unicode.to_upper_case l.text
            else
				l.text = sf "%s", unicode.to_upper_case l.text			
            subs[i] = l
    elseif b == "Aplicar" and gui[2].value == m1[2] and gui[4].value == m2[1]
        for _, i in ipairs sel
			l = subs[i]
			if gui[5].value == false
				if l.text\match "%b{}"
					l.text = l.text\gsub "(%b{})([^%{]*)", (x, y) ->
						y = unicode.to_lower_case y
						return sf "%s", x .. y 
				else
					l.text = sf "%s", unicode.to_lower_case l.text
			else
				l.text = sf "%s", unicode.to_lower_case l.text
			subs[i] = l
    elseif b == "Aplicar" and gui[2].value == m1[1] and gui[4].value == m2[2]
        for i = 1, #subs
            if subs[i].class == "dialogue"
                l = subs[i]
                if gui[5].value == false
                    if l.text\match "%b{}"
                        l.text = l.text\gsub "(%b{})([^%{]*)", (x, y) ->
                            y = unicode.to_upper_case y
                            return sf "%s", x .. y
                    else
                        l.text = sf "%s", unicode.to_upper_case l.text
                else
                    l.text = sf "%s", unicode.to_upper_case l.text
                subs[i] = l
    elseif b == "Aplicar" and gui[2].value == m1[2] and gui[4].value == m2[2]
        for i = 1, #subs
            if subs[i].class == "dialogue"
                l = subs[i]
                if gui[5].value == false
                    if l.text\match "%b{}"
                        l.text = l.text\gsub "(%b{})([^%{]*)", (x, y) ->
                            y = unicode.to_lower_case y
                            return sf "%s", x .. y
                    else
                        l.text = sf "%s", unicode.to_lower_case l.text
                else
                    l.text = sf "%s", unicode.to_lower_case l.text
                subs[i] = l

aegisub.register_macro sf("Zeref Macros/%s", script_name), script_description, master