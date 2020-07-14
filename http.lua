-- Allow "http" strings to be printed in text areas, workaround for leaderboards
-- Works by replacing h/H with unicode representation <- big brain Tactcat's idea

local tests = {
"http#7181",
"Http#1798",
"HTTP Protocol",
"hTTp",
"Prohttp_player#5475"
}

for i = 1, #tests do
	local aaa = tests[i]
		:gsub("H([tT][tT][pP])", "&#x48;%1")
		:gsub("h([tT][tT][pP])", "&#x68;%1")
	ui.addTextArea(i, aaa, nil, nil, 40+(i-1)*30)
end

tfm.exec.disableAfkDeath()
