pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- 0,4,8,c
amp = {
	[0]=159,
	[1]=143,
	[2]=127,
	[3]=111,
}

brosnd = {
	coin="ちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちきヌ▥し[\-0\0\|pり⬇️\0\f4003クト\015\014,。、やこネクんトあたx8xxkッなエイ🅾️⌂i*ヌすヌヌヒあそ-l8-ちff@\*\nマnぬ8uくへね➡️z⌂m,it*★ちタソˇ●hittけすあ⬅️⌂n^mjちほワフフサあyl-)((\|j❎ラ⬇️j웃▮▶h¥う¥!iそゅ⌂◆お^jffけけすちちちiiijちちむヒコサつちちちちちむちたしちちちちた∧ちちちちちちたすちちちちちちちちちちちタ\tちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちち ちちちちちち",
	kill="ちちちちちちちちちちちちちちちちちちちちちけ\0\0\0◀◝ワ^○◝◝◝◝ヲ@\0\0\0\0\0■uuvちyˇp\0\0\0\+◝◝◝ュ\0\0\0?◝◝◝ ら\0\0\0\0\0\+uuiuuちjちr(@\0\0@ャら\0?ユ\0め◝◝◝◝◝ナ\0\0\0\0\0\0\0\*uzち⧗テte@\+\*\|\*ほ◝\0゜\0\0c◝◝◝◝◝\0\0\0\0uujしちuuuuu」d%h\0\0\0rヤス9\-ム\*█◝◝◝ョ◜fッt\0\0\0\+tャよ◝◝l%@\0\0\0▮\+\0$か◝◝\-◝○◝◝➡️ua\0\0\0/◝$ツ◝◝p\0◀ちちあˇuuuuち@\0\0\"◝",
	bonk="ちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちˇちちちたuzちつたuzッあホuzたuoョp\*oたjヲcˇョ\aeよ◝⬆️\*eさ?◝ホ\t\0ョ\aマ◝「…\a⬅️◜やzンu@u\#◜に◝@\0fちみし◝ン\0\0v◝マち◝ン@\0\^◜ちす◝ン@\0[◝ホj◝◜\0\0\v◝みz◝◜ヘ\0\0つしuo◝ッら\0\+しちい◝◝いˇd\*‖ゆ◝◝◝ッに\0\0vつ◝にヤ◜u@\0\|eよに◝◝ミハu\0t*uちつマゆjˇuuちつミ◝よつハi\0p\+uijちちミすち∧しuujちちちちしj∧つちたvuたuvちちちちちちち∧しyuizちちちちちちちッちちちちしuuuちたuezˇuzちちちちちちちちちちちちちちちˇzちちちちちちちちˇjちちちちちちちちたuuuuzちちちちちちちちちちちちちちちˇzちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちjちちちちちちちちちちちちちちちちちuuuちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちち ちちちちちちち",
	dies="ちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちたjちちちちちちちちjちちちjあたちたjあちちuちちちしvちちしuoちしzvンちuしoマたzu◜ちˇしoマたzuゆjˇしoちハifッゆv…よつˇし•ヒン¥aョnaハo∧さo∧ンuvッにˇuoすョ‖aッoニt゜マ◝‖a~つンu\^みよをp¥い◝uaと○ョu\^みヤルt◀ヒよ➡️`[v◜a█jz◝●aとgョ‖\+し_ン‖\^しにルuwノ○ケˇ゜q◝り@nu◝\*eや\*◝j\*ヲ\vュ‖\vル゜ハさ•ケ○█t/カ◜@q◝b◜\+\*◜gヲ\0\#◜[ヲ\|\aン•ホ⁘\aン_ヲx\aレoュ‖\# レ_ヲ\+\*ヲ゜◜a\0ョ•◝\+aや\a◝▮@~a◝▒p゜🐱よユ\0+ルoンu\aユ\015◝█\*よさよ█し?█○◜p\*◜oョ\0◀◝\0◝ッ@\tqにュ▮\aッ\|◝シ\0.ヌヤ ョ\-オゆ\#◝ン\0¥レ゜◝\0qゆ\*◝ン\0\nユ\015◝オ\0゜@よ◝\0\0◝\0◝ャ\*\*ユ•◝ユ\#\aユ\015◝ら\r_ナ゜oナ\|\vオ○◝\0.に\0>よ@$?▒ョ○@to\*ュ◝\0ナよ\*ル◝\*ら○\-ユョ\-らョ\-ラュ\#█ュ\015ネュ\a\0ヲ/んユ゜\-ナ/[ユ\v\vユ?♥ル\v\vユ/kユ\*\aル゜タュ\#\-ヲ゜クュ\*aュ\aマョ\0@よ\aル◝\0▮?\aン○\#…>\#ョ○@ひ?\*ュ/ユ\#\015ユ'⬅️◝\0らよ\nルよニ\b\#ユにf◝\0█o\nルにル\*\aユ_⬇️◝ら ▶り~•◜\#\*=\vニ◝ル\0\-ノ○w◝ら\0\v…ゆo◝\*`。🐱レ_◝\0\0むoホ○ュ\0@ま\a➡️○ュ\0\-ち]ロよョ\*█や\+ヨ○ョ\0▮⬇️█<つ◝\0\07わ]○◝ら\*▶ナあ[◝ひ\-さョ▶ゆ◝ョ\0 u\+yよ◝\0▮&●i○◝ユ@\015uコgよヲ\0a゛uフ◝◝@@\nyv◝◝そb\^maに◝◝t@り■\|j◝h 1\015\\z◝◝|@❎y^ャよ◜や\*ハouみャ◝ヲ\0\+ˇug◝◝キ…‖pˇzつ◝た\|\0わ[ち◝◝◝▥◀vuzˇちつッeナ◀aさjミ◝か🐱ケ\tuちちめ◝マ}@めあたeつモつf`uu▥あkむ◜.ら&ueuちちたけき\|qjメめ◝◝◝よ⬆️eyくujたち_ヲ•\|yくˇieすちッ●サoすしちちすちつくd[ˇiちつたjちよッちjちuufちueちˇしiす➡️vˇちちに◝◝ヤつみvˇ‖uujˇ▥uuたちちjしzちちちちjちちちよッちちたˇuuuejちちちちちちちちちちちちちちちちちちuしjˇzたzちちちjちちちちちた∧ちちちちちちちちちちちちちちちちたuuvちちちちちちちちちちちちちちちちああたuuuvたjちちちちちちちちちちˇuvちちちちちちちちちち ちちちちちちちˇuuuuvzちちちちちちちちちちちしuuuuちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちち ちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちちち",
}

usrdta = 0x4300
dtalen = 2048
dtaend = usrdta+dtalen

function unpacksnds()
	for k,v in pairs(brosnd) do
		bytes = {ord(v,1,#v)}
		samples = {}
		for b in all(bytes) do
			for shift=6,0,-2 do
				bits = (b>>shift) & 3
				add(samples,amp[bits])
			end
		end
		brosnd[k] = samples
	end
end

function playsnd(snd)
	adr = usrdta
	for sam in all(snd) do
		poke(adr,sam)
		adr += 1
		if adr == dtaend then
			serial(0x808,usrdta,dtalen)
			while stat(108)!=0 do end
			adr = usrdta
		end
	end
	remains = adr-usrdta
	serial(0x808,usrdta,remains)
	while stat(108)!=0 do end
end

unpacksnds()
for k,v in pairs(brosnd) do
	playsnd(v)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000