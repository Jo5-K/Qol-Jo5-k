return function(mod)
 local GV=require('src.core.GameVersion')
 if not ({emerald=true,ruby=true,sapphire=true,firered=true,leafgreen=true})[GV.get()]then return end
 local X=assert(loadstring(assert(mod:read('experience.lua')),'@qol_jo5k/experience.lua'))()
 local settings=assert(loadstring(assert(mod:read('settings.lua')),'@qol_jo5k/settings.lua'))()
 local function define()mod.options:define(settings(mod.options:get('language')or 'pt-BR'))end
 define()
 local Space=require('src.core.game3.scripting.space')
 local Battle=require('src.core.game3.battle')
 local Flags=require('src.core.game3.scripting.flags')
 local pending,recipients,eligible
 local function option(k,d)local v=mod.options:get(k);if v==nil then return d end;return v end
 mod.hooks:wrap('battle.exp_award',function(nextFn,ctx)
  if option('experience','native')~='party' then return nextFn(ctx)end
  local st=Battle.getState()
  if not st or st.link or st.safari or st.oldManTutorial or type(ctx.applyShare)~='function' then return nextFn(ctx)end
  local indices={}
  for i=1,6 do if X.eligible((st.playerParty or {})[i])then indices[#indices+1]=i end end
  if #indices==0 then return nextFn(ctx)end
  local previousR,previousE=recipients,eligible
  recipients,eligible=ctx.recipients or {},indices
  local ok,err=pcall(function()
   for _,i in ipairs(indices)do
    pending=i
    -- Native award handles EVs, level-up events, move learning and animation.
    ctx.applyShare(st.playerParty[i],1)
   end
  end)
  pending=nil;recipients,eligible=previousR,previousE
  if not ok then error(err,0)end
 end,1000)
 mod.hooks:wrap('exp.gain',function(nextFn,ctx)
  if not pending or ctx.index~=pending then return nextFn(ctx)end
  local total=math.floor((tonumber(ctx.defeatedDef and ctx.defeatedDef.baseExp)or 0)*math.max(1,tonumber(ctx.level)or 1)/7)
  local amount=X.allocate(total,recipients,eligible)[pending]or 0
  if ctx.luckyEgg then amount=math.floor(amount*1.5)end
  if ctx.isTrainer then amount=math.floor(amount*1.5)end
  if ctx.traded then amount=math.floor(amount*1.5)end
  return amount
 end,-1000)
 -- Resolve symbolic labels from the active cartridge, never fixed addresses.
 local bundle,marked,roots
 local function refresh()
  local b=Space.bundle
  if b==bundle then return end;bundle=b;marked={};roots={}
  if not b or not b.labels or not b.scripts then return end
  for name,key in pairs(b.labels)do
   if name=='Common_EventScript_PkmnCenterNurse' or name=='EventScript_PkmnCenterNurse' or name=='EventScript_PokemonCenterNurse' then roots[key]=true end
  end
  local function walk(key)
   if marked[key]then return end;marked[key]=true
   for _,row in ipairs(b.scripts[key]or {})do
    if row.target and ({call=true,call_if=true,goto=true,goto_if=true})[row.op]then walk(row.target)end
   end
  end
  for key in pairs(roots)do walk(key)end
 end
 mod.hooks:wrap('script.command',function(nextFn,ctx,op,row)
  if option('quick_nurse',true)==false then return nextFn(ctx,op,row)end
  refresh()
  local vm=Space.getVm();local key=vm and vm.ctx and vm.ctx.pc and vm.ctx.pc.listKey
  if key and roots[key]then vm._jo5QuickNurseOwner=vm._scriptKey or key end
  if not key or not marked[key]or vm._jo5QuickNurseOwner~=(vm._scriptKey or key)then return nextFn(ctx,op,row)end
  -- Only the native healing call graph. Keep movement, actual heal, Pokerus,
  -- stat/flag updates and control release; skip dialogue and confirmations.
  -- FRLG's nurse uses MULTICHOICE_YES_NO (YES is row zero), unlike
  -- Hoenn's MSGBOX_YESNO (YES is one). Never expose the Kanto menu.
  if roots[key]and(op=='multichoice'or op=='multichoicedefault'or op=='multichoicegrid')then
   Flags.setVar(vm.store,vm.ctx,0x800D,0);return false
  end
  if op=='callstd' then
   local std=row.std or row[1]
   if std==5 then Flags.setVar(vm.store,vm.ctx,0x800D,1);return false end
   if std==4 then return false end
  end
  if op=='message' or op=='waitmessage' or op=='waitbuttonpress' or op=='yesnobox' then
   if op=='yesnobox' then Flags.setVar(vm.store,vm.ctx,0x800D,1)end
   return false
  end
  return nextFn(ctx,op,row)
 end)
 local stopFeatures=assert(loadstring(assert(mod:read('features.lua')),'@qol_jo5k/features.lua'))()(mod,option)
 mod.exports.shutdown=stopFeatures
 mod.events:on('mod.options_changed',function(e)if e and e.mod==mod.id and e.key=='language'then define()end end)
 local SCREEN='qol_jo5k_settings'
 mod.content.screens:register(SCREEN,{new=function(game)
  local items={};for _,row in ipairs(settings(option('language','pt-BR')))do items[#items+1]={key=row.key}end
  local function refresh(menu)
   local en=option('language','pt-BR')=='en';menu.title='Qol - Jo5-k'
   local schema=settings(option('language','pt-BR'))
   for i,item in ipairs(menu.items)do
    local row=schema[i];local value=option(row.key,row.default);local display
    if row.type=='toggle'then display=value and(en and 'On'or 'Ligada')or(en and 'Off'or 'Desligada')
    else for _,choice in ipairs(row.choices)do if choice[2]==value then display=choice[1];break end end end
    item.label=row.label;item.right=display or tostring(value)
   end
  end
  local menu=mod.ui.ListMenu.new(game,'Qol - Jo5-k',items,{onChoose=function(item,menu)
   local row;for _,r in ipairs(settings(option('language','pt-BR')))do if r.key==item.key then row=r;break end end
   local current=option(row.key,row.default);local value
   if row.type=='toggle'then value=not current else
    local index=1;for i,c in ipairs(row.choices)do if c[2]==current then index=i;break end end
    value=row.choices[index%#row.choices+1][2]
   end
   require('src.mods.ManagerState').new(game):setOption(mod.id,row.key,value);refresh(menu)
  end})
  refresh(menu);return menu
 end})
 mod.hooks:wrap('ui.start_menu.items',function(nextFn,game,rows)
  rows=nextFn(game,rows)
  if type(rows)~='table'or(Battle.isActive and Battle.isActive())then return rows end
  for _,row in ipairs(rows)do if row.id=='qol_jo5k_settings'then return rows end end
  return mod.ui.insertBefore(rows,'SAVE',{id='qol_jo5k_settings',label='QOL',onSelect=function()mod.ui.push(game,SCREEN)end})
 end)
 mod.exports.allocate=X.allocate
 mod.exports.status=function()refresh();local n=0;for _ in pairs(roots or {})do n=n+1 end;return {quickNurse=option('quick_nurse',true),experience=option('experience','native'),nurseRoots=n}end
end
