package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit');local SDK=require('tests.modkit.sdk');local Loader=require('src.mods.Loader')
require('src.core.Version').engine='0.3.97'
local root=assert(os.getenv('QOL_PROJECT'))
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
for _,game in ipairs({'emerald','ruby','sapphire','firered','leafgreen'})do
 require('src.core.GameVersion').set(game);T.sdk.captureRuntime()
 local files={};for _,p in ipairs({'manifest.json','main.lua','experience.lua','settings.lua','features.lua'})do files['mods/qol_jo5k/'..p]=read(root..'/qol_jo5k/'..p)end
 files['options.lua']='return {mods={qol_jo5k=true}}'
 local fs=SDK.memfs(files);local loader=Loader.new({fs=fs,generation=3,version=game})
 local owner={data=SDK.gen3Data(),mods=loader,generation=3,save={version=game,options={}}};loader.game=owner
 assert(loader:load(owner.data));for _,e in ipairs(loader.errors)do print(e.message or e.error or tostring(e))end
 local api=assert(loader.exports.qol_jo5k)
 local counts=api.allocate(101,{1},{1,2,3,4,5,6});assert(counts[1]==51 and counts[2]==10 and counts[6]==10)
 counts=api.allocate(100,{1},{1,2,3});assert(counts[1]==50 and counts[2]==25 and counts[3]==25)
 counts=api.allocate(101,{1,2},{1,2,3,4});assert(counts[1]==26 and counts[2]==25 and counts[3]==25 and counts[4]==25)
 assert(api.allocate(100,{1},{1})[1]==100)
 local Space=require('src.core.game3.scripting.space');local oldBundle,oldVm=Space.bundle,Space.vm
 local flags=require('src.core.game3.scripting.flags')
 Space.bundle={labels={Common_EventScript_PkmnCenterNurse='nurse'},scripts={nurse={{op='callstd',std=5},{op='call',target='heal'}},heal={{op='special',id=0}}}}
 Space.vm={_scriptKey='nurse',store=flags.newStore(),ctx={pc={listKey='nurse'},specialVars={}}}
 local called=0
 loader.hooks:call('script.command',function()called=called+1 end,{},'callstd',{op='callstd',std=5})
 assert(called==0 and Space.vm.ctx.specialVars[0x800D]==1,'nurse confirmation auto-accepts')
 loader.hooks:call('script.command',function()called=called+1 end,{},'multichoice',{op='multichoice'})
 assert(called==0 and Space.vm.ctx.specialVars[0x800D]==0,'FRLG multichoice YES is row zero, no prompt')
 Space.vm.ctx.pc.listKey='heal';loader.hooks:call('script.command',function()called=called+1 end,{},'special',{op='special',id=0});assert(called==1,'native healing preserved')
 Space.vm.ctx.pc.listKey='other';loader.hooks:call('script.command',function()called=called+1 end,{},'callstd',{op='callstd',std=5});assert(called==2,'other dialogues unaffected')
 if game=='emerald' and os.getenv('EMERALD_SCRIPTS')then
  local d=os.getenv('EMERALD_SCRIPTS')
  local labels=assert(loadfile(d..'/labels.lua'))();local scripts=assert(loadfile(d..'/scripts.lua'))()
  Space.bundle={labels=labels,scripts=scripts}
  local healed,messages=0,0
  local VM=require('src.core.game3.scripting.vm')
  local adapters=require('src.core.game3.scripting.adapters').stub({nurseHeal=function(done)healed=healed+1;done()end,onMessage=function()messages=messages+1 end})
  local vm=VM.new({scripts=scripts,store=flags.newStore(),text={},adapters=adapters,version=game})
  Space.vm=vm
  assert(vm:start(labels.Common_EventScript_PkmnCenterNurse))
  for i=1,100 do vm:tick()end
  assert(healed==1 and messages==0 and not vm:isRunning(),'real Emerald nurse VM heals once without prompts and exits')
 end
 local Battle=require('src.core.game3.battle');local get=Battle.getState
 local Experience=require('src.core.game3.battle.experience');local P=require('src.core.game3.pokemon')
 local yield,opts,names=P.speciesMeta,Experience.recipientOpts,P._names
 P._names=owner.data.gen3Pokemon._names
 P.speciesMeta=function()return {expYield=140,growthRate=0}end
 Experience.recipientOpts=function()return {traded=false,luckyEgg=false}end
 local party={};for i=1,6 do party[i]={species=4,level=10,hp=30,maxHp=30,exp=1000,moves={},evs={},ivs={},stats={hp=30,atk=20,def=20,spe=20,spa=20,spd=20}}end
 local st={wild=true,playerParty=party,player={partyIndex=1,mon=party[1]},session={}}
 Battle.getState=function()return st end
 local foe={species=16,mon={species=16,level=10},participants={[1]=true},level=10}
 loader.modOptions.qol_jo5k={experience='party',quick_nurse=true}
 local oldEV=P.gainEVs;local evs=0;P.gainEVs=function()evs=evs+1 end
 local out=Experience.awardFoe(st,foe,{getOpts=function()return {traded=false,luckyEgg=false}end})
 assert(#out==6 and out[1].amount==100 and out[2].amount==20 and out[6].amount==20,'native 50/50 award for six')
 assert(evs==6,'EV pipeline once per recipient')
 party[6].hp=0;party[5].isEgg=true
 out=Experience.awardFoe(st,foe,{getOpts=function()return {}end});assert(#out==4 and out[1].amount==100,'fainted and eggs excluded')
 loader.modOptions.qol_jo5k.experience='native';out=Experience.awardFoe(st,foe,{getOpts=function()return {}end});assert(#out==1 and out[1].amount==200,'native mode untouched')
 P._names=names;P.gainEVs=oldEV;P.speciesMeta=yield;Experience.recipientOpts=opts;Battle.getState=get;Space.bundle,Space.vm=oldBundle,oldVm
 local rows=loader.hooks:call('ui.start_menu.items',function(_,r)return r end,owner,{{id='save',label='SAVE'}})
 local shortcut;for _,r in ipairs(rows)do if r.id=='qol_jo5k_settings'then shortcut=r end end
 assert(shortcut,'START has QOL settings');shortcut.onSelect()
 local screen=assert(require('src.ui.game3.mod_ui').stackFor(owner):top())
 assert(#screen.items==14,'all options and language are available')
 local Font=require('src.ui.game3.frlg_font');local nativeDraw=Font.draw;local drawn={}
 Font.draw=function(text)drawn[#drawn+1]=text end
 screen:draw();assert(#drawn>=12 and table.concat(drawn,'|'):find('Idioma / Language',1,true),'Gen3 labels actually drawn')
 Font.draw=nativeDraw
 local pressed={};owner.input={wasPressed=function(_,key)return pressed[key]end,isDown=function()return false end}
 pressed.down=true;screen:update(1/60);assert(screen.index==2,'controller navigates')
 pressed={b=true};screen:update(1/60);assert(not require('src.ui.game3.mod_ui').stackFor(owner):top(),'B closes menu')
 shortcut.onSelect();screen=assert(require('src.ui.game3.mod_ui').stackFor(owner):top())
 local Manager=require('src.mods.ManagerState');Manager.new(owner):setOption('qol_jo5k','language','en')
 -- Cycle language through the same callback used by controller and touch.
 screen.onChoose(screen.items[1],screen)
 screen.onChoose(screen.items[1],screen)
 assert(loader.modOptions.qol_jo5k.language=='en')
 screen.onChoose(screen.items[2],screen)
 assert(loader.modOptions.qol_jo5k.quick_nurse==false)
 screen:close();api.shutdown();api.shutdown()
 assert(#loader.errors==0,'no callback errors');T.sdk.restoreRuntime();print('PASS QoL '..game)
end
