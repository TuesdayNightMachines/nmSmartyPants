-- nmSmartyPants
-- 0.0.4 @NightMachines
-- llllllll.co/t/nmsmartypants/
--
-- if you regularly fail at
-- elementary school level math
-- then this script is for you
--
-- K1: hold for /alt controls
-- E1: select operator/number
-- K2: randomize r formula
--     /reset r formula
-- K3: randomize p formula
--     /reset p formula
-- E2: dry wet mix
-- E3: change value by 0.1
--     /change value by 1.0


-- _norns.screen_export_png("/home/we/dust/nmSmartyPants.png")
-- norns.script.load("code/nmSmartyPants/nmSmartyPants.lua")


--adjust encoder settigns to your liking
--norns.enc.sens(0,2)
--norns.enc.accel(0,false)

local devices = {}
local ops = {"+","-","*","/","%"}
local vPos = 0
local rResult = 0 -- record result
local pResult = 0--- play result
local rRes = 0 -- temporary result for calulations
local pRes = 0
local opCount = 6 -- number of operators
local ids = {"op1","no1","op2","no2","op3","no3","op4","no4","op5","no5","op6","no6"}
local tape = {}
local k1held = 0
local message = "nmSmartyPants"
local msgOn = 1

function init()
  for id,device in pairs(midi.vports) do
    devices[id] = device.name
  end
  
  for i=1,101 do
    tape[i] = 1
  end
  
  params:add_group("nmMathProblem",13)
  
  params:add{type = "option", id = "midi_input", name = "Midi Input", options = devices, default = 1, action=set_midi_input}

  params:add_separator()
  
  params:add{type = "number", id = "sel", name = "Selection", min = 1, max = opCount*2, default = 1, wrap = false, action=function(x) end}
  params:add{type = "number", id = "dryWet", name = "Dry/Wet", min=0, max=10, default = 5, wrap = false, action=function(x) dryWet(x) end}

  params:add_separator("Record")
  params:add{type = "option", id = ids[1], name = "Operator 1", options = ops, default = 3}
  params:add{type = "number", id = ids[2], name = "Number 1", min = -100, max = 100, default = 1, wrap = false, action=function(x) msgMe() end}
  params:add{type = "option", id = ids[3], name = "Operator 2", options = ops, default = 5}
  params:add{type = "number", id = ids[4], name = "Number 2", min = -100, max = 100, default = 6, wrap = false, action=function(x) msgMe() end}
  params:add{type = "option", id = ids[5], name = "Operator 3", options = ops, default = 1}
  params:add{type = "number", id = ids[6], name = "Number 3", min = -100, max = 100, default = 47, wrap = false, action=function(x) msgMe() end}
 
  params:add_separator("Play") 
  params:add{type = "option", id = ids[7], name = "Operator 4", options = ops, default = 3}
  params:add{type = "number", id = ids[8], name = "Number 4", min = -100, max = 100, default = -0.5, wrap = false, action=function(x) msgMe() end}
  params:add{type = "option", id = ids[9], name = "Operator 5", options = ops, default = 5}
  params:add{type = "number", id = ids[10], name = "Number 5", min = -100, max = 100, default = 6, wrap = false, action=function(x) msgMe() end} 
  params:add{type = "option", id = ids[11], name = "Operator 6", options = ops, default = 1}
  params:add{type = "number", id = ids[12], name = "Number 6", min = -100, max = 100, default = 47, wrap = false, action=function(x) msgMe() end} 
  
  --params:add_control("vLen1","Cloud 1 Altitude", controlspec.new(0.1,4.1,"lin",0.1,1.0,"",0.025,false))
  
  
  softcut.buffer_clear()
  softcut.buffer_clear_region_channel(1,0,100)
  audio.level_adc_cut(1)

  audio.level_monitor(0.5)
  
  for i=1,3 do
    softcut.enable(i,1)
    softcut.pan(i,0)
    softcut.buffer(i,1)
    softcut.rate(i,1.0)
    softcut.loop(i,1)
    softcut.loop_start(i,0)
    softcut.loop_end(i,100)

    softcut.rec_level(i,1.0)
    softcut.position(i,0)
    softcut.play(i,1)
  end
  
  -- voice 1 is record head
  softcut.level_input_cut(1,1,1.0)
  softcut.level_input_cut(2,1,1.0)
  softcut.pre_level(1,0)
  softcut.level(1,0)
  softcut.rec(1,1)
  
  -- voice 2 is play head
  softcut.pre_level(2,1)
  softcut.level(2,params:get("dryWet")/10)
  softcut.rec(2,0)
  
  -- voice 3 keeps time
  softcut.phase_quant(3,0.01)
  softcut.level(3,0)

  softcut.event_phase(updatePos)
  softcut.poll_start_phase()
  
  redraw()

