pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- bros
-- je-soft

-- 0 bros
-- 1 movement
-- 2 entities
-- 3 levels
-- 4 hiscores
-- 5 font
-- 6 swap
-- 7 encoded

-- sprite flags
f = {
	coll=0,
	brks=1,
	pipe=2,
	bonk=4,
	coin=5,
	powr=6,
}

-- game
g = {
	score=0,
	coins=0,
	lives=3,
	timer=0,
	fungus=false,
	wep=0,
}

-- sprite codes
s = {
	bg=1,
	bro=2,
	bbro=7,
	timer=14,
	fguy=17,
	emptyblock=42,
	coin=59,
	shroom=61,
}

-- state
staupdate = nil
stadraw = nil

sndp = {
	snd=nil,
	len=0,
	sam=1,
	adr=usrdta,
	done=false,
	play=false,
	stime=0,
}

wait = {
	f=0,
	call=nil,
}
-- bg colour
bc = 12
-- text colour
tc = 9
-- sound memory block
usrdta = 0x4300
dtalen = 2048
dtaend = usrdta+dtalen
amp = {
	[0]=159,
	[1]=143,
	[2]=127,
	[3]=111,
}

function _init()
	bbs = false
	if not bbs then
		extcmd("set_title","BROS")
	end
	palt(0,false)
	color(tc)
	menuinit()
	loadfont()
	initscores()
	unpacksnds()
	mainscreen()
end

function _update60()
--	debugstats()
	if sndplaying()
			or updatewait() then
		return
	end
	updatecode()
	staupdate()
end

function _draw()
	stadraw()
end

function debugstats()
	printh("")
	printh(time())
	printh("p.x"..pad(p.x,3))
	printh("p.y"..pad(p.y,3))
	printh("p.jump"..p.jump)
	printh("p.jtick"..p.jtick)
end

function menuinit()
	menuitem(
		1,
		"! delete save",
		function ()
			resetgame()
			savegame()
			mainscreen()
		end
	)
	menuitem(
		2,
		"? bros tutorial",
		helpscreen
	)
end

function updatewait()
	if wait.f > 0 then
		if wait.f == 1 then
			wait.f = 0
		 wait.call()
		elseif btnp(β) or btnp(πΎοΈ) then
			wait.f = 1
		else
			wait.f -= 1
		end
		return true
	end
	return false
end

