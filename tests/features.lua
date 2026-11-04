local root=assert(arg[1]);local options={};local hooks={};local state={wild=true,playerParty={}}
local function module(name,t)package.loaded[name]=t;return t end
local nativeCalls={}
local function count(name,result)return function(...)nativeCalls[name]=(nativeCalls[name]or 0)+1;return result end end
local Bag=module('src.core.game3.bag',{remove=count('remove',true)})
local learnedCallback
local Learn=module('src.core.game3.battle.learn_move',{begin=function(opts)learnedCallback=opts.onDone end})
local Use=module('src.core.game3.item_use',{useTm=function(_,bag,id,slot)
 if slot==4 then Learn.begin({onDone=function(ok)if ok then Bag.remove(bag,id,1)end end})else Bag.remove(bag,id,1)end
 return true,'tm',nil,'last'
end})
local Battle=module('src.core.game3.battle',{getState=function()return state end})
module('src.core.game3.runtime',{getSession=function()return {}end})
module('src.core.Game3',{})
module('src.core.game3.items_data',{isTm=function(id)return id>=289 and id<=338 end,isHm=function(id)return id>=339 end})
module('src.core.game3.field_moves',{})
local Help=module('src.ui.game3.help_system',{update=count('help',true),show=count('show',true),isOpen=function()return false end})
local caught={success=true,mon={hp=1,maxHp=40,status='poison'}}
local Catch=module('src.core.game3.battle.catching',{storeCaught=function()return caught end})
module('src.core.game3.party',{healAll=function(list)for _,m in ipairs(list)do m.hp=m.maxHp;m.status=nil end end})
local Prize=module('src.core.game3.battle.prize',{calc=function()return 100 end,calcRse=function()return 200 end})
local Held=module('src.core.game3.battle.held_items',{consume=count('held')})
local Daycare=module('src.core.game3.daycare',{step=function()return 2,nil end})
local View=module('src.core.game3.field_view',{flashRadius=function()return 50 end})
local Message=module('src.ui.game3.message',{show=function(_,opts)return opts end,tick=count('tick'),isTyping=function()return true end,isRsFieldAutoScroll=function()return false end,skipReveal=count('skip')})
local Rs=module('src.ui.game3.rs.field_auto_scroll_message',{open=function()return true end,tick=count('rsTick'),isPrinting=function()return false end})
local TB=module('src.render.TextBox',{new=function(_,_,_,opts)return opts end})
local mod={id='qol_jo5k',hooks={wrap=function(_,name,fn)hooks[name]=fn end},content={}}
local function option(k,d)if options[k]~=nil then return options[k]end;return d end
local stop=assert(loadfile(root..'/features.lua'))()(mod,option)
Use.useTm({}, {},289,1);assert(nativeCalls.remove==1,'native TM consumed')
options.reusable_tms=true
local a,b,c,d=Use.useTm({}, {},289,1);assert(a and b=='tm'and c==nil and d=='last','native returns preserved');assert(nativeCalls.remove==1,'TM use kept')
Bag.remove({},289,1);assert(nativeCalls.remove==2,'sale/discard still removes TM')
Use.useTm({}, {},289,4);assert(learnedCallback);learnedCallback(true);assert(nativeCalls.remove==2,'asynchronous teaching kept')
options.reusable_tms=false;Use.useTm({}, {},289,4);learnedCallback(true);assert(nativeCalls.remove==3,'toggle checked when asynchronous learning finishes')
options.disable_help=true;assert(Help.update({})==false and Help.show({})==false);options.disable_help=false;assert(Help.update({})==true)
options.heal_caught=true;assert(Catch.storeCaught().mon.hp==40 and caught.mon.status==nil)
options.always_catch=true;assert(hooks['catch.rate'](function()return false end,'BALL',{}, {},{})==true)
state.link=true;assert(hooks['catch.rate'](function()return false end,'BALL',{}, {},{})==false);state.link=nil
options.exp_multiplier=5;assert(hooks['exp.gain'](function()return 10 end,{})==50)
options.money_multiplier=3;assert(Prize.calc()==300 and Prize.calcRse()==600);options.money_multiplier=1;assert(Prize.calc()==100)
local mon={hp=10};state.playerParty={mon};options.infinite_held=true;Held.consume({}, {mon=mon});assert(not nativeCalls.held);Held.consume({}, {mon={}});assert(nativeCalls.held==1,'enemy item consumed normally')
options.instant_eggs=true;local count,slot=Daycare.step({party={{hp=10},{isEgg=true}}});assert(count==2 and slot==2)
options.instant_eggs=false;assert(select(2,Daycare.step({party={{isEgg=true}}}))==nil)
options.auto_flash=true;assert(View.flashRadius()==nil);options.auto_flash=false;assert(View.flashRadius()==50)
options.instant_text=true;assert(Message.show('text',{}).speed==0);Message.tick();assert(nativeCalls.skip==1);assert(TB.new({},'text',nil,{}).noLetterDelay)
options.hm_without_move=true
local candidate={hp=10,isEgg=false};assert(hooks['fieldmove.eligibility'](function()end,'SURF',{party={candidate}})==candidate)
assert(hooks['fieldmove.eligibility'](function()end,'TELEPORT',{party={candidate}})==nil,'only HMs bypass learned move')
stop();stop();assert(Prize.calc()==100 and View.flashRadius()==50 and Message.show('text',{}).speed==nil,'native methods restored')
local build=assert(loadfile(root..'/settings.lua'))();local en,pt=build('en'),build('pt-BR');assert(#en==14 and #pt==14)
for i,r in ipairs(en)do assert(r.key==pt[i].key and r.label~=nil and pt[i].label~=nil)end
print('PASS: TM sync/async and sale guard; help; catch heal/rate; XP/money; held items; eggs; Flash; text; HM; bilingual settings; cleanup')