end


function updatePos(v,p) -- v = voice, p = position
  vPos=vPos+0.01
  
  if vPos > 100 then
    vPos=0
  elseif vPos < 0 then
    vPos = 100
  end
  
  vPos=round(vPos*100)/100
  
  rResult=vPos
  rRes=vPos
  rfOp(1,rRes)
  rResult = round((rRes%100)*100)/100
  softcut.position(1,rResult)
  tape[round(rResult)+1] = 8

  pResult=vPos
  pRes=vPos
  pfOp(round(opCount/2)+1,pRes)
  pResult = round((pRes%100)*100)/100
  softcut.position(2,pResult)
  softcut.pan(2,((pResult/50)-1)*-1)

end

function rfOp(o,v) -- o=operator number, v=value to calculate with
    if o <= opCount/2 then
      if params:get("op"..o) == 1 then -- +
        rRes = rRes+params:get("no"..o)
        rfOp(o+1,rRes)
      elseif params:get("op"..o) == 2 then -- -
        rRes = rRes-params:get("no"..o)
        rfOp(o+1,rRes)
      elseif params:get("op"..o) == 3 then -- *
        rRes = rRes*params:get("no"..o)
        rfOp(o+1,rRes)
      elseif params:get("op"..o) == 4 then -- /
        pcall(function() rRes = rRes/params:get("no"..o) end)
        rfOp(o+1,rRes)
      elseif params:get("op"..o) == 5 then -- %
        pcall(function() rRes = rRes%params:get("no"..o) end)
        rfOp(o+1,rRes)
      end
    end
end

function pfOp(o,v) -- o=operator number, v=value to calculate with
    if o> opCount/2 and o <= opCount then
      if params:get("op"..o) == 1 then -- +
        pRes = pRes+params:get("no"..o)
        pfOp(o+1,pRes)
      elseif params:get("op"..o) == 2 then -- -
        pRes = pRes-params:get("no"..o)
        pfOp(o+1,pRes)
      elseif params:get("op"..o) == 3 then -- *
        pRes = pRes*params:get("no"..o)
        pfOp(o+1,pRes)
      elseif params:get("op"..o) == 4 then -- /
        pcall(function() pRes = pRes/params:get("no"..o) end)
        pfOp(o+1,pRes)
      elseif params:get("op"..o) == 5 then -- %
        pcall(function() pRes = pRes%params:get("no"..o) end)
        pfOp(o+1,pRes)
      end
    end
end


function changeVal(s,d)
  params:delta(ids[s],d)
end


function dryWet(x) -- adjust input monitor level on param change
  audio.level_monitor(((x/10)-1)*-1)
  softcut.level(2,x/10)
end

function randomizer(x)
  if x == "r" then
    for i=1,5,2 do
      params:set(ids[i],math.random(1,5))
    end
    for i=2,6,2 do
      params:set(ids[i],math.random(-100,100)/2)
    end
  elseif x == "p" then
    for i=7,11,2 do
      params:set(ids[i],math.random(1,5))
    end
    for i=8,12,2 do
      params:set(ids[i],math.random(-100,100)/2)
    end
  elseif x == "rr" then -- reset r values
    for i=1,6 do
      params:set(ids[i],1)
    end
  elseif x == "pr" then -- reset p values
    for i=7,12 do
      params:set(ids[i],1)
    end
  end
end


-- BUTTONS
function key(id,st)
  if id==1 then
    if st==1 then
      k1held = 1
    else
      k1held =0
    end
  elseif id==2 and st==1 then
    msgOn = 0
    if k1held==1 then
      randomizer("rr") --reset
    else
      randomizer("r")
    end
  elseif id==3 and st==1 then
    msgOn = 0
    if k1held==1 then
      randomizer("pr")  --reset
    else
      randomizer("p")  
    end
  end
end


-- ENCODERS
function enc(id,delta)
  if id==1 then  -- select value
    params:delta("sel",delta)
  elseif id==2 then
    params:delta("dryWet", delta)
  elseif id==3 then  -- change value
    msgOn = 1
    if k1held ==1 then
      params:delta(ids[params:get("sel")],delta)
    else
      params:delta(ids[params:get("sel")],round(delta)/10)
    end
    if params:get(ids[params:get("sel")])<0.1 and params:get(ids[params:get("sel")])>-0.1 then
      params:set(ids[params:get("sel")],0)
    else
      params:set(ids[params:get("sel")],round(params:get(ids[params:get("sel")])*100)/100)
    end 