-- sampled sound playing
function unpacksnds()
	for k,v in pairs(snd) do
		bytes = {ord(v,1,#v)}
		samples = {}
		for b in all(bytes) do
			for shift=6,0,-2 do
				bits = (b>>shift) & 3
				add(samples,amp[bits])
			end
		end
		snd[k] = samples
	end
end

function sndplaying()
	-- no sound active
	if not sndp.play then
		return false
	end
	-- skip sound
	if btnp(β) then
		sndp.play = false
		return false
	end

	-- wait for buffer
	if stat(108) != 0 then
		return true
	end

	if sndp.done then
		sndp.done = false
		sndp.play = false
		return false
	end

	-- fill memory
	while sndp.sam < sndp.len do
		local sam = sndp.snd[sndp.sam]
		poke(sndp.adr,sam)
		sndp.adr += 1
		sndp.sam += 1
		if sndp.adr == dtaend then
			sndp.adr = usrdta
			-- play if full
			serial(0x808,usrdta,dtalen)
			return true
		end
	end

	local remains = sndp.adr-usrdta
	sndp.done = true
	serial(0x808,usrdta,remains)
	return true
end

function psnd(snd)
	sndp.snd = snd
	sndp.len = #snd
	sndp.sam = 1
	sndp.adr = usrdta
	sndp.play = true
	sndp.stime = time()
end

-- help screen
function updatehelpscreen()
	if mbtnp(πΎοΈ,β) then
		mainscreen()
	end
end

function helpscreen()
	staupdate = updatehelpscreen
	stadraw = function() end
	map(0,16)
	music(-1)
	wait.f = 15 * tick
	wait.call = drawhelpscreen
end

function drawhelpscreen()
	map(32,16)
	music(24)
	helptext = {
		{"gameplay",44},
		{"β¬οΈβ‘οΈ : move",36},
		{"β¬οΈπΎοΈ : jump",36},
		{"11 coins : 1up",20},
		{"mushroom : break bricks",20},
		{"",0},
		{"hiscore",44},
		{"β¬οΈβ‘οΈ : cursor",36},
		{"β¬οΈβ¬οΈ : letter",36},
		{"β : discard",44},
		{"πΎοΈ : record",44},
	}
	local y = 16
	for t in all(helptext) do
		print(t[1],t[2],y)
		y += 8
	end
end

-- top bar rendering
function pad(num, digits)
	padded = tostr(num)
	for i=1,digits-#padded do
		padded = "0"..padded
	end
	return padded
end

function drawtimer()
	rectfill(86,8,98,15,bc)
	color(tc)
	print(ceil(g.timer),86,8)
end

function drawtopbar()
	rectfill(0,8,127,15,bc)
	color(tc)
	print(pad(g.score,5),2,8)
	spr(s.coin,22,8)
	print(pad(g.coins,2),32,8)
	spr(s.bbro,40,8)
	print(g.lives,50,8)
	print("lvl",56,8)
	print(l.world..l.stage,68,8)
	spr(s.timer,76,8)
	drawtimer()
	if g.fungus then
		spr(s.shroom,100,8)
	end
	spr(62,110,8)
	print(pad(g.wep,2),118,8)
end

function updatemainscreen()
	enticki(2)
	if btnp(πΎοΈ) then
		levelscreen()
	elseif btnp(β) then
		scorescreen()
	end
end

function drawmainscreen()
	spr(25+3*enspr,8,48,1,1)
	spr(19+enspr,104,72,1,1,enspr==1)
end

function mainscreen()
	staupdate = updatemainscreen
	stadraw = drawmainscreen
	cls(bc)
	map(0,16)
	music(24)
	drawtopbar()
	spr(2,112,48,1,1,true)
	print("00",90,8)
	print("πΎοΈ:play",4,104)
	print("β:screen",44,104)
	print("β:scores",88,104)
	mspr = 0
	mtick = 0
end

-->8
-- movement

tick = 2
-- walk
wtickl = 1 * tick
-- stop walk
stickl = 2 * tick
-- up jump
utickl = 2 * tick
-- down fall
dtickl = 1 * tick
-- refill jump on floor
rtickl = 2 * tick
-- bonk
btickl = 4 * tick
-- apex of jump
atickl = 0 * tick

jumpmax = 5
coyotemax = 2

p = {
	x=0,
	y=0,
	l=false,
	wspr=0,
	wtick=0,
	jtick=0,
	jump=jumpmax,
	coyote=0,
}


function drawbro()
	local sprn = 2
	if 0 < p.jump
			and p.jump < jumpmax then
		sprn = 5
	elseif p.wspr != -1 then
		sprn = 3 + p.wspr
	end
	spr(sprn,p.x,p.y,1,1,p.l)
end

function updatewalk()
	if p.wtick > 0 then
		p.wtick -= 1
		return
	end

	local lb = btn(β¬οΈ)
	local rb = btn(β‘οΈ)

	if lb and rb
			or not (lb or rb) then
		p.wspr = -1
		return
	end

	p.wspr += 1
	p.wspr %= 2

	if lb then
		p.l = true
		if lcol() or p.x<=0 then
			p.wtick = stickl
		else
			p.wtick = wtickl
			p.x -= 4
		end
	end
	if rb then
		p.l = false
		if rcol() or 120<=p.x then
		 p.wtick = stickl
		else
			p.wtick = wtickl
			p.x += 4
		end
	end
end

function updatejump()
	if p.jtick > 0 then
		p.jtick -= 1
		return
	end
	p.y += 8

	p.jtick = dtickl
	dl,dm,dr = ycol(p.x,p.y)
	if yft(dl,dm,dr) then
		p.y -= 8
		p.coyote = coyotemax
		if p.jump == 1 then
			p.jump = jumpmax
			p.jtick = rtickl
			return
		else
			p.jtick = 0
		end
	end

	if 1 < p.jump then
		if btn(β¬οΈ) or btn(πΎοΈ) then
			p.y -= 16
			p.jtick = utickl
			if p.jump == jumpmax then
				p.y += 8
				sfx(56)
			elseif p.jump == 3 then
				p.jtick = atickl
				p.wtick = 0
			end
			p.jump -= 1
			ul,um,ur = ycol(p.x,p.y)
			if yft(ul,um,ur) then
				p.y += 8
				p.jtick = btickl
				bonk(ul,um,ur)
			end
		elseif p.jump < jumpmax then
			p.jump = 1
			sfx(56,-2)
		end
		return
	end

	-- coyote time
	if p.jump==jumpmax and not dcol() then
		if 0 < p.coyote then
			p.coyote -= 1
		else
			p.jump = 1
		end
	end
end

-- collision
function ccollide(x,y)
	return mget(x/8,y/8)
end

function yft(cl,cm,cr)
	if cm != nil then
		return fget(cm,f.coll)
	else
		return fget(cl,f.coll)
			or fget(cr,f.coll)
	end
end

function xft(cx)
	return fget(cx,f.coll)
end

function ycol(x,y)
	-- returns left,middle,right
	if x % 8 == 0 then
		local cm = ccollide(x,y)
		return nil,cm,nil
	else
		local cl = ccollide(x-4,y)
		local cr = ccollide(x+4,y)
		return cl,nil,cr
	end
end

function xcol(x,y)
	if x % 8 != 0 then
		return s.bg
	else
		return ccollide(x,y)
	end
end
function lcol()
	return xft(xcol(p.x-8,p.y))
end
function rcol()
	return xft(xcol(p.x+8,p.y))
end

function checkfall()
	if (p.y > 104) die()
end

function updatemovement()
	updatewalk()
	updatejump()
	checkfall()
end

-->8
-- entities

coin={
	x=0,
	y=0,
	lifet=0,
	show=false,
	sprn=59,
}
fungus={
	x=0,
	x=0,
	show=false,
	sprn=61,
}
fguy={
	x=0,
	y=0,
	l=true,
	wtick=0,
	jtick=0,
	show=false,
	sprn=17,
}

enspr = 0
entick = 0

function enticki(freq)
	if entick == 0 then
		entick = freq * tick
		enspr += 1
		enspr %= 2
	else
		entick -= 1
	end
end

function coinup()
	g.score += 10
	g.coins += 1
	if g.coins >= 11 then
		g.lives += 1
		g.coins = 0
	end
	drawtopbar()
end

function bonk(ul,um,ur)
	-- called in updatejump()
	local cachedjump = p.jump
	p.jump = 1

	-- between two blocks
	-- no bonk interaction
	if um == nil then
		if xft(ul) then
			sprn = ul
		elseif xft(ur) then
			sprn = ur
		end
		if fget(sprn,f.bonk) then
			psnd(snd.bonk)
		end
		return
	end

	-- popout
	sprn = um
	local x = p.x
	local y = p.y - 8
	local mx = x / 8
	local my = y / 8

	if fget(sprn,f.coin) then
		psnd(snd.coin)
		coin.x = p.x
		coin.y = p.y-16
		coin.show = true
		coin.lifet = 5*tick
		mset(mx,my,s.emptyblock)
	elseif fget(sprn,f.powr) then
		psnd(snd.coin)
		fungus.x = p.x
		fungus.y = p.y-16
		fungus.show = true
		g.score += 100
		drawtopbar()
		mset(mx,my,s.emptyblock)
	elseif g.fungus
			and fget(sprn,f.brks) then
		p.jump = cachedjump
		psnd(snd.brks)
		g.score += 25
		drawtopbar()
		mset(mx,my,s.bg)
	elseif fget(sprn,f.bonk) then
		psnd(snd.bonk)
	end
end

function updatecoin()
	if coin.show then
		if coin.lifet == 0 then
			coin.show = false
			coinup()
		else
			coin.lifet -= 1
		end
	end
end

function updatefungus()
	if fungus.show then
		if fungus.x==p.x and fungus.y==p.y then
			g.fungus = true
			fungus.show = false
			drawtopbar()
			psnd(snd.eats)
		end
	end
end

function updatefguy()
	if (not fguy.show) return

	-- player interaction
	if abs(p.x-fguy.x) <= 4 then
		if p.y - fguy.y == 0 then
			if p.jump==1
					or (p.coyote!=0 and not yft(ycol(p.x,p.y))) then
				--stomped on
				fguy.show = false
				g.score += 100
				drawtopbar()
				psnd(snd.kill)
			else
				die()
			end
		end
	end

	-- fall
	if fguy.y > 108 then
		fguy.show = false
	end
	dl,dm,dr = ycol(
		fguy.x,fguy.y+8
	)
	if not yft(dl,dm,dr) then
		if fguy.jtick == 0 then
			fguy.jtick = tick
			fguy.y += 8
		else
			fguy.jtick -= 1
		end
		return
	end

	-- walk
	if fguy.wtick == 0 then
		fguy.wtick = 8*tick
		if fguy.l then
			cl = xcol(fguy.x-8,fguy.y)
			if not xft(cl) then
				fguy.x -= 4
			else
				fguy.l = false
				fguy.x += 4
			end
		else
			cr = xcol(fguy.x+8,fguy.y)
			if not xft(cr) then
				fguy.x += 4
			else
				fguy.l = true
				fguy.x -= 4
			end
		end
	else
		fguy.wtick -=1
	end
end

function drawentities()
	for en in all({coin,fungus}) do
		if en.show then
			spr(en.sprn,en.x,en.y)
		end
	end

	for en in all({fguy}) do
		if en.show then
			local sprn = en.sprn
			sprn += enspr
			spr(sprn,en.x,en.y,1,1,en.l)
		end
	end
end

function checkcoin()
	if xcol(p.x,p.y)==s.coin then
		psnd(snd.coin)
		mset(p.x/8,p.y/8,s.bg)
		coinup()
	end
end

function updateentities()
	enticki(4)
	checkcoin()
	updatecoin()
	updatefungus()
	updatefguy()
end

-->8
-- levels

l = {
	world=1,
	stage=1,
	screen=1,
	scrn=1,
	-- player start coords
	px=0,
	py=0,
}
offset=2

compress = {}
compress[s.bg] = true

function resetgame()
	g.score = 0
	g.coins = 0
	g.lives = 4
	g.timer = 999
	-- todo reset from debugging
	l.world = 1
	l.stage = 1
	l.screen = 1
	l.scrn = 1
end

function levelscreen()
	loadgame()
	levelmusic()
	loadlevel()
	resetp()
	wait.f = 5 * tick
	wait.call = levelstart
end

function levelstart()
	staupdate = updatelevel
	stadraw = drawlevel
	cls(bc)
	drawtopbar()
end

function decodescreen(scrn)
	-- spawn defaults
	l.px = 0
	l.py = 96

	scrc = screens[scrn]
	scrd = {ord(scrc,1,#scrc)}
	local x = 0
	local y = offset
	local i = 1
	while i < #scrd do
		sprn = scrd[i]
		if compress[sprn] then
		 i += 1
			reps = scrd[i]
			for j=1,reps do
				mset(x,y,sprn)
				x,y = nextm(x,y)
			end
		else
			sprn = submtile(sprn,x,y)
			mset(x,y,sprn)
			x,y = nextm(x,y)
		end
		i += 1
	end
end

function submtile(sprn,x,y)
	if sprn == s.bro then
		sprn = s.bg
		l.px = 8*x
		l.py = 8*y
	elseif sprn == s.fguy then
		sprn = s.bg
		fguy.x = 8*x
		fguy.y = 8*y
		fguy.l = true
		fguy.show = true
	end
	return sprn
end

function nextm(x,y)
	x += 1
	if 15 < x then
		x = 0
		y += 1
	end
	return x,y
end

function mbtnp(...)
	for b in all({...}) do
		if (btnp(b)) return true
	end
	return false
end

function updatewinscreen()
	if mbtnp(β,πΎοΈ) then
		wait.f = 1
	end
end

function win()
	staupdate = function() end
	stadraw = function() end
	map(48,16)
	spr(20,56,96,1,1,true)
--	local y = 44
--	print("s o r r y",44,y)
--	local t
--	t = "but your brother is in"
--	print(t,16,y+16)
--	print("another castle")
	local y = 44
	print("thank you mario!",24,y)
	local t
	t = "but your \015bros\014 is still"
	print(t,16,y+16)
	print("in development!")
	wait.f = 120 * tick
	wait.call = mainscreen
end

function levelup()
	l.scrn += 1
	if #screens < l.scrn then
		win()
		return
	end

	l.screen += 1
	if l.screen > 5 then
		l.screen = 1
		l.stage += 1
		g.timer = 999
	end
	if l.stage > 4 then
		l.stage = 1
		l.world += 1
	end

	savegame()
	drawtopbar()
	loadlevel()
end

function levelmusic()
	music(((l.stage-1)%3)*8)
end

function loadlevel()
	coin.show = false
	fungus.show = false
	fguy.show = false
	if l.screen == 1 then
		levelmusic()
	end
	decodescreen(l.scrn)
	p.x = l.px
end

function checklevelup()
	if btn(β‘οΈ) and p.wtick==0 then
		if l.screen == 5 then
			tright = xcol(p.x+8,p.y)
			if fget(tright,f.pipe) then
				levelup()
			end
		else
			if (120 <= p.x) levelup()
		end
	end
end

function resetp()
	p.x = l.px
	p.y = l.py
	p.l = false
end

function die()
	stadraw()
	stadraw = function() end
	spr(6,p.x,p.y)
	flip()
	psnd(snd.dies)
	g.lives -= 1
	g.fungus = false
	wait.f = 1
	wait.call = respawn
end

function respawn()
	g.timer = 999
	drawtopbar()
	if g.lives == 0 then
		gameover()
	else
		stadraw = drawlevel
	 resetp()
	end
end

function gameover()
	map(20,22,32,40,9,5)
	print("game  over",44,56)
	wait.f = 60 * tick
	wait.call = dieforever
end

function dieforever()
 h.rank = rankscore(g.score)
	if h.rank != 11 then
		askname()
	else
		mainscreen()
	end
	resetgame()
	savegame()
end

function updatetimer()
	if g.timer == 0 then
		die()
	else
		g.timer -= 0.5/tick
	end
end

function debugdie()
	if (btnp(β)) die()
end

function updatelevel()
	debugdie()  -- todo remove
	checklevelup()
	updatetimer()
	updatemovement()
	updateentities()
end

function drawlevel()
	map()
	drawentities()
	drawtimer()
	drawbro()
end

-->8
-- hiscores

-- data layout
-- 01 to 10 top scores
-- 11 to 41 3 nums per name
-- 42 to 50 save game

h = {
	ords={32,32,32},
	chrs={" "," "," "},
	curs=1,
	rank=0,
}

function loadgame()
	g.score,
	g.coins,
	g.lives,
	g.timer,
	l.world,
	l.stage,
	l.screen,
	l.scrn
		= peek4(0x5ea0,8)
	-- 0x5e00 + 40 * 4
end

function savegame()
	poke4(
		0x5ea0,
		g.score,
		g.coins,
		g.lives,
		g.timer,
		l.world,
		l.stage,
		l.screen,
		l.scrn
	)
end

function initscores()
	loaded = cartdata("bros_sorb")
	if not loaded then
		for i=1,10 do
			savename(i,"   ")
		end
		resetgame()
		savegame()
	end
end

function nameaddr(i)
	-- 0x5e00 + 10 * 4
	return 0x5e28 + i * 12
end

function loadname(i)
	addr = nameaddr(i)
	name = chr(peek4(addr,3))
	return name
end

function savename(i,name)
	addr = nameaddr(i)
	n1,n2,n3 = ord(name,1,3)
	poke4(addr,n1,n2,n3)
end

function rankscore(num)
	for i=1,10 do
		if num > dget(i) then
			return i
		end
	end
	return 11
end

function shiftscores(rank)
	for i=10,rank,-1 do
		j = i-1
		score = dget(j)
		dset(i,score)
		name = loadname(j)
		savename(i,name)
	end
end

function savescore()
	hc = h.chrs
	name = hc[1]..hc[2]..hc[3]
	shiftscores(h.rank)
	dset(h.rank,g.score)
	savename(h.rank,name)
end

function askname()
	staupdate = updatenameentry
	stadraw = drawnameentry
	cls(bc)
	drawtopbar()
	print("great score",42,40)
	print("enter your name",34,56)
end

function drawnameentry()
	rectfill(58,72,70,86,bc)
	color(tc)
	for i=1,3 do
		print(h.chrs[i],54+4*i,72)
	end
	print(":",54+4*h.curs,80)
end

function updatenameentry()
	if btnp(πΎοΈ) then
		savescore()
	end
	if btnp(β) or btnp(πΎοΈ) then
		scorescreen()
	end

	-- cursor
	c = h.curs
	if btnp(β‘οΈ) and c < 3 then
		h.curs += 1
	end
	if btnp(β¬οΈ) and 1 < c then
		h.curs -= 1
	end

	-- character
	for b,v in pairs({[2]=1,[3]=-1}) do
		if btnp(b) then
			h.ords[c] += v
			hoc = h.ords[c]
			bounds={[31]=122,[33]=97,[96]=32,[123]=32}
			for f,t in pairs(bounds) do
				if (hoc==f) h.ords[c]=t break
			end
			h.chrs[c] = chr(h.ords[c])
		end
	end
end

function scorescol(x,rank)
	y=48
	print("nr score name",x,y)
	for i=rank,rank+8,2 do
		y += 8
		score = dget(i)
		name = loadname(i)
		print(pad(i,2),x,y)
		print(pad(score,5),x+12,y)
		print(name,x+40,y)
	end
end

function updatescorescreen()
	if btnp(β) or btnp(πΎοΈ) then
		mainscreen()
		g.score = 0
	end
end

function scorescreen()
	staupdate = updatescorescreen
	stadraw = function() end
	cls(bc)
	drawtopbar()
	print("00",90,8)
	t = "h i g h s c o r e s :"
	print(t, 20, 28)
	scorescol(8,1)
	scorescol(64,2)
end

-->8
-- font

function sprtochar(sprn)
	-- sprn is sprite number
	-- convert sprite n to custom
	-- font format and return
	-- as table of 8 bytes
	char = {}
	x,y = sprnxy(sprn)
	for i=0,7 do
		a = i + 1
		char[a] = 0
		for j=0,7 do
			if sget(x+j, y+i) == 7 then
				char[a] |= 2^j
			end
		end
	end
	return char
end

function fblock(src, dest, len)
	--font copy block
	--src is sprite number
	--dest is p8scii code
	daddr = 0x5600 + dest * 8
	for i=1,len do
		char = sprtochar(src)
		poke(daddr, unpack(char))
		src += 1
		daddr += 8
	end
end

function loadfont()
	-- load custom font from sprite
	-- sheet and activate it

	--letters, numbers
	fblock(64,97,26)
	fblock(96,48,10)
	--symbols
	dests = {21,45,58,131,139,142,145,148,151,33}
	for i=1,#dests do
		fblock(111+i,dests[i],1)
	end

	--switch and metadata
	poke(0x5f58,0x1 | 0x80)
	poke(0x5600,4,8,8)
end

-->8
-- swap

function sprnxy(sprn)
	x = (sprn%16)*8
	y = flr(sprn/16)*8
	return x,y
end

function getspr(sprn)
	x,y = sprnxy(sprn)
	sprite = {}
	for i=0,7 do
		sprite[i] = {}
		for j=0,7 do
			sprite[i][j] = sget(x+i,y+j)
		end
	end
	return sprite
end

function setspr(sprn,sprite)
	x,y = sprnxy(sprn)
	for i=0,7 do
		for j=0,7 do
			sset(x+i,y+j,sprite[i][j])
		end
	end
end

function swapspr(sprna,sprnb)
	spra = getspr(sprna)
	sprb = getspr(sprnb)
	setspr(sprna,sprb)
	setspr(sprnb,spra)
end

function along()
	for i=1,3 do
		swapspr(i,36+i)
	end
	swapspr(10,40)
	music(60)
end

pachinko = {2,2,3,3,0,1,0,1,5,4}
codestep = 1
function updatecode()
	if (btn()==0) return

	req = pachinko[codestep]
	for btnid=0,5 do
		if btnp(btnid) then
			if btnid==req then
				codestep +=1
			else
				codestep = 1
				return
			end
		end
	end

	if codestep > #pachinko then
		codestep = 1
		along()
	end
end

-->8
-- encoded

snd = {
	coin="γγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γγβ₯γ[\-0\0\|Pγβ¬οΈ\0\f4003γ―γ\015\014,γγγγγγ―γγγγx8xxkγγͺγ¨γ€πΎοΈβi*γγγγγγγ-l8-γ‘fF@\*\nγnγ¬8uγγΈγ­β‘οΈZβm,it*βγ‘γΏγ½Λβhittγγγβ¬οΈβN^mjγ‘γ»γ―γγγ΅γYl-)((\|jβγ©β¬οΈJμβ?βΆhΒ₯γΒ₯!iγγββγ^jffγγγγ‘γ‘γ‘iiijγ‘γ‘γγγ³γ΅γ€γ‘γ‘γ‘γ‘γ‘γγ‘γγγ‘γ‘γ‘γ‘γβ§γ‘γ‘γ‘γ‘γ‘γ‘γγγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γΏ\tγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘",
	kill="γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ\0\0\0ββγ―^βββββγ²@\0\0\0\0\0β UUVγ‘YΛP\0\0\0\+βββγ₯\0\0\0?βββγ\0\0\0\0\0\+UUiUUγ‘jγ‘R(@\0\0@γ£γ\0?γ¦\0γβββββγ\0\0\0\0\0\0\0\*UZγ‘β§γTE@\+\*\|\*γ»β\0γ\0\0Cβββββ\0\0\0\0UUjγγ‘UUUUUγd%H\0\0\0Rγ€γΉ9\-γ \*ββββγ§βfγT\0\0\0\+Tγ£γββl%@\0\0\0β?\+\0$γββ\-βββββ‘οΈUA\0\0\0/β$γββP\0βγ‘γ‘γΛUUUUγ‘@\0\0\"β",
	bonk="γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘Λγ‘γ‘γ‘γUZγ‘γ€γUZγγγUZγUoγ§P\*oγjγ²cΛγ§\aEγββ¬οΈ\*eγ?βγ\t\0γ§\aγβγβ¦\aβ¬οΈβγZγ³U@U\#βγ«β@\0Fγ‘γΏγβγ³\0\0Vβγγ‘βγ³@\0\^βγ‘γβγ³@\0[βγjββ\0\0\vβγΏZββγ\0\0γ€γUoβγγ\0\+γγ‘γββγΛD\*βγβββγγ«\0\0Vγ€βγ«γ€βU@\0\|Eγγ«ββγγU\0T*Uγ‘γ€γγjΛUUγ‘γ€γβγγ€γi\0P\+Uijγ‘γ‘γγγ‘β§γUUjγ‘γ‘γ‘γ‘γjβ§γ€γ‘γVUγUVγ‘γ‘γ‘γ‘γ‘γ‘γ‘β§γYUiZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γγ‘γ‘γ‘γ‘γUUUγ‘γUeZΛUZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘ΛZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘Λjγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γUUUUZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘ΛZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘jγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘UUUγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘",
	dies="γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γjγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘jγ‘γ‘γ‘jγγγ‘γjγγ‘γ‘Uγ‘γ‘γ‘γVγ‘γ‘γUoγ‘γZVγ³γ‘UγoγγZUβγ‘ΛγoγγZUγjΛγoγ‘γiFγγVβ¦γγ€Λγβ’γγ³Β₯Aγ§nAγoβ§γoβ§γ³UVγγ«ΛUoγγ§βAγoγTγγββA~γ€γ³U\^γΏγγPΒ₯γβUAγ¨βγ§U\^γΏγ€γ«Tβγγβ‘οΈ`[VβaβjZββAγ¨gγ§β\+γ_γ³β\^γγ«γ«UWγβγ±ΛγQβγ@nUβ\*Eγ\*βJ\*γ²\vγ₯β\vγ«γγγβ’γ±ββT/γ«β@QβBβ\+\*βGγ²\0\#β[γ²\|\aγ³β’γβ\aγ³_γ²X\aγ¬oγ₯β\#γ¬_γ²\+\*γ²γβA\0γ§β’β\+Aγ\aββ?@~AββPγπ±γγ¦\0+γ«oγ³U\aγ¦\015ββ\*γγγβγ?βββP\*βoγ§\0ββ\0βγ@\tQγ«γ₯β?\aγ\|βγ·\0.γγ€γ§\-γͺγ\#βγ³\0Β₯γ¬γβ\0Qγ\*βγ³\0\nγ¦\015βγͺ\0γ@γβ\0\0β\0βγ£\*\*γ¦β’βγ¦\#\aγ¦\015βγ\r_γγoγ\|\vγͺββ\0.γ«\0>γ@$?βγ§β@to\*γ₯β\0γγ\*γ«β\*γβ\-γ¦γ§\-γγ§\-γ©γ₯\#βγ₯\015γγ₯\a\0γ²/γγ¦γ\-γ/[γ¦\v\vγ¦?β₯γ«\v\vγ¦/Kγ¦\*\aγ«γγΏγ₯\#\-γ²γγ―γ₯\*Aγ₯\aγγ§\0@γ\aγ«β\0β??\aγ³β\#β¦>\#γ§β@γ²?\*γ₯/γ¦\#\015γ¦'β¬οΈβ\0γγ\nγ«γγ\b\#γ¦γ«Fβ\0βo\nγ«γ«γ«\*\aγ¦_β¬οΈβγ βΆγ~β’β\#\*=\vγβγ«\0\-γβWβγ\0\vβ¦γoβ\*`γπ±γ¬_β\0\0γOγβγ₯\0@γΎ\aβ‘οΈβγ₯\0\-γ‘]γ­γγ§\*βγ\+γ¨βγ§\0β?β¬οΈβ<γ€β\0\07γ]ββγ\*βΆγγ[βγ²\-γγ§βΆγβγ§\0 U\+Yγβ\0β?&βiββγ¦@\015uγ³Gγγ²\0Aγuγββ@@\nYVββγB\^maγ«ββT@γβ \|jβH 1\015\\zββ|@βY^γ£γβγ\*γOUγΏγ£βγ²\0\+ΛUgββγ­β¦βPΛZγ€βγ\|\0γ[γ‘ββββ₯βVUZΛγ‘γ€γEγβAγjγβγπ±γ±\tUγ‘γ‘γβγ}@γγγeγ€γ’γ€f`UUβ₯γkγβ.γ&UeUγ‘γ‘γγγ\|Qjγ‘γβββγβ¬οΈEYγUjγγ‘_γ²β’\|yγΛieγγ‘γβγ΅oγγγ‘γ‘γγ‘γ€γd[Λiγ‘γ€γjγ‘γγγ‘jγ‘UUfγ‘Ueγ‘Λγiγβ‘οΈVΛγ‘γ‘γ«ββγ€γ€γΏVΛβUUjΛβ₯UUγγ‘γ‘jγZγ‘γ‘γ‘γ‘jγ‘γ‘γ‘γγγ‘γ‘γΛUUUejγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘UγjΛZγZγ‘γ‘γ‘jγ‘γ‘γ‘γ‘γ‘γβ§γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γUUVγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γγγUUUVγjγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘ΛUVγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘ΛUUUUVZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γUUUUγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘",
	brks="|Oγ‘γzYnaiγγ¦γ³z*γmIγd[fβ§fZβ§γβ§jγVγjmWγ‘Zβ§β₯jfjkβγγβγ‘P\0\0\0\0@&β₯γγ£γ€βγ’γγ‘γUβΛIγβγjγγγ½γͺγ­]γ€γ}γγz&βiγγ‘γ΅Vγ£jYUjβ₯uγiγfγ‘ejiγ΅γγγγv]γ‘Jγ»γ¨*Λγγβ§γγ΅γjγ‘γ‘β¬οΈjγ‘Zγ‘γ‘γγ‘γjZγγγ¦γγ:Zγ‘γ‘γAβ§γγYγγ‘γ‘γ‘γγ‘γ‘γ‘γ‘β§γ‘γγ‘γγ‘ZγZγ‘γ‘0βγZjγfγjγγ‘γγ‘γ‘γ‘γγγ‘γ‘^Yγmjγ‘γ‘γ‘jγ‘γ‘jγγ‘γ‘jγ‘γ‘γjγ‘γ‘γγγγ‘γ‘γ‘γ‘γ‘γ‘γγγ‘γ‘γ‘γγ‘γγγ‘γjZγγ‘γ‘γ‘γ‘γγγeγ‘γγβ§γjZjγγ‘γγγγ‘γγ‘β₯β§γjγ‘γ‘γγγγγ‘γ‘jγ‘γγ‘γ‘γ‘γγ‘jγγ‘γ‘γγeγ‘γ‘γγjγγ‘γ‘γ‘Zγ‘γ‘γ‘γγ‘γ‘γ‘jjγ‘γγ‘γ‘iγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘",
	eats="γ‘γ‘γ‘γ‘γ‘γ‘γγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γZγγ‘Vγ‘γ‘γ‘γ‘γ‘Λγ‘γ‘γ‘γ‘γ‘γγ‘β§γVγ‘γ‘β§γ‘γ‘γ‘γ‘γ‘β₯jΛγ‘Vγ‘γγ‘γ‘γ‘γVγ²Vβ¦γVγ«γͺ[γγγγ\*γβ’β¦iVγγ‘ΛUγ‘γ€Yγͺγ‘γ‘Λγ‘VγjΛγ‘Vγγ‘γjγjγ‘γͺjγͺZγoβγVγjΛjVγ‘γ€γoγjUγVγVγjγγEγ‘γ‘γ‘γ‘γ€βγVγUγUZγ‘γVγ‘γ‘γ‘γ‘γ€γγkγ\^γ³\+γZγγ‘γ‘γ‘γγ‘γUUγ‘γUγ‘Λγ‘γ‘ββγUUUUVγ‘γ‘βγ‘γUUUUZγ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘γ‘",
}

screens = {
	"\*v!+!+!+!\*#\#\*\015                                ",
	"\*<β \*\v!+!+!\*:!+!+!+!\*β‘\#\*\015                                ",
	"\*Jβ \*\n!+!!-!\**!+!!+!\*\aβΆγ\*\f\#\*\*'(\*\f  '(         \*\#   '(         \*\# ",
	"\*K!!\*\*!,\*+!+!+!\*\-*\*\#*\*\v**\*\#**\*\b\#***\*\#***\*\^β     \*\#              \*\#          ",
	"\*);;;;\*\f;;;;\*\f;;;;\*\nβ \*\*;;;;\*\n*\*\014**\*\r***\*\f****\*\^$%\*\-*****\*\^45        \*\-             \*\-     ",
	"\* !!\*\#!!!!!!!!!!!!!!\*\f!!!!\*\f!!!!\*\|!+!+!\*\-!!!!\*\014!!\*\014!!\*\-!+!+!-!\*\|!!\*\014!!\#\*\fβ                                ",
	"\* !!!!!!!!!!!!!!!!!\*\v;;;!!\*\v;;;!!\*\v!!!!\*\^,\*β’βΆγ\*\+βΆγ\*\a'(\*\+'(\*\a'(\*\|β '(\*\+                                ",
	"\* !!!!!!!!!!!!!!!!!!\*\r!!!\*\|;;;;\*\+!!!\*\r!\*γβ\*\t*\*\#****\*\-*\*\|**\*\#****\*\-**\*\#***\*\#****\*\-***    \*\#    \*\-       \*\#    \*\-   ",
	"\* !!!!!!!!!!!!!!!!\*\+!!!!!!!!!!!;;;;\*\*!!!\*\b;;;;\*\*!!!\*\r!!,\*\b!!\*\n*\*\#*\*\v**\*\#*\*\n***\*\#*\*\aβ\*\*****\*\#*   \*\#   \*\*    \*\#    \*\#   \*\*    \*\# ",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!\*\*;;;;;\*\*!\*\^!!\*\*;;;;;\*\*!\*\^,!\*\a!\#\*\+!!!!!!!!!!*\*\014!**\*\r!***\*\v$%****\*\tβ45     \*\*  \*\#           \*\*  \*\#      ",
	"\*:;;\*\014;;\*\a+\*\*-\*γ+\*\*+\*ββΆγ\*\|%&\*\b'(\*\|56\#\*\|β\*\#'(\*\|        \*\#'(\*\#          \*\#'(\*\#  ",
	"\*Fβ\*\#;;\*\*+++\*\|!!!,\*\#;;\*!+++\*β*\*\|*\*\t**\*\|**\*\a   \*\|            \*\|         ",
	"\*1;\*\*;\*\*;\*\*;\*\*;\*\a;\*\*;\*\*;\*\*;\*\*;\*-*\*\**\*\v*\*\**\*\**\*\|β\*\|*\*\**\*\**\*\**\*\-βΆγ\*\#*\*\**\*\**\*\**\*\**\*\-'(\*\*        \*\* \*\-           \*\* \*\-   ",
	"\*B;\*\#;\*\#;\*\#;\*\#;\*&+\*\#+\*\#+\*\^+\*\v+\*!    \*\t       \*\t   ",
	"\**;;;!\*\*!\*\n;;;!!!\*\n;;;!*!\*\|β \*\b!!!\*\#-++\*\t!!\*\tβΆγ\*\-!!\*\t'(\*\-!!\*\t'(\*\-$!\*\t'(\*\-4!  \*\-    '(       \*\-    '(     ",
	"\* !\*\#*!*!!!!!!!!!*!\*\#*!*!!!!,!!!!*!\*\#*!*\*\t*!\*\#*!*\*\t*!\*\#*!*\*\+β \*\-*!\*\#***\*\|βΆγ\*\-*!\*\a!!'(!!\*\#!\*\a!!'(!!\*\#!\#\*\^!!'(!!\*\#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\* *!!!!!!!!!!!!!!!*****************\*\#*\*\|*\*\|*\*\#*\*\015*\*\014β *\*\#*************\*$*\*\-*\*\**\*\#*\*\#!!!!*\*\-*!*\*\#*!!!!!!*\*\-*!*\*\#*!!",
	"\* !!!!!!!!!!!!!!!!****************\*0****\*\#+\*\#+\*\#-\*\#+\*0!!!!!!\*\-!!\*\-!!!!!!!!\*\-!!\*\-!!",
	"\* !!!!!!!!!!!!!!!!*\*QΒ₯β’\*\-Β₯β’\*\-Β₯β’\*\|βΆγ\*\-βΆγ\*\-βΆγ\*\|'(\*\-'(\*\#β'(\*\#!!'(!!!'(!!!'(!!!!'(!!!'(!!!'(!!",
	"\* !!!!!!!!!!!!!!!!\*\-!!!!!!!\*\|!!\*\-!!!!!!!\*\|!!\*\-!!!!!!.\*\|!!\*\014!!\*\aβ\*\^!!\*\-!!!!!!!\*\|!!\*\-!!!!!!!\*\|$%\*\-!!!!!!!\*\|45!\*\#!!!!!!!\*\#!!!!!\*\#!!!!!!!\*\#!!!!",
	"\*A!+!\*\#!-!\*γβ\*\b!+!\*\#!+!\*!*\*\-*\*\v*\*\-*\*\*          *\*\-*           *\*\-* ",
	"\*6+\*\#+\*\t+\*\b+\*\-+\*\014+\*β*Β₯β’*\*\^\#\*\#*Β₯β’*βΆγ*Β₯β’*\*\-*Β₯β’*βΆγ*'(*βΆγ*Β₯β’**βΆγ*'(*βΆγ*'(*βΆγ*                                ",
	"\*?β\*β!!+!!\*\#Β₯β’\*\014βΆγ\*\014'(\*\|!!+!!\*\+βΆγ\*\014'(\*\014βΆγ\*\#                                ",
	"\*Oβ\*$;;\*\-;;\*\a*\*\*;;\*\**\*\*;;\*\**\*\+*\*\*;;\*\**\*\*;;\*\**\*\+*\*\|*\*\|*\*\-    \*\#   \*\#         \*\#   \*\#     ",
	"\**;;;;\*\f;;;;\*\f;;;;\*\b*\*\**\*\*;;;;\*\b*\*\**\*\v*\*\**\*\**\*\v*\*\**\*\**\*\t*\*\**\*\**\*\**\*\+$%\*\#*\*\**\*\**\*\**\*\+45   \*\* \*\* \*\* \*\|      \*\* \*\* \*\* \*\|   ",
	"\*0!\*\#!!!!!!!!!!!!!!\*\015!\*\014β!\*\015!\*\015!\*\#βΆγ\*\*++\*\-!!\*\-!\*\#'(\*\^!!\*\-!\#\*\*'(\*\^!!\*\-         \*\#  \*\#          \*\#  \*\# ",
	"\*0!!!!.!!!!!!!!!!!\*γβ\*β‘!!\*\a++\*\+!!\*\-βΆγ\*\t!!\*\-'(\*\t!!\*\-'(\*\a    \*\#              \*\#          ",
	"\*0!!!!!!!!!!!!!!!!\*β;;\*\#;;\*\n;\*\-;\*\+β\*βΒ₯β’\*\#Β₯β’\*\#Β₯β’\*\^βΆγ\*\#βΆγ\*\#βΆγ\*\^'(\*\#'(\*\#'(\*\-   '(  '(  '(      '(  '(  '(   ",
	"\*0!!!!!!!!!!!!!!!!\*\014!!\*\rβ!!\*\|;;\*\#;;\*\|!!\*\014!!\*\|++\*\#++\*\**\*\#!!\*\v*\*\#$%\*\v*\*\#45  \*\#  \*\#          \*\#  \*\#        ",
	"\**!!!!!!!!!!!!\*\|!!!!!!!\*\r!!!\*\*;;;\*\*;;;\*\*;;;\*\*!!!\*\*;;;\*\*;;;\*\*;;;\*\*!!!\*\*;;;\*\*;\*\*;\*\*;;;\*\*!!!\*\*;;;\*\*!!!\*\*;;;\*\*!!!\*\*;;;\*\*!!!\*\*;;;\*\*$%!\*\+!!!\*\+45                                ",
	"\*?β\*β!+!+*-!+!\*'!+!+*+!+!\*#      \*\-             \*\-       ",
	"\*Oβ\*β‘Β₯β’\*\014βΆγ\*\+++*++\*\|'(\*\014βΆγ\*\014'(\*\f       \*\#              \*\#       ",
	"\*_β\*γ+\*\+*\*\+*\*\b**\*\+**\*\^***\*\+***\*\|    \*\+           \*\+       ",
	"\*&;\*\^;\*\+;\*\^;\*\|;\*\*;\*\+;\*β+\*\a+\*β+\*\b+\*\f+\* β  \*\f    \*\f  ",
	"\*-!\*\*!\*\n;;;!!!\*\n;;;!*!\*\t*;;;!!!\*\b**\*\-β!!\*\a***\*\|!!\*\^****\*\|!!\*\+*****\*\|$!\*\+*****\*\|4!  \*\-             \*\-           ",
	"\* !\*\#!!!!!!!!!!!!!!\*\#!!,!!!!!!!!!!!\*\015!\*\fβ\*\#!\*\+!\"\"\"\"\"\"!\*\#!\*\+!\*\^!\*\#!\*\+!\*\^!\*\#!\*\|!!\*\^!!\*\*!\#\*\-!!\*\^!!\*\*!!!!!!!\*\^!!!!!!!!!!\*\^!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\|!!!!!\*\v!!,!!\*+!!\*\*!!\*\v!!\*\*!!\*\v!!\*\*!!\*\^β!!Β₯β’!!\*\*!!!!Β₯β’!!!!!βΆγ!!\*\*!!!!βΆγ!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\|!!!!!!!\*\t!!!!!!!\*\t!!!!!!!\*\t!!!,!!!\*\#!!!\*\r!!!\*\r!!!\*\r!!!!!!!Β₯β’!!!Β₯β’!!!!!!!!!βΆγ!!!βΆγ!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\014!!\*\014!!\*\t!!!\*\|!!Β₯β’!!!\*\#!!!\*\|!!βΆγ!!!\*\#!!!\*\#!!!!'(!!!\*\#!!!Β₯β’!!!!βΆγ!!!\*\#!!!βΆγ!!!!'(!!!βΆγ!!!'(!!!!βΆγ!!!'(!!!βΆγ!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!;;;;;;;;;;;!!!!!\*\v!!\*\#!!!!!!\"\"!.!!!!\*\^!!\*\#!!\*\#!!!!!!\*\aβ\*\#!!!!!!!!!!!!!!\*\#$%!!!!!!!!!!!!\*\#45!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\*9+\*\#+\*,+\*\#+\*\"β?\*\a   \*\#    \*\a   \*\#              \*\#              \*\#    ",
	"\*5;\*\f;\*\+;\*,;\*β+!-!+\*\*  \*\014  \*\rβ?  \*\+           \*\+         ",
	"\*V+!++\*γβ?\*\f*\"\"*\*\f*\*\#*\*\f*\*\#*\*\^  \*\|*\*\#*\*\|    \*\|*\*\#*\*\|  ",
	"\*L+!+\*β‘;;\*\014;;\*\t+!+\*\|Β₯β’\*\|Β₯β’\*\bβΆγ0000βΆγ\*\b'(\*\|'(\*\|β?   '(\*\|'(        '(\*\|'(     ",
	"\*,;;\*\014;;\*\rβ;;\*\f*\*\*;;\*\014;;\*\t*\*\|;;\*\014;;\*\^*\*\t$%\*\01445  \*\v     \*\v   ",
	"\* !\*\#!!!!!!!'(!!!!!\*\#!!!!!!!'(!!!!!\*\t'(\*\|!\*\#+\*\*-\*\|'(\*\|!\*\bββΆγ\*\|!\*\015!\*\#+\*\*+\*\*βΆγ\*\|βΆγ\*\*!\*\^'(\*\*Β₯β’\*\*'(\*\*!\#\*\+'(\*\*βΆγ\*\*'(\*\*!!!!!!!'(!'(!'(!!!!!!!!'(!'(!'(!",
	"\* !!!!!!!'(!!!!!!!!!!!!!!'(!!!!!!!\*\#!!!!!βΆγ!!!!!\*\|!!!!!\*\#!.!!!\*\|!,!!\*\|!!!!\*\015β?\*\|!!!!\"\"\"\"!!!!\*\|!!!!\*\|!!!!\*\|!!!!\*\|!!!!\*\#!!!!!!\*\|!!!!!!!!!!!!\*\|!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\^;;;;;!!!!!\*\014!!\*\#+\*\*-\*βΒ₯β’\*\|β?\*\a!!!!!!!!!\*\+!!!!!!!!!!!\*\#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\#!!!!!!!!!!!!!\*\|!!!!!!\*γβ?\*\^!!0!!0!!!!0!!0!!!!\*\*!!\*\*!!!!\*\*!!\*\*!!\*β?Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!,!!!!!!!!\*\n;;;!!!\*\tβ;;;!!!!!!!!!!!!!;;;!!!!!!!!!!!!!\*\-$%%!!!!!!!!!!\*\-455!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\*T+!-\*\|+!+\*&+!+\*\|+!+\*\#%&\*\01456\*\rβ?                                ",
	"\*E++\*\|;;;;\*γ     \*\#Β₯β’\*\*++\*\*        \*\#βΆγ\*\|    \*\^'(\*\014'(\*\vβ?  '(              '(            ",
	"\*8+!-!+\*\a;\*\*;\*γβ?   \*\*;\*\*;\*\*           \*\+        \*\|;\*\*;\*γ;\*\*;\*\|Β₯β’\*\-   \*\+           \*\+        ",
	"\*2;\*\*;\*\*;\*β+!+!+\*\-;\*\*;\*\*;\*\t \*\rβ?\*\* \*\*;\*\*;\*\*;\*\-+!+!-\*\bΒ₯β’\*\014βΆγ\*\014'(\*\a   \*\|'(          \*\|'(       ",
	"\*-!\*\*!\*\a;\*\*;\*\*;\*\*!!!\*\- \*\t!*!\*\- \*\-;\*\*;\*\*;\*\*!!!\*\#  \*\n!!\*\#  \*\-;\*\*;\*\*;\*\#!!\*\#  Β₯β’\*\b!!\*\#    \*\*;\*\*;\*\*;\*\#$!\*\*     \*\b4!      \*\a         βΆγ\*\+   ",
	"\* !!\*\#!!!!!!!!!!!!!!\*\#!!!!!!!!!!!,!!\*\014!!\*\014!!\*\014!!\*\#+!+!+!+\*\#!!!!!\*\014!!\*\014!!\*\014!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*0!!!!\*\#!!,!!\*\#!!!\*$Β₯β’\*\+Β₯β’\*\-!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!,!!!!!!!!\*\#!!!!\*\|!!!!!!\*\#!!!!\*\*!!\*\*!!.!!!\*\#!!\*\-!!\*\*!!!!!!!\*\*!!\*\*!!!!\*\*!\*\n!!!!\*\^β\*\#-+\*\*!!!!\*\*!!!!!!\*\+!!!!β?!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\*0!!,,,!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\^!!!!!!!!!!\*\*!!!\*\#!!!!!!!!\*\-!!!\*\#!!!;;;!!\*\-!!!\*\#!!!;;;!!!!!!!!\*\#!!!;;;!!!!!!!!\*\b$%!!!!!!Β₯β’\*\+β?45!!!!!!!!!!!!!!!!",
	"\* \#\*\+!!!!!!!!!!!!!!;;!!!!!!!!!!!!!!;;!;\*\*;!;;;$%!;\*\#;;!\*\*!;!;;;45!\*\*!!!!!\*\*!;!\*\*!!!!!;\*\*;!;\*\*;!;!;\*\#;!!!!\*\*!\*\*!!!;!!!!\*\*!!;\*\*;!\*\*!;\*\*;!;\*\#;!!\*\*!!!\*\*!\*\*!!!\*\*!!!!!;\*\-;!;\*\-;!!!!!!!!!!!!!!!!!!!!",
	"\*lβ?\*\t!+!+!+!\*βΒ₯β’\*\014βΆγ\*\#β?\*\|β?\*\-   '(              '(           ",
	"\*H!+!+!\*0β?\*\^*00!+!+!+!\*\^*\*\015*\*\*β?\*\t  \*\#              \*\#            ",
	"\*Eβ?\*\015!+,!+!\*ββ\*\bβ?\*\tΒ₯β’\*\*!-!!+!\*\aβΆγ\*\014'(\*\f  '(       0000   '(       \*\| ",
	"\*J!!\*\*!!\*'β?\*\-,+!+!\*\|*00*\*\+!\*\+**\*\#**\*\|!\*\|***\*\#***\*\-!\*\#β?    \*\#              \*\#          ",
	"\*(****\*\f;;;;\*\f;;;;\*\f;;;;\*\n*\*\015*\*\014**\*\014**\*\a$%\*\|β?**\*\a45       \*\|            \*\|     ",
	"\* !\*\#!!!!!!!!!!!!!!\*\-'(\*\a!!!!\*\-'(\*\a!!!!\*\-βΆγ\*\*!-!!\*\#!!!!\*\f'(\*\*!\*\fβΆγ\*\*!\*\+!+!++!\*\|!\*\015!\*\014β?        0               \*\*       ",
	"\* !!!!!!!!!!!!!!!!!'(\*\+'(\*\*;;;;!!'(\*\+'(\*\*;;;;!!βΆγ\*\+βΆγ\*\*!!!!!\*\+.\*β’βΆγ\*\+βΆγ\*\a'(β?\*\-β?'(\*\|Β₯β’\*\*'(*\*\#β?*'(Β₯β’\*\#βΆγ              '(              '(",
	"\* !!!!!!!!!!!!!!!!!!!!\*\t!!!!!!!\*\#++-+\*\-!!!!!!!\*\v!\*\015!\*\tβ?\*\+!\*\-*00****000*\*\|**\*\#****\*\-**\*\#***\*\#****\*\-***    \*\#    \*\-       \*\#    \*\-   ",
	"\* !!!!!!!!!!!!!!!!!\*\b!!!!,!!!\*\*;;;;\*\*!\*\*!\*\^!\*\*;;;;\*\*!\*\*!\*\^!\*\^!\*\*,\*\^!!\*\|!!\*\*!\*\#*00*\*\f*\*\#*\*\f*\*\#*\*\-Β₯β’\*\|β?\*\#*\*\#*     00   00 \*\#      \*\#   \*\# \*\# ",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!;;;;;!\*\+'(\*\#!;;;;;!\*\+'(\*\#,\*\+!\*\+βΆγ\*\#!!!!!!!*\*\014!**\*\r!***\*\v$%****\*\*β?\*\-**\*\#β?45       00  00          \*\#  \*\#   ",
	"\*:;;\*\014;;\*\b-\*\*+\*γ+\*\*+\*\-Β₯β’\*\014βΆγ\*\|%&\*\b'(\*\|56\*\+β?\*\#'(\*\|        \*\#'(\*\#          \*\#'(\*\#  ",
	"\*Fβ?\*\#;;\*\*++-\*\|,!!!\*\#;;\*!+++\*β*0000*\*\t**\*\|**\*\#Β₯β’\*\*Β₯β’   \*\|            \*\|         ",
	"\*1;\*\*;\*\*;\*\*;\*\*;\*\a;\*\*;\*\*;\*\*;\*\*;\*-*\*\**\*\tβ?\*\**\*\**\*\**\*\|β?\*\|*\*\**\*\**\*\**\*\-βΆγ\*\#*\*\**\*\**\*\**\*\**\*\-'(\*\*        \*\* \*\-           \*\* \*\-   ",
	"\*7β?\*\t;\*\#;\*\#+\*\#;\*\#;\*3+\*\|+\*\*+\*\|+\*!β?   \*\t       \*\t    ",
	"\**;;;!\*\*!\*\n;;;!!!\*\n;;;!*!\*\^β?\*\^!!!\*\|++-\*\a!!\*\vβΆγ\*\*!!\*\v'(\*\*!!\*\v'(\*\*$!\*\*Β₯β’\*\+Β₯β’\*\*'(\*\*4!    000    '(       \*\-    '(   ",
	"\* !\*\#!!!!!!!!!!!!*!\*\#!!!!!!!,!!!!*!\*\#!!!!\*\b*!\*\#!!!!\*\b*!\*\nβ?\*\-*!\*\---\*\|βΆγ\*\-*!\*\a!!'(Β₯β’\*\#!\*\a!!'(!!\*\#!\*\a!!'(!!\*\#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\* *!!!!!!!!!!!!!!!*****************\*\**\*\+*\*\|*\*\#*\*\015*\*\-β?\*\+β?\*\|β?*\*\***************\*$*000*\*\**00*\*\#!!!!*\*\-*!*\*\#*!!!!!!*\*\-*!*\*\#*!!",
	"\* !!!!!!!!!!!!!!!!****************\*0***\*\#+\*\#+\*\#-\*\#+\*1!!!!!\*\n!!!!!!\*\n!",
	"\* !!!!!!!!!!!!!!!!*!!!!!.!!!!!!!!!\*\*!!\*\n!!!\*\*!!\*\n!!!\*\"Β₯β’\*\-Β₯β’\*\-Β₯β’\*\*-\*\#βΆγ000βΆγ000βΆγ\*\|'(\*\-'(\*\-'(\*\#!!'(\*\-'(\*\-'(!!!!'(\*\-'(\*\-'(!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!\*\-!!!!!!!!!!!!!\*\-!!!!!!!!!,!!.\*\-!!\*\#!!\*\n!!\*\#!!\*\|β\*\+!!\*\^!!!!!\*\-!!\*\^!!!!!\*\-$%\*\^!!!!!\*\#β?45!!!!\*\#!!!!!\*\*!!!!!!!!\*\#!!!!!\*\*!!!!",
	"\*R+!-!+!+!+\*'+!+!+!+!-\*\"               \*\-β                ",
	"\*\"Β₯β’\*\014  \*\014  \*\-;\*\-;;;;\*\-  \*\-;\*\-;;;;\*\-  \*\-;\*\-;;;;\*\-  \*\-;\*\***;;;;*\*\*$% \*\+**\*\|*\*\*45 \*\+**\*\|*    \*\+**\*\|*\*\+*000**0000*     *\*\-**\*\|*",
	"\*B;;;;\*\|;;;;\*\|;;;;\*\|;;;;\*\|;;;;\*\|;;;;\*\#*\*\*;;;;\*\***\*\*;;;;\*\***\*\^**\*\^**\*\^**\*\^**\*\^**\*\^**000000**000000**\*\^**\*\^*",
	"\*B;;;;\*\|;;;;\*\|;;;;\*\|;;;;\*\|;;;;\*\|;;;;\*\#*\*\*;;;;\*\***\*\*;;;;\*\***\*\^**\*\^**\*\^**\*\^**\*\^**\*\^**000000**000000**\*\^**\*\^*",
	"\*B;;;;\*\|;;;\*\+;;;;\*\|;;;\*\+;;;;\*\|;;;\*\-*\*\*;;;;\*\***\*\*;;;\*\-*\*\^**\*\a*\*\^**\*\+$%*\*\^**\*\+45*000000**00000  *\*\^**\*\+  ",
	"\*  \*\#              \*\#              \*\015 \*\#-\*\f \*\015 \*\t 00000 \*\#-\*\|β?\*\* \*\+ \*\+   \*\* \*\* ;;; \*\+     ;     \*\-                            ",
	"\*                  \*\-     \*\#     \*000\*\* 000000000 \*\+ \*\+ \*\- \*\#;;; \*\*β?\*\- \*\- \*\*     \*\* \*\*β?\*\* \*\*β?\*\* ;     ; ; ;   ;                   ",
	"\*      !!!             !!!  \*\#  \*\-    !!!  \*\- \*\-    !,! \*#β?\*\r   \*\-  00000 \*\#    \*\#  \*\+ ;;;   \*\#  ;  ;;                         ",
	"\*                            \*\+          \*\t  \*\#   \*\-  \*\|  \*\b  \*\rβ?  \*\n      \*\+ 0 \*\#      \*\- \*\* \*\* \*\#          ; ; ;;                       ",
	"\*                 \*\#              \*\+ \*\*  \*\*      \*\+ \*\# \*\| \*\* \*\b \*\^ \*\b \*\^ \*\# \*\vβ \*\# \*\b \*\-  \*\* \*\b \*\#$%   ;;; \*\#Β₯β’ \*\#45                ",
	"\*j!+!+!\*\|-!+!+\*'β\*β?                                ",
	"\*f+!!-\*\a+\*\f+\*Β₯β?\*\f    \*\^  0000    0000    \*\|    \*\|  ",
	"\*6;\*\#;\*Β₯;\*\#;;\*\#;\*βΒ₯β’\*\bΒ₯β’\*\|βΆγ00000000βΆγ\*\|'(\*\b'(\*\|'(\*\b'(\*\#  '(\*\b'(    '(\*\b'(  ",
	"\*R!!!!!!!\*\015β?\*\t+!+!-!+\*7         \*\+           \*\+  ",
	"\*d;\*\#;;\*\-;\*\015;\*\b;;\*\-;\*β$%\*\#Β₯β’\*\#Β₯β’\*\-Β₯β’\*\*45                                ",
	"\* !!.!!!!!!!!!!!!!!\*\*;;;;;;;;;;;;;;!\*\*!!!!!!\*\b!\*\t!\*\-β?\*\*!!!!!;;;\*\#!!!!!!!!!!!!!!\*\^;;!!!!+.+!\*\#!!!!!!%&;!\*\a!!!!!56;\*\#!!!\*\b!!\*\^Β₯β’!!!\*\*;!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!,,,***\*\|!!!\*\r!!!\*\#!!!!!!!!!;\*\*!\*\a!!!!!!!;!\*\#Β₯β’\*\-!!!!!!!;!\*\#***-;-;**!\*\t;\*\*;\*\-!\*\rβ?\*\-!!!!\*\|!!!!!!!!;;;;\*\*Β₯β’\*\*β\*\+!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*\^β?\*\#!!!!!!!!!\*\#!!!!!,,.,,,,!!\*\*!!!!!\*\b!!\*\a-+\*\+!!\*β‘β\*\015βΆγ\*\#!!!!*\*\-!!\*\#'(\*\*;;;;!**Β₯β’\*\|'(!\*\#!!!****!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*\*++++\*γβ\*\^*\*\b*\*\#;*\*\#*\*\+!\*\*-*\*\^*\*\+!\*\#*\*\^*\*\#*\*\#!\*\#*\*\+**\*\+!\*\#*\*\+**\*\+!***\*\#Β₯β’***\*\#Β₯β’\*\*!!!*!!!!!***!βΆγ!!",
	"\* !!!!!!!!!!!!!!!!\*\014!!\*\a-;;;\*\-!!\#\*\*!!\*\b.,.!!!!!!!\*\t$;;;;\*\+β?\*\+4!!!!\*\#******!!!!!+++-\*\b!!!!\*\f!!!!\*\|Β₯β’\*\^!!!!!!!!!!!!!!!!!!!",
	"\*R+\*\*+\*βΆ,;;\*\b;;\*\+;;\*\b;;\*\^%&\*\#β\*\v56\#\*\*!!Β₯β’\*\*Β₯β’!!\*\#!*!!!!!!!!!!!!!!!                ",
	"\*G+\*\|+\*\*;\*\-;\*\v;\*\#;\*\*;\*βΆβ\*\t!0\"0000!!!\*\*\#\*\-!!\*\-!\*\#!!!!*\*\*!!!\*\|!\*\#!!!!   !!Β₯β’Β₯β’!\*\#****          \*\#    ",
	"\*U+\*\*-\*\*+\*\a;;;;\*\r;\*\*;\*β’!\*\|*\*\**\*\#*\*\+!!\*\r*!!!!\*\+β?\*\+*     000000000**",
	"\*Zβ\*'*\*\|*\*\t**\*\|**\*\|Β₯β’\*\****\*\|***\*\-βΆγ\*\****\*\|****\*\#'(\*\****\*\*Β₯β’\*\*****\*\#'(*",
	"\*;;\*\^;\*\|;\*\f;\*\aβ\*\015$%%%\*\a;\*\|4555\*\#*\*\f*\*\#*\*\^*\*\+*\*\#*\*\-*\*\#*\*\+*\*\#*\*\*Β₯β’*Β₯β’*\*\#Β₯β’\*\******************",
	"\* *              * \*\vβ\*\- \*\*+\*\v   \*\-+\*\|-\*\#     \*\#Β₯β’\*\n  \*\#βΆγ\*\|β?\*\+  \*\#'(\*\*    +!!.!! \*\#'(\*\-;;;;;;; &\*\*    \*\b;$6\*\^Β₯β’Β₯β’\*\*Β₯β’;4*              *",
	"\* *!!!!!!!!!!!!!!!\#\*\015!  \*\r!\*\t*\*\|!!\*\t*\*\|!!\*\*β\*\a*\*\****!!    \*\#+\*\#*\*\*;;;!!;;; \*\+*\*\*;;;!!+-; \*\+*\*\#;;!!\*\+Β₯β’Β₯β’*Β₯!!!!!!!!!!!**!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*β?\#\*\015!!!!!\*\n!!\*\t*\*\|!!+-++\*\#*\*\^,!!\*\014!!\*\v-\*\#!!;0000\*\*;;000\*\*00!!\*\+Β₯β’\*\-β?\*\-!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*\#!!!!!!!!!!!!!!\#\*\t;;;;;!!\*\bβ\*\*!!!!!!\*\014!!!\*\^!!\*\+!!!\*\*!\*\+!,\*\|!!!\*\*!\*\+!\*\+!!!!!\*\#Β₯β’\*\*!-\*\|!!!!!00\"\"0!\*\-Β₯β’\*\*!!!!\*\+!!!!!!!",
	"\*                       ;;;        \*\+;;;\*\|    \*\+;\*\*;\*\+$% \*\^β\*\^45 \*\r!!*\*\-*\*\+*\*\#-!! \*\r!!\*\014!*\*\-β?\*\#Β₯β’\*\|β?\*\*!!!!!!!!!!!!!!!!!!",
	"\*3;\*\|;\*\^;\*β ;\*\#;\*\b;\*\bβ\*\n;\*\v;\*\^+\*\++\*\#+\*\tΒ₯β’\*\014!!\*\r!!!!\*\^!!\*\*β?\*\*!!!!!!β?\*\#!!",
	"\*D;;\*\+;;\*\^;;;;\*\-;;;;\*\^;;\*\+;;\*β+\*\^-\*\^+\*γΒ₯β’\*\+Β₯β’\*\*β\*\+!!!!!!         !!!!",
	"\*d!!\*\a;;\*\-*\*\b*\*\*;;\*β;;;;;\*β!!%%%\*\^%%%%%!!555\*\^55555",
	"\* ;\*\014;;\*\f;;\*\*;;;\*\b;;\*\-;;;\*\a;\*\|*;;;\*\#β\*\-;\*\+*\*\-+-+\*\#;\*\-*\*\#*\*\f*\*\#*\*\b*\*\-*\*\#*\*\b*\*\-*\*\#***\*\-β \*\#*\*\*Β₯β’*Β₯β’*!!!!!!!!!!!!!!!!",
	"\*)*******\*\^;\*\+$%%%\*\+;;;\*\|4555**\*\n!*****\*\n!!!!**\*\|Β₯β’\*\|!*!!**\*\#*-*+*\*\*!!!!!!**\*\b!;;;;!**\*\b!;!;;!**\*\*β?\*\a;!!!!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!\*\-!!!!!\*\v;;\*\*!!+\*\****\*\*;\*\#β?\*\+!\*\|+********!!!\*\n;\*\-!!!;!\*\#β\*\+-\*\*;!!!!!!!!!!!!\*\#+\*\*!!!!+!;;\*\*;\*\*!!\*\#+!\*\b+\*\#!\*\-!!!!\*\-β?\*\|;\*\-!!!!!!!!!**!!!!!!",
	"\* !!!!!!!!!!\*\|!!!!\*\#;;\*\n\#\*\-!!!\*\*β \*\*!Β₯β’\*\#!!!!!\*\-!!!!!!\*\#!!!\*\014!!\*\#Β₯β’\*\*!!!!\*\-β\*\*!+\*\*.!!!!!!!!!!!!!\*\-!\*\-;!!\*\#;+!!\*\rβ!!\*\*+\*\-βΆγ\*\-Β₯β’\*\-!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!\*\t+\*\#+\*\*!!\*\+*\*\a+!!\*\|*;*!!!!\*\-!!\*\#**;;!+.\*\+!!\*\*+\*\#;;!\*\*!\*\-!!!!\*\-!*,*\*\-!\*\-!!\*\|;\*\*!\*\*Β₯β’\*\|*+!!\*\|!+!+*\*\n;!;;;\*\#Β₯β’\*\*!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!;\*\*;\*\|;!!;;\*\-!\*\*!\*\++\*\a!\*\*!!!*\*\*β \*\^*!!\*\++*****\*\-!!!!!!\*\*;\*\#;+*\*\*-\*\*!!\*\-!\*\*!!\*\-*\*\-!!\*\*!\*\*+*;\*\*,!\*\**\*\-!;\*\*!\*\^+\*\**\*\*!+!\*\#!\*\-β?\*\|*;;;!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!;\*\|;;\*\-;\*\-!!;\*\*;\*\#.!\*\-!\*\-!!;\*\*;\*\*;\*\|+!\*\-!!;\*\|!\*\|!\*\*;β!!\*\#+\*\**\*\-+\*\*!\*\#$%!\*\#!\*\-βΆγ\*\#*\*\#45!\*\*+*\*\#*!!!*\*\#*\*\*!\*\|+\*\*+\*\#Β₯β’Β₯β’\*\**!\*\-Β₯β’Β₯β’Β₯β’βΆγβΆγΒ₯β’!!!!!!!!!!!!!!!!!",
	"\*&;;\*\f;\*\*+\*\tβ\*β +;;;\*\#;\*\^;\*\++;+;\*\^;;\*\|;\*\+;\*\#+\*\*+\*\|;;\*\#;\*\*+\*\^;\*\t;;;\*\-βΆγ\"00\"βΆγ\*\b'(\*\|'(Β₯β’\*\*Β₯β’\*\*  '(\*\|'(      ",
	"\*8-\*\014*;*\*\f*-\*\***\"\"\"\"\"\*\+*;;\*\*;**\*\b**;*\*\#**\*\a**\*\***\*\**\*\***\*\+*\*\t**\*β    Β₯β’   Β₯β’   \*\*                ",
	"\*#;;\*\|;\*\v+\*\|+-\*\aβ?\*\t;\*\#\"\"******\*β *\*\**\*\#+\*γ*\*\#;\*γ*\*\|Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’\*\-;                ",
	"\*!*\*\r*\*\**\*\r*\*\**\*\b-\*\#+\*\**\*\**\*\-+\*\#+\*\^*\*\**\*\n+\*\#*\*\**\*\r*\*\**\*\*+\*\#+\*\b*\*\**\*\+βΒ₯β’\*\#β?\*\|*\*\+        \*\^β?         \*\*                ",
	"\* *%%%%%%&;\*\a*5555556\*\|;\*\-;;\*\f;\*\015-\*\|β?\*\#β?\*\#Β₯β’\*\*;\*\*;\*\-**********\*\|+\*\**;;;;;;;;*\*\#;;\*\#*+;;;;-;;*\*\#;;\*\#*;;;+;;;;*\*\*$%%\*\nβ \*\*455                ",
	"\* !'(!!!!!!!!!!!!!!βΆγ!;!;!;!;!\*\-!!\*\#!\*\+!\*\+!!\*\#!+\*\*+\*\*-!\*\+!!\*\#!\*\+.*0 \*\#!!\*\#!\*\*;\*\*!\*\*!+\*\|!!\*\#!\*\*!\*\*!\*\*β\*\#  ;!!\*\#+\*\*!\*\*!!!!\*\*!!;!!\*\|!\*\*!;\*\-!!;!!\*\-+!;\*\#Β₯β’\*\*!!;\*\*!!!!!!!!!!!!!!!!",
	"\* !!!!\*\*!!\*\-!!!!!!!\*\v;;;!!\*\+-\*\*β?\*\-;;;!!\*\#*β?*\*\****\*\#;;;!!*\*\*!!!\*\b+!!\*\#!\*\#!\*\b!!\*\#!\*\#;!!\*\#β?\*\*!!!!\*\**!\*\+!!!!;;!!\*\#!\*\n+!\*\-!\*\*β?\*\|β\*\+!!!!!!!!!!!!!!!!",
	"\* !!!!!!!\*\#!!!!!!!!\*\*+\*\v+!!\*\-,.\*\*β?\*\#+\*\|!!+\*\|**\*\a!!\*\-+\*\-*-*+**\*\*!!\*\++\*\+!!\*\*!!\*\f!\*\*!!!!++!!!!!!\*\#!\*\*!!\*\-+\*\-β\*\|!\*\*!\*\a+\*\+!\*\#!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!\*\r;;!\*\-;\*\#;\*\#;\*\-;!!\*\-;\*\#;\*\#;\*\-!!!\*\-*\*\#*\*\#*\*\|!!\*\-!\*\#!\*\#!\*\#*\*\*!!*\*\#!\*\#!\*\#!\*\#!\*\*!!\*\-!\*\#!\*\#!\*\#!Β₯β’!\*\-!\*\#!Β₯β’!\*\#!!!\*\#β?\*\*!Β₯β’!!!!Β₯β’!!!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!\*\*!!!!!\*\v;;;;;!\*\tβ?;;β?;;!;;;\*\*+\*\-******!!β?\*\a*\*\|$%!***\*\#-\*\****\*\-45!\*\014!!\*\014!;;;\*\#*\*\#+\*\**;;;*!β?;!\*\*β \*\+*;β?;;!!!!!!!!!!!!!!!!!",
	"\*9-\*\^;\*\*;+\*\r-\*\|Β₯β’\*\a \*\-+\*\*     00000 \*\*+\*\*;\*\*        \*\# \*\+        \*\# \*\|         \*\# \*\#           \*\# \*\*            \*\#              \*\# ",
	"\*%;;;;;;;;;\*\++\*\a+\*\|\#\*\015 \*\*   0000\"\"\"000\" \*\*   \*\a;;;; \*\*   \*\*Β₯β’β \*\-;-;; \*\*         \*\*;;;; \*\*         Β₯β’\*\- \*\*               \*\*               \*\*              ",
	"\* ;;;;;;;;;;;;\*β -\*β‘\"000\"\"\"\"00\*\# \*\014 ; \*\-+\*\++\*\# ;;; \*\t00;;;; \*\^000\*\#;;;; \*\-000\*\t \*\a+\*\*+\*\#Β₯β’\*\*      \*\+       ",
	"\*/ \*\#+\*\-+\*\b \*\015 \*\|+\*\|+\*\#+\*\# \*\014  \*\*-\*\f  \*\- \*\* ;; \*\* 0    \*\- \*\* ;; \*\* 0    \*\- \*\* \*\# \*\* 00000    0    0 00000    \*\*    \*\*      ",
	"\*2--\*\+;;;;\*β‘β?\*\+;;;;\*\^ \*\#*\*\f \*\-β?\*\|β \*\-β?\*\# \*\-          \*\# *\*\|+++ \*\+Β₯β’\*\*β?\*\*;;;;; \*\#$%%%%\*\*        \*\#45555                ",
	"\*!!!!!!!!!!!!!!!!!;;!;\*\f;;!\*\#;\*\-+\*\*+\*\*;\*\|!\*\f!\*\#!\*\**\*\#+\*\^+!\*\#!\*\^;\*\+!\*\#.\*\-*!\*\--\*\-!\*\#,\*\**\*\#!;\*\-;\*\**!\*\a!\*\a!\*\-!\*\#β!Β₯β’Β₯β’Β₯β’Β₯!!!!!!!!!!!!!!!!",
	"\*!!!!!!!!!!!!!!!!\*\#;\*β‘;\*\*-\*\*β?\*\|;\*\|+\*\#+\*\#+\*β ;\*\-+\*β?\#\*\*+\*\b+\*\|*\*\-*β\*\-*\*\+*\*β?β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’Β₯!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!;\*\a!\*\-;\*\#!\*\*-\*\^!\*\-;\*\#!\*\#+\*\+!\*\*!\*\*;\*\#!\*\|!0\"0!\*\*!!;\*\#!\#\*\-!000!\*\#!;\*\#!*\*\-!0\"0!!\*\*!;;;!\*\**\*\#!\"00!!;;!\*\*;!\*\|!0\*\-!;;!\*\*;!β’Β₯β’β?!0Β₯β’\*\#;;!\*\-!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!\*\aβ\*\^!!\*\+!\*\#*\*\#*\*\#!!\*\+!\*\b!!\*\*000*!\*\#;\*\^!\*\+!00000;0!\*\*!00*\*\#!0000000!\*\*!\*\+!\*\a!\*\*!\*\#*00!\*\+*\*\*!\*\a!β?\*\*β?\*\*β?\*\*β?!\*\*!!!!!!!!!!!!!!!!",
	"\* !!;!!!!!!!!!!!!!!!\*\r!!!\*\t;\*\-!!!\*\#;\*\*-\*\**\*\|;\*\*!\*\*!+\*\**;\*\++\*\-!\*\*!\*\+;\*\t!\*\b*\*\#$%%\*\*!\*\v455\*\*!\*\*+\*\-+\*\+*\*\*!\*\f+\*\#!!!!!!!\*\t!",
	"\*(;;\*\^;;\*\b++\*\a+\*\# \*\-;;+\*\***;+\*\| +\*\#;*+\*\-;\*\|+ \*\#;+\*\a+\*\- \*\#;\*\-;;\*\|+\*\# \*\f+\*\#   \*\-;;\*\a    \*\^*\*\-        \*\|+                ",
	"\*?;*\*\014;\*\|;*;++-\*\-*\*\*;\*\*+\*\#***\*\*;\*\|*;+;\*\|+;\*\|*+*\*\#;;;\*\*;;;\*\#*β?*\*\-*\#\*\#+\*\***\*\-**\*\|*\*\+*+\*\#++\*\#+\*\**\*\*β?\*\r*******\*\#**\*\-**",
	"\*2+\*\*++\*\|*\*\|*\*\#+\*\a*\*\+*\*\#;\*\v;\*\-;\*\#;\*\*++β?++\*\#;\*\*+\*\-*\*\*;;\*\*-\*\+*\*\+++\*\a*\*\#;;\*\*+\*\*;;\*\#;;\*\#*\*\|+\*γ++\*\*++\*\a*\*\|**",
	"\*&+\*\*;;\*\+**++\*\b*\*\-*;+;\*\+;\*\#*\*\*;\*\**\*\#;;\*\#*;\*\*+\*\b*\*\n;;;;\*\-*\*\|**\*\-+\*\*+\*\|+\*\#;\*\-+\*\*;*+\*\+β?\*\|**\*\+;\*\-**\*\a*\*\t;\*\^**\*\f**",
	"\* *\*\aβ\*\+*\*\**\*\+*\*\-*\*\+*\*\+*;\*\t++\*\*;\*\#+\*\#;-+\*\r;\*\*;\*\a;;**\*\**;\*\*;\*\-+\*\-;;++;;;;+;\*\+*;;\*\*;\*\#;;;;\*\#*;;;\*\*++\*\#β?;$%%%%\*\t*;45555++\*\b******",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!++\*\#;\*\-!!!\*\-!!\*\b;;!\*\*-+!;\*\*;\*\^!!!\*\-!!\*\#+-\*\|,!!\*\-!!\*\*+\*\#!!\*\-+\*\-+!\*\+!!\*\b!\*\+!!β?\*\a!\#!!;!!!!!!!!!!!!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!++\*β?;\*\|;\*\a*\*\-+\*\-!;!;!\*\*-\*\#!\*\#;\*\*!\*\*!;!;!\*\v!;!;!;\*\#*\*\*++\*\*;\*\#!;!;!\*\^;\*\*,\*\#!;!;!\*\^!\*\|!;!;!\*\*+\*\*!\*\#β?β?\*\#;!β?!β?!\*\-!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*\a!+\*\b!\*\#-\*\*;\*\a!\*\*;\*\n+\*\b!\*\a!\*\*;\*\#!\*\*+\*\*!\*\#!\*\-!!;\*\^++\*\b+\*\+;\*\^+\*\-;!\*\*!\*\*;\*\-;\*\#!\*\#+\*\+;\*\#β ;\*\^!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*\|!\*\-!\*\b++\*\#;\*\#!\*\-;+\*\tβ?\*\t!\*\*+\*\-+\*\*;\*\#!!\*\-!\*\|,++\*\#;\*\-;!\*\#+\*\v!\*\*;\*\*β?\*\-;\*\#+\*\#β?\*\#!\*\*!!\*\#!\*\-+\*\*-+\*\aβ\*\n!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*\015!\*\++\*\+;\*\-!\*\*;;+\*\#;\*\*-;;+;;\*\*!\*\*+\*\a;,;\*\-!\*\-;\*\-β\*\-;;;;!+\*\#;!!!!!!!!!!;!\*\-;!\*\t;!\*\-;!\*\*$%%%%%%%%%\*\-;!\*\*4555555555!!!!!!!!!!!!!!!!",
	"\*8β\*\v      ; ; ; \*\|      ; ; ; \*\|;;;;; ; ; ; \*\|;   ; ; ; ; \*\- ; β ; ; ; ; \*\- ;;; ; ; ; ; \*\- ;   ; ; ; ; \*\*   ;;;;;;;;;;;                 ",
	"\*2;\*\*;\*\*;\*\#β\*\^  ; ; ; -   \*\|  ; ; ; ;   \*\|  ; ; ; ;;;;\*\|  ; ; ;       \*\#  ; ; ;    β?  \*\#  ; ; ; ;;;;; \*\#  ; ; ; ;   ; \*\#  ;;;;;;;;;;;                   ",
	"\*8;\*\b;\*\---\*\+;\*\#;\*\*;\*\n;\*\#;;\*\-β\*\+;\*\a+000000+\*\*;;;;\*\#;\*\v;\*\-;\*\-**\*\+Β₯β’\*\*;\*\*;;\*\tβΆγ\*\#   ;;;;;;   '(     ;;;;;;   '(  ",
	"\*.β\*\a;\*\-;\*\b-\*\|+\*\--\*\^;;\*\-;\*\-+\*β+;\*\-+;;\*\b+\*β;;\*\#+\*\a++;;;;+;;;\*\-  ;;;;;;;;;;;;    ;;;;;;;;;;;;  ",
	"\*B;;;;;;;;;;;;\*\|;+;-;;;;-;;+\*γβ\*\#β?\*\-+\*\+000β?00\"00\*\*;\*\|*000\"00000*\*\#$\*\**\*\*Β₯β’Β₯β’Β₯β’Β₯β’Β₯β’*\*\*4                                ",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\*\b!!!!!!!!\*\*!!!!!!\*\*!!!!!!!!\*\*!!!!!!\*\*!!!!\*\+!!!!!!\*\+!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!!!!\*\a!!!!!!!!!\*\*!!!!!\*\*!!\*\|!!!\*\*!\*\+!!\*\*!!\*\*!\*\-!\*\*!!!!!!\*\*!!\*\*!\*\*!!!\*\|!!!\*\#!\*\*!\*\*!!!!!!\*\*!!!!\*\*!\*\*!\*\#!!\*\|!!!!\*\*!\*\*!!\*\*!!\*\*!!!!!\*\-!\*\|!!\*\^!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!!!!!!\*\|!\*\-!!!!\*\+!!\*\-!\*\|!\*\*!!!!!!!!!!!!!!!\*\*!!!\*\-!\*\-!!!!!\*\-!\*\*!\*\*!\*\*!\*\*!!!!!!!\*\*!\*\*!\*\*!\*\*!\*\|!!!!\*\-!\*\-!!!!\*\*!!!!!!!!!!!!!!!\*\*!\*\015!!!!!!!!!!!!!!!!!",
	"\* !!\*\|!\*\^!!!!!\*\*!!\*\*!\*\*!!0!\*\*!!!\#\*\#!!\*\*!\*\*!!\*\*!\*\*!!!!!!\*\-!\*\#!\*\*!\*\*!!!\*\|!!!\*\*!!\*\*!\*\-!\*\*!!!!\*\-!!\*\*!!!\*\*!\*\*!!!!\*\*!!!\*\#!!!\*\*!\*\*!!\*\-!\*\-!!\*\-!\*\*!!\*\*!!!\*\*!!\*\-!!!\*\|!!!\*\|!\*\|!!!!!!!!!!!!!!!!",
	"\* !!!!!!!!!!!!!!!!\*β !!!!!!!!!!!!!!\*\n!!\*\+!!!!!!!!\*\*!!\*\*!!!!\*\a!\*\*!!\*\^!!!!!\*\*!\*\#!!!!!\*\^!\*\*!\*\*!!\*\+!!!!\*\*!\*\*!\*\*!!\*\*!!$%\*\+!\*\-!!\*\-45!!!!!!!!!!!!!!!!",
}
-- close bracket here
-- to fit 160 screens
-- with easy mapdata.py use
-- end of encoded data block
-- end of game code

__gfx__
00000000ccccccccccc222cccc222ccccc222cccccc222ccc99cc99cccc555cccc222222cc222222cc222222cc222222c22cc22ccc555555cc000ccccc333ccc
00000000cccccccccc222222c222222cc222222ccc222222c22cc22ccc555555cc222222cc222222cc22222222222266c22cc22ccc555555c00900cc333333cc
00700700ccccccccccc9099ccc9099cccc9099ccccc9099cc922229cccc9099c22222266222222662222226622222222c222222c555555660009000cc9909ccc
00077000ccccccccccc99ccccc99cccccc99ccccccc99cc9c000000cccc99ccc22222222222222222222222222222222c222222c555555550999050cccc99ccc
00077000ccccccccc000000c0900009cccc009ccc0000000ccc99cccc000000c22222222222222222222222222222222c222222c555555550000000cc000000c
00700700ccccccccc922229cc2222cccccc222ccc92222cccc9999ccc955559c222222222222222222222222cc222222c222222c55555555c00500ccc933339c
00000000ccccccccc22cc22c22cc22cccc922cccc22cc22cc222222cc55cc55ccc22cc22ccc2ccc2cc2ccc2ccc22cc22c226622ccc55cc55cc000cccc33cc33c
00000000ccccccccc99cc99c99cc99ccccc99ccc99cccc99cc2222ccc99cc99ccc22cc22ccc2ccc2cc2ccc2cccccccccc222222ccc55cc55ccccccccc99cc99c
ccccccccccccccccccccccccccccccccccccccccc9cccc9ccccccccc9999494444440400c9cccc9cccccc9cccc9cccccccc9c9ccccccccc9c9cccccc00000000
ccc9c9cccc9cc9ccc9cccc9ccc9ccc9ccc9ccc9c999cc999cccccccc9999494444440400c9cccc9cccccc9cccc9cccccccc9c9ccccccccc9c9cccccc00000000
cc2929cccc9cc9cccc9cc9ccc909c909c909c909c99cc99cc99cc99c9999494444440400c9c9c99cccccc9c9c99cccccc9c9c9ccccccc9c9c9cccccc00000000
c9222229c292292cc292292cc292229cc292229ccc9229cc999229999999494444440400c9c9c99cccccc9c9c99cccccc9c9c99cccccc9c9c99ccccc00000000
c292929c22222222222222222222222222222222ccc22cccc9c22c9c99994944444404009292929ccccc9292929ccccc9292929ccccc9292929ccccc00000000
99222222c222222cc222222cc222222cc222222ccc9cc9cccc9cc9cc999949444444040099292229cccc99292229cccc92222229cccc92222229cccc00000000
22292299cc9cc9cccc9cc9cccc9cc9cccc9cc9ccc9cccc9ccc9cc9cc999949444444040092222929cccc92222929cccc92922299cccc92922299cccc00000000
c222222ccc9cc9ccc9cccc9ccc9cc9ccc9cccc9ccccccccccccccccc000000000000000092929229cccc92929229cccc99222929cccc99222929cccc00000000
4404440440444444000000000000000099999990cccccccc09999999c99994944440400c00000000999999949999999440444444999999944044444400000000
44044404404444444444444400000000999999909999999909999999c99994944440400c00000000900000409444444040444444944444404044444400000000
4040440040444444c0c0c0c000000000999999909999999909999999c99994944440400c00000000904444909449944040444444944994404044444400000000
0444004400000000cccccccc00000000999999909999999909999999c99994944440400c00000000904444909494404000000000949940400000000000000000
0444044444444044cccccccc00000000444444409999999904444444c99994944440400c00000000904444909494404044444044949440404444404400000000
0440044444444044cccccccc00000000999999904444444409999999c99994944440400c00000000904444909440044044444044944004404444404400000000
4004404044444044cccccccc00000000444444409999999904444444c99994944440400c00000000949999909444444044444044944444404444404400000000
4404440400000000cccccccc00000000444444404444444404444444c99994944440400c00000000400000004000000000000000400000000000000000000000
4c4c4c4ccccc4c4c4c4ccccc0000000044444440444444440444444400000000000000000000000000000000cccccccc00000000c292292cccc9cccc00000000
c4c4c4c4ccccc4c4c4c4cccc0000000044444440444444440444444499994944444404000000000000000000cc9944cc0000000092222222cc040ccc00000000
4c4c4c4ccccc4c4c4c4ccccc0000000044444440444444440444444499994944444404000000000000000000c999944c0000000022292229c04440cc00000000
cccccccccccccccccccccccc0000000044444440000000000444444499994944444404000000000000000000c999944c00000000292229229444449c00000000
cccccccccccccccccccccccc0000000000000000444444440000000099994944444404000000000000000000c999944c00000000ccc99cccc04440cc00000000
cccccccccccccccccccccccc0000000044444440000000000444444499994944444404000000000000000000c999944c00000000cc9999cccc040ccc00000000
cccccccccccccccccccccccc0000000000000000000000000000000099994944444404000000000000000000cc9944cc00000000cc9999ccccc9cccc00000000
cccccccccccccccccccccccc0000000000000000cccccccc0000000099994944444404000000000000000000cccccccc00000000ccc99ccccccccccc00000000
07000000770000000770000077000000777000007770000007000000707000007770000077700000707000007000000070700000707000000700000077000000
70700000707000007000000070700000700000007000000070700000707000000700000000700000707000007000000077700000777000007070000070700000
70700000707000007000000070700000700000007000000070000000707000000700000000700000707000007000000077700000777000007070000070700000
77700000770000007000000070700000770000007700000077700000777000000700000000700000770000007000000070700000777000007070000077000000
70700000707000007000000070700000700000007000000070700000707000000700000000700000707000007000000070700000777000007070000070000000
70700000707000007000000070700000700000007000000070700000707000000700000070700000707000007000000070700000777000007070000070000000
70700000770000000770000077000000777000007000000007000000707000007770000007000000707000007770000070700000707000000700000070000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000770000000770000077700000707000007070000070700000707000007070000077700000000000000000000000000000000000000000000000000000
70700000707000007000000007000000707000007070000070700000707000007070000000700000000000000000000000000000000000000000000000000000
70700000707000007000000007000000707000007070000070700000707000000700000000700000000000000000000000000000000000000000000000000000
70700000770000000700000007000000707000007070000070700000070000000700000007000000000000000000000000000000000000000000000000000000
70700000707000000070000007000000707000007070000077700000707000000700000070000000000000000000000000000000000000000000000000000000
77000000707000000070000007000000707000000700000077700000707000000700000070000000000000000000000000000000000000000000000000000000
07700000707000007700000007000000070000000700000070700000707000000700000077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700000070000007770000077700000707000007770000077700000777000007770000077700000000000000000000000000000000000000000000000000000
70700000070000000070000000700000707000007000000070000000007000007070000070700000000000000000000000000000000000000000000000000000
70700000070000000070000000700000707000007000000070000000007000007070000070700000000000000000000000000000000000000000000000000000
70700000070000007770000077700000777000007770000077700000007000007770000077700000000000000000000000000000000000000000000000000000
70700000070000007000000000700000007000000070000070700000007000007070000000700000000000000000000000000000000000000000000000000000
70700000070000007000000000700000007000000070000070700000007000007070000000700000000000000000000000000000000000000000000000000000
77700000070000007770000077700000007000007770000077700000007000007770000077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70700000000000000700000007777700077777000777770007777700077777000777770007000000000000000000000000000000000000000000000000000000
70700000000000000700000077000770777007707700077077007770777077707707077007000000000000000000000000000000000000000000000000000000
70700000777000000000000077000770770007707707077077000770770007707770777007000000000000000000000000000000000000000000000000000000
70700000000000000700000077707770777007707700077077007770770007707707077007000000000000000000000000000000000000000000000000000000
70700000000000000700000007777700077777000777770007777700077777000777770000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cc999c999c999c999c999ccccccccccc999c999cccc555cccc999ccc9ccc9c9c9cccc9ccc9cccc000ccccc999c999c999cccccccccccccccc9cccc999c999ccc
cc9c9c9c9c9c9c9c9c9c9ccc9944cccc9c9c9c9ccc555555cccc9ccc9ccc9c9c9cccc9ccc9ccc00900cccc9c9c9c9c9c9ccccccccccccccc040ccc9c9c9c9ccc
cc9c9c9c9c9c9c9c9c9c9cc999944ccc9c9c9c9cccc9099ccccc9ccc9ccc9c9c9cccc9ccc9cc0009000ccc9c9c9c9c9c9cccccccccccccc04440cc9c9c9c9ccc
cc9c9c9c9c9c9c9c9c9c9cc999944ccc9c9c9c9cccc99ccccc999ccc9ccc9c9c9cccc9ccc9cc0999050ccc9c9c9c9c9c9ccccccccccccc9444449c9c9c9c9ccc
cc9c9c9c9c9c9c9c9c9c9cc999944ccc9c9c9c9cc000000ccccc9ccc9ccc9c9c9cccc9ccc9cc0000000ccc9c9c9c9c9c9cccccccccccccc04440cc9c9c9c9ccc
cc9c9c9c9c9c9c9c9c9c9cc999944ccc9c9c9c9cc955559ccccc9ccc9cccc9cc9cccc9ccc9ccc00500cccc9c9c9c9c9c9ccccccccccccccc040ccc9c9c9c9ccc
cc999c999c999c999c999ccc9944cccc999c999cc55cc55ccc999ccc999cc9cc999cc9ccc9cccc000ccccc999c999c999cccccccccccccccc9cccc999c999ccc
ccccccccccccccccccccccccccccccccccccccccc99cc99ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
9999999499999994cccccccccccccccc9999999499999994cccccccccccccccccccccccc9999999499999994cccccccccccccccccccccccc9999999499999994
9000004090000040cccccccccccccccc9000004090000040cccccccccccccccccccccccc9000004090000040cccccccccccccccccccccccc9000004090000040
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490cccccccccccccccccccccccc9044449090444490
9499999094999990cccccccccccccccc9499999094999990cccccccccccccccccccccccc9499999094999990cccccccccccccccccccccccc9499999094999990
4000000040000000cccccccccccccccc4000000040000000cccccccccccccccccccccccc4000000040000000cccccccccccccccccccccccc4000000040000000
99999994cccccccc99999994cccccccc99999994cccccccc99999994cccccccc99999994cccccccccccccccc99999994cccccccc99999994cccccccccccccccc
90000040cccccccc90000040cccccccc90000040cccccccc90000040cccccccc90000040cccccccccccccccc90000040cccccccc90000040cccccccccccccccc
90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc
90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc
90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc
90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc
94999990cccccccc94999990cccccccc94999990cccccccc94999990cccccccc94999990cccccccccccccccc94999990cccccccc94999990cccccccccccccccc
40000000cccccccc40000000cccccccc40000000cccccccc40000000cccccccc40000000cccccccccccccccc40000000cccccccc40000000cccccccccccccccc
99999994ccc9c9cc99999994cccccccc99999994cccccccc99999994cccccccc99999994cccccccccccccccc99999994cccccccc99999994cc222ccccccccccc
90000040ccc9c9cc90000040cccccccc90000040cccccccc90000040cccccccc90000040cccccccccccccccc90000040cccccccc90000040222222cccccccccc
90444490c9c9c9cc90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490c9909ccccccccccc
90444490c9c9c99c90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490ccc99ccccccccccc
904444909292929c90444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490c000000ccccccccc
904444909222222990444490cccccccc90444490cccccccc90444490cccccccc90444490cccccccccccccccc90444490cccccccc90444490c922229ccccccccc
949999909292229994999990cccccccc94999990cccccccc94999990cccccccc94999990cccccccccccccccc94999990cccccccc94999990c22cc22ccccccccc
400000009922292940000000cccccccc40000000cccccccc40000000cccccccc40000000cccccccccccccccc40000000cccccccc40000000c99cc99ccccccccc
9999999499999994cccccccccccccccc9999999499999994cccccccccccccccc99999994cccccccccccccccc99999994cccccccccccccccc99999994cccccccc
9000004090000040cccccccccccccccc9000004090000040cccccccccccccccc90000040cccccccccccccccc90000040cccccccccccccccc90000040cccccccc
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccc
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccc
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccc
9044449090444490cccccccccccccccc9044449090444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccccccccccc90444490cccccccc
9499999094999990cccccccccccccccc9499999094999990cccccccccccccccc94999990cccccccccccccccc94999990cccccccccccccccc94999990cccccccc
4000000040000000cccccccccccccccc4000000040000000cccccccccccccccc40000000cccccccccccccccc40000000cccccccccccccccc40000000cccccccc
99999994cccccccc99999994cccccccc99999994cccccccc99999994cccccccc99999994999949444444040099999994cccccccccccccccccccccccc99999994
90000040cccccccc90000040cccccccc90000040cc9944cc90000040cccccccc90000040999949444444040090000040cccccccccccccccccccccccc90000040
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490999949444444040090444490cccccccccccccccccccccccc90444490
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490999949444444040090444490cccccccccccccccccccccccc90444490
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490999949444444040090444490cccccccccccccccccccccccc90444490
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490999949444444040090444490cccccccccccccccccccccccc90444490
94999990cccccccc94999990cccccccc94999990cc9944cc94999990cccccccc94999990999949444444040094999990cccccccccccccccccccccccc94999990
40000000cccccccc40000000cccccccc40000000cccccccc40000000cccccccc40000000000000000000000040000000cccccccccccccccccccccccc40000000
99999994cccccccc99999994cccccccc99999994cccccccc99999994cccccccc99999994c99994944440400c99999994cccccccccccccccccccccccc99999994
90000040cccccccc90000040cccccccc90000040cc9944cc90000040cccccccc90000040c99994944440400c90000040ccccccccc9ccc9cccccccccc90000040
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490c99994944440400c90444490cccccccc909c909ccccccccc90444490
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490c99994944440400c90444490ccccccccc922292ccccccccc90444490
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490c99994944440400c90444490cccccccc22222222cccccccc90444490
90444490cccccccc90444490cccccccc90444490c999944c90444490cccccccc90444490c99994944440400c90444490ccccccccc222222ccccccccc90444490
94999990cccccccc94999990cccccccc94999990cc9944cc94999990cccccccc94999990c99994944440400c94999990cccccccccc9cc9cccccccccc94999990
40000000cccccccc40000000cccccccc40000000cccccccc40000000cccccccc40000000c99994944440400c40000000ccccccccc9cccc9ccccccccc40000000
9999999499999994cccccccccccccccc99999994cccccccc99999994cccccccccccccccc9999999499999994cccccccccccccccc9999999499999994cccccccc
9000004090000040cccccccccccccccc90000040cccccccc90000040cccccccccccccccc9000004090000040cccccccccccccccc9000004090000040cccccccc
9044449090444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc9044449090444490cccccccccccccccc9044449090444490cccccccc
9044449090444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc9044449090444490cccccccccccccccc9044449090444490cccccccc
9044449090444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc9044449090444490cccccccccccccccc9044449090444490cccccccc
9044449090444490cccccccccccccccc90444490cccccccc90444490cccccccccccccccc9044449090444490cccccccccccccccc9044449090444490cccccccc
9499999094999990cccccccccccccccc94999990cccccccc94999990cccccccccccccccc9499999094999990cccccccccccccccc9499999094999990cccccccc
4000000040000000cccccccccccccccc40000000cccccccc40000000cccccccccccccccc4000000040000000cccccccccccccccc4000000040000000cccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccc99cc9cccc9cc9c9cccccccccccccccccccccc99cc99c99cc999c999c9c9cccccccccccccccccccccccccc99cc99cc9cc99cc999cc99ccccc
ccccc99999ccc9cc9c9c9ccc9c9c9c9ccccccccccccc9c9cc9cc9ccc9ccc9c9c9ccc9ccc999cccccccccccccc99999ccc9cc9ccc9ccc9c9c9c9c9ccc9ccccccc
cccc99ccc99cc9cc9c9c9ccc9c9cc9cccccccccccccc9c9cc9cc9ccc9ccc9c9c9ccc9ccc999ccccccccccccc99c9c99cc9cc9ccc9ccc9c9c9c9c9ccc9ccccccc
cccc99c9c99ccccc99cc9ccc999cc9cccccccccccccc9c9cccccc9cc9ccc99cc99cc99cc999ccccccccccccc999c999cccccc9cc9ccc9c9c99cc99ccc9cccccc
cccc99ccc99cc9cc9ccc9ccc9c9cc9cccccccccccccc9c9cc9cccc9c9ccc9c9c9ccc9ccc999ccccccccccccc99c9c99cc9cccc9c9ccc9c9c9c9c9ccccc9ccccc
ccccc99999ccc9cc9ccc9ccc9c9cc9cccccccccccccc9c9cc9cccc9c9ccc9c9c9ccc9ccc999cccccccccccccc99999ccc9cccc9c9ccc9c9c9c9c9ccccc9ccccc
cccccccccccccccc9ccc999c9c9cc9cccccccccccccccccccccc99ccc99c9c9c999c999c9c9ccccccccccccccccccccccccc99ccc99cc9cc9c9c999c99cccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccc4404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404cccccccc
cccccccc4404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404cccccccc
cccccccc4040440040404400404044004040440040404400404044004040440040404400404044004040440040404400404044004040440040404400cccccccc
cccccccc0444004404440044044400440444004404440044044400440444004404440044044400440444004404440044044400440444004404440044cccccccc
cccccccc0444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444cccccccc
cccccccc0440044404400444044004440440044404400444044004440440044404400444044004440440044404400444044004440440044404400444cccccccc
cccccccc4004404040044040400440404004404040044040400440404004404040044040400440404004404040044040400440404004404040044040cccccccc
cccccccc4404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404440444044404cccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__gff__
0100000000000000000000000000000000000000000000111100000000000000131311001511111111001131315151001111110015111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010101010101212b212b212b2101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0201010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010101010101010101010101010101012121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010101010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a01012a2a0101012a2a0101012a2a00000000000000000000000000000000010101010101010101010101011601010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a012a012a012a012a01012a012a010100000000000000000000000000000000010101010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a192a012a012a012a01012a012a0201000000002a2a2a2a2a2a2a2a00000000260101010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a01012a2a01012a01012a01012a01000000002a0101010101012a00000000361301010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a012a012a3b2a012a17182a0101012a000000002a0101010101012a00000000010101010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a012a012a3b2a012a27282a0111012a000000002a0101010101012a00000000010101010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2a2a01012a012a01012a2a01012a2a01000000002a2a2a2a2a2a2a2a00000000010114010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010101010101010101010101010101010101010101010101010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010101010101010101010101010101010000000000000000000000000000000001010101010101010101013b010101010101020101010114010101010101012100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010102150f01010101012c2c2c0101012121212121212121212121212121212100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0120202020202020202020202020200100000000000000000000000000000000012020202020202020202020202020010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010100000000000000000000000000000000010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100001036010360103601036010360103601036011350113501135011350113501135011350123401234012340123401234012340123400000000000000000000000000000000000000000000000000000000
010100001333013330133301333013330133301333014320143201432014320143201432014320153101531015310153101531015310153100030000300003000030000300003000030000300003000030000300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e000026320263201f32021320233202432026320263201f320303001f3201f32028320283202432026320283202a3202b3202b3201f320303001f3201f3202432024320263202432023320213202332023320
010e10002432023320213201f320213202132023320213201f3201e3201f3201f3201f3201f3201f3201f3202f3002f3002b3002d3002f3002b3002d3002d30026300283002a300263002b3002b300283002a300
010e00002f3202f3202b3202d3202f3202b3202d3202d32026320283202a320263202b3202b320283202a3202b3202832025320253202332025320213203030021320233202532026320283202a3202b3202b320
010e00002a3202a32028320283202a3202a3202132021320253202532026320263202632026320263203030026320263201f3201e3201f3201f32028320283201f3201e3201f3201f32026320263202432024320
010e00002332023320213201f3201e3201f32021320213201a3201c3201e3201f320213202332024320243202332023320213202132023320263201f3201f3201e3201e3201f3201f3201f3201f3201f3201f320
010e00001a3101a3101a3101a31015310153101731017310173101731017310173101831018310183101831018310183101731017310173101731017310173101531015310153101531015310153101331013310
010e1000133101331013310133101a3101a310173101731013310133101a3101a3100e31018310173101531018300183001730017300183001730015300133001530015300153001530012300123001330013300
010e00001731017310173101731015310153101331013310173101731013310133101831018310183101831018310183101731017310183101731015310133101531015310153101531012310123101331013310
010e10001331013310173101731018310183101a3101a3100e3100e31013310133101331013310133103030013300133001330013300133001330012300123001230012300123001230010300103001330013300
010e00001331013310133101331013310133101231012310123101231012310123101031010310133101331010310103101531015310153103030015310303001531015310153101531015310153101731017310
010e00001a3101a31019310193101a3101a310123101231015310153101a3101a3100e3100e310183101831017310173101a3101a310173101731018310183101c3101c310183101831017310173101531015310
010e000013310133101a3101a3101a3101a31030300303000e3100e3100e3100e310123101231010310103101331013310123101231013310133100c3100c3100e3100e31013310133100e3100e3101331013310
010e00002e3202e3202d3202d3202b3202b3202d3202d320263203030026320263202b3202b3201f32021320223202432026320263202632026320263202632029320293202b3202932027320263202732027320
010e10002932027320263202432026320263202b3202b3202432024320223202232022320223202232022320223002430026300263002630026300263002630029300293002b3002930027300263002730027300
010e000026320263202232024320263202832029320293202b3202b3202d3202d3202e3202e3202b3202d3202e3202b3202d3202d3202b3202d32029320293201d3201f320213202232024320263202732027320
010e0000263202632024320243202932029320223202232021320213202232022320223202232022320223201f3201f320263202432026320263201f3201f320273202632027320273201f320263201e32024320
010e00001f320223202132021320213202132030300303001a3201c3201e3201f320213202232024320243202232022320213202132022320263201f3201f3201e3201e3201f3201f3201f3201f3201f3201f320
010e00001331013310133101331013310133101131011310113101131011310113100f3100f3100f3100f3100f3100f3100e3100e3101a3101831016310153101631016310163101631015310153101631016310
010e1000163101631013310133101531015310123101231013310133100e3100e3101a310183101631015310163001630013300133001530015300123001230013300133000e3000e3001a300183001630015300
010e00001331013310133101331013310133101131011310113101131011310113100f3100f3100f3100f3100f3100f3100e3100e3101a3101831017310153101731017310173101731013310133101831018310
010e10001531015310113101131016310163100f3100f310153101531016310303001631016310163101630016300163001630016300163001530015300133001330011300113001330013300103001030000000
010e0000163101631016310163101631016310153101531013310133101131011310133101331010310103100c3100c3101131011310113101131030300303001531015310133101331011310113101331013310
010e000011310113100f3100f3100e3100e3100f3100f310113101131016310163101a3101a31018310183101a3101a3101a3101a3101a3101a31018310183101831018310183101831016310163101531015310
010e000013310133101a3101a310153101331012310103100e3100e3100e3100e31030300303000f3100f3100e3100e3100c3100c31016310163100c3100c3100e3100e310133103030013310133101331013310
010e18002532023320213202132021320263202332023320213203030021320213201c32021320253202132025320283202d3202d3202d3202d3202d3202d32028300283002d3002d30028300283002830028300
010e000028320283202d3202d320283202832028320283202a3202c3202d3202d320283202832028320283202a3202c3202d3202d3202b3202a320283202a3202b320283202a3202a32026320263202632021320
010e100023320243202332026320283202a3202b32023320253202632025320283202a3202b3202d320253202630028300263002b3002f3002d3002b3002a3002830026300253002530021300213002130021300
010e00002632028320263202b3202f3202d3202b3202a3202832026320253202532021320213202132021320263202132023320213201f3201e3201f320233202832023320253202132023320253202632028320
010e18002a3202b3202d3202d32026320263202a320283202632025320263202632021320263202a320263202a3202d32030320303203032030320303203032015300153000e3000e3001a300193001a3001a300
010e000024300303001a3101a3101f3101f3101e3101e3101c3101c3101a3101a3101f3101f3101e3101e3101c3101c3101e3101e3101a3101a310193101931015310153100e3100e3101a310193101a3101a310
010e10000e310303000e3100e3101a310193101a3101a3100e310303000e3100e3101a310193101a3101a3100e3000e3000d3000d30012300123000e3000e3001030010300153003030015300103001530010300
010e18000e3100e3100d3100d31012310123100e3100e3101031010310153103030015310103101531010310153101031015310153101c3101c31021310213101030010300153003030015300103001530010300
010e0000303003030021310213102631026310253102531023310233102131021310263102631025310253102331023310213102131023310233102531025310213102131026310263101a3101c3101e3101e310
010e10001a3101a3101f3101f3103030030300303003030020310203102131021310303003030030300303002030020300213002130030300303003030030300223002230023300233001f3001f3001c3001c300
010e0000223102231023310233101f3101f3101c3101c3101f3101f3102131015310213101f3101e3101c3101e3101a3101331013310303003030030300303001f3101f310213102131023300233001f3001f300
010e18001f3101f3101e3101e31023310233101f3101f31021310213101a3101a3100e3101a3100e3101a3100e3101a3100e3100e31015310153101a3101a3100000000000000000000000000000000000000000
011800001f320183001f320303001f32030300243202432026320273202632026320243202432022320213202632026320223202232021320223201f3201f3202232030300223203030022320303002632026320
011810002732029320223202232024320243202132021320213202132022320223202232022320223202232030300303003030030300303003030030300243000000000000000000000000000000000000000000
011800002432030300243202b300243202b30024320243202432022320213202132026320263202432022320213201f3201e3201e3201e3201e3201e3201e3201a3201a3201e3201e32021320213202432024320
011800002632027320263202632022320223201f3201f3201e3201e3201f3201f3201f3201f3201f3201f32024320303002432030300243203030024320243202432022320213202132026320263202432022320
01180000213201f3201e3201e3201e3201e3201e3201e3201a3201a3201e3201e320213202132024320243202632027320263202632022320223201f3201f3201e3201e3201f3201f3201f3201f3201f32000000
0118000013310133101f3101f3101d3101d3101b3101b3101531015310163101631018310183101a3101a3100e3100e31013310133101a3101a3101f3101f3101a310163101b3101d3101f310213102231022310
011810001d3101d3101f3101f3101b3101b3101d3101d3101131011310163101631022310243102631024310153001630015300133001130010300113001130018300183001d3001d30016300163001b3001b300
01180000223102431022310213101f3101d3101b3101b3101531015310163101631018310183101a3101a3100e3100e31013310133101a3101a3101f3101f3101a310163101b3101d3101f310213102231022310
011810001d3101d3101f3101f3101b3101b3101d3101d31011310113101631015310163101a31018310163100e3000e30013300133001a3001a3001f3001f3001a300163001b3001d3001f300213002230022300
01180000153101631015310133101131010310113101131018310183101d3101d31016310163101b3101b31018310183101a310263102431022310213101f3101e31022310213101f3101e3101c3101a3101a310
011800001e3101e3101a3101a3101f3101f31016310163101a3101a310133101231013310153101631013310153101631015310133101131010310113101131018310183101d3101d31016310163101b3101b310
0118000018310183101a310263102431022310213101f3101e31022310213101f3101e3101c3101a3101a3101e3101e3101a3101a3101f3101f31016310163101a3101a310133101331013310133101331000000
011500001885018950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00001f3301f33000000183301833000000000000000024330243300000021330000001f3301f3300000018330183300000000000000001f3301f330000001d330000001c330000001c330000001d33000000
010c00001f330000001833018330000001a3301a330000001c3301c3301c3301c330000001f3001f300003001f3301f330000001833018330003001c3000030024330243300000021330000001f3301f33000000
010c000018330183300000000000000001f3301f330000001d330000001c330000001c330000001d330000001f330000001833018330000001a3301a330000001833018330183301833000000000000000000000
0110080018300183000000000000000001f3001f300000001d300000001c300000001c300000001d300000001f300000001830018300000001a3001a300000001830018300183001830000000000000000000000
__music__
01 080d4344
00 090e4344
00 080f4344
00 09104344
00 0a114344
00 0b124344
02 0c134344
00 7f424344
01 14194344
00 151a4344
00 141b4344
00 151c4344
00 161d4344
00 171e4344
02 181f4344
00 7f424344
01 21254344
00 22264344
00 20274344
00 21284344
00 22294344
00 232a4344
02 242b4344
00 7f424344
01 2c314344
00 2d324344
00 2c334344
00 2d344344
00 2e354344
00 2f364344
02 30374344
00 7f424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
04 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 3c424344
00 3d424344
02 3e7f4344