end
end



function redraw()
  screen.clear()
  screen.line_width(1)
  
  screen.level(0)
  screen.move(0,0)
  screen.rect(0,0,128,64)
  screen.fill()
  
  -- top box
  screen.level(2)
  screen.rect(0,0,128,9)
  screen.fill()
  screen.level(0)
  screen.move(2,6)
  if k1held==1 then
    screen.text("turbo!")
  else
    screen.text(message)
  end
  
  -- formulas
  screen.level(2)
  screen.move(0,11)
  screen.line_rel(128,0)
  screen.stroke()
  
  screen.level(2)
  screen.move(2,19)
  screen.text("r =   t") 
  for i=1,#ids/2 do
    if params:get("sel")==i then
      screen.level(15)
    else
      screen.level(2)
    end
    if i%2==0 then --if even id number then number
      screen.text(" "..params:get(ids[i]))
    else --- if odd id number then operator
      screen.text(" "..ops[params:get(ids[i])] )
    end
  end
  
  screen.level(2)
  screen.move(2,29)
  screen.text("p =   t") 
  for j=7,#ids do
    if params:get("sel")==j then
      screen.level(15)
    else
      screen.level(2)
    end
    if j%2==0 then --if even id number then number
      screen.text(" "..params:get(ids[j]))
    else --- if odd id number then operator
      screen.text(" "..ops[params:get(ids[j])] )
    end
  end
  
  screen.level(2)
  screen.move(0,33)
  screen.line_rel(128,0)
  screen.stroke()
  
  -- bottom box
  screen.rect(0,55,128,64)
  screen.fill()
  screen.level(0)
  screen.move(2,62)
  screen.text("t"..vPos)
  screen.move(48,62)
  screen.text("r"..rResult)
  screen.move(96,62)
  screen.text("p"..pResult)
  
  -- line indicator thing
  for i=1,101 do
    if tape[i]>5 then
      screen.level(tape[i])
      screen.move(i+13,42) --31
      screen.line_rel(0,3)
      screen.stroke()
    else
      screen.level(tape[i])
      screen.pixel(i+13,43) --32
      screen.stroke()
    end
  end
  
  screen.level(3)
  screen.circle(5,43,5)
  screen.stroke()
  screen.level(params:get("dryWet"))
  screen.circle(5,43,3)
  screen.stroke()

  screen.level(3)
  screen.circle(122,43,5)
  screen.stroke()
  screen.level(params:get("dryWet"))
  screen.circle(122,43,3)
  screen.stroke()
  
  screen.level(8)
  screen.move(round(rResult)+12,39) --27
  screen.text("r")
  screen.move(round(rResult)+14,42) --31
  screen.line_rel(0,-2)
  screen.stroke()
  
  screen.move(round(pResult)+12,52) --42
  screen.text("p")
  screen.move(round(pResult)+14,45) --34
  screen.line_rel(0,2)
  screen.stroke()  

  
  
  screen.update()

  result = 0
end




re = metro.init() -- screen refresh
re.time = 1.0 / 15
re.event = function()
  redraw()
end
re:start()




-- MIDI Stuff
function set_midi_input(x)
  update_midi()
end

function update_midi()
  if midi_input and midi_input.event then
    midi_input.event = nil
  end
  midi_input = midi.connect(params:get("midi_input"))
  midi_input.event = midi_input_event
end

function midi_input_event(data)
  msg = midi.to_msg(data)
  -- do something if you want
end

function round(n)
  return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

local messages = {
  "You're looking good today.",
  "Twist those knobs!",
  "Interesting choice.",
  "What a nice sound.",
  "I like it!",
  "Wanna go out some time?",
  "You're mathemagic!",
  "Absolutely brilliant!",
  "Nice digits.",
  "Cool formulae!", --10
  "What's a Norns anyway?",
  "You're doing great!",
  "Fantastic!",
  "You've got cute ears.",
  "Lovely :)",
  "You know some numbers!",
  "The teachers would be proud.",
  "Well done!",
  "Uuuh, goosebumps!",
  "Shake it!", --20
  "Have you ever modeled?",
  "You're a smart one!",
  "Such soft fingers!",
  "Oh yeah!",
  "Crunch those numbers!",
  "You should get a PHD.",
  "I see you and me likey.",
  "Gimme a kiss!",
  "You're a pretty one!",
  "You're my favorite.",
  "You raise my numbers.",
  "Ask me about Loom."
}


function msgMe()
  if msgOn == 1 then
    local randmonn = math.random(1,750)
    if randmonn ==1 then
      message = messages[math.random(1,#messages)]
    end
  end
end

