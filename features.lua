-- Native entry points only. Every wrapper is scoped and reversible.
return function(mod,option)
 local Battle=require('src.core.game3.battle')
 local Runtime=require('src.core.game3.runtime')
 local Game=require('src.core.Game3')
 if Game._qolJo5kOwner then Game._qolJo5kOwner()end
 local patches,stopped={},false
 local pack=function(...)return {n=select('#',...),...}end
 local unpack=table.unpack or unpack
 local function wrap(target,key,fn)
  if type(target[key])~='function'then return end
  local original=target[key]
  local replacement=function(...)if stopped then return original(...)end;return fn(original,...)end
  target[key]=replacement;patches[#patches+1]={target,key,original,replacement}
 end
 local function safeBattle()local st=Battle.getState();return not(st and(st.link or st.oldManTutorial))end
 local function enabled(key)return safeBattle()and option(key,false)==true end
 local function session()return Runtime.getSession and Runtime.getSession()end
 local tmDepth=0
 local function tmScope(fn,...)
  tmDepth=tmDepth+1;local results=pack(pcall(fn,...));tmDepth=tmDepth-1
  if not results[1]then error(results[2],0)end;return unpack(results,2,results.n)
 end
 local Items=require('src.core.game3.items_data')
 wrap(require('src.core.game3.item_use'),'useTm',function(nextFn,...)return tmScope(nextFn,...)end)
 wrap(require('src.core.game3.battle.learn_move'),'begin',function(nextFn,opts,...)
  if tmDepth<=0 or type(opts)~='table'or type(opts.onDone)~='function'then return nextFn(opts,...)end
  local copy={};for k,v in pairs(opts)do copy[k]=v end
  copy.onDone=function(...)return tmScope(opts.onDone,...)end
  return nextFn(copy,...)
 end)
 wrap(require('src.core.game3.bag'),'remove',function(nextFn,bag,id,qty)
  if tmDepth>0 and enabled('reusable_tms')and Items.isTm(id)and not Items.isHm(id)then return true end
  return nextFn(bag,id,qty)
 end)
 local FieldMoves=require('src.core.game3.field_moves')
 local hm={CUT=true,FLY=true,SURF=true,STRENGTH=true,FLASH=true,ROCK_SMASH=true,WATERFALL=true,DIVE=true}
 mod.hooks:wrap('fieldmove.eligibility',function(nextFn,move,ctx)
  local native=nextFn(move,ctx)
  if native or not enabled('hm_without_move')or not hm[move]then return native end
  for _,mon in ipairs(ctx.party or {})do if not mon.egg and not mon.isEgg and (tonumber(mon.hp)or 0)>0 then return mon end end
 end)
 mod.hooks:wrap('script.command',function(nextFn,ctx,op,row)
  local move=FieldMoves.normalizeMoveId and FieldMoves.normalizeMoveId(row and(row.move or row[1]))
  local name=move and FieldMoves.MOVE_NAME_BY_ID[move]
  if op~='checkpartymove'or not enabled('hm_without_move')or not hm[name]then return nextFn(ctx,op,row)end
  local Space=require('src.core.game3.scripting.space');local vm=Space.getVm()
  if not vm then return nextFn(ctx,op,row)end
  local party=session()and session().party or {}
  local Flags=require('src.core.game3.scripting.flags')
  for i,mon in ipairs(party)do
   if not mon.isEgg and not mon.egg and (tonumber(mon.hp)or 0)>0 then
    Flags.setVar(vm.store,vm.ctx,0x800D,i-1);Flags.setVar(vm.store,vm.ctx,0x8004,tonumber(mon.species or mon.speciesId)or 0);return false
   end
  end
  return nextFn(ctx,op,row)
 end)
 -- Party actions needing a menu (Fly, Dive, etc.) use the same native validation
 -- and execution as collision-triggered HMs; the real moveset is never edited.
 mod.hooks:wrap('ui.party.submenu',function(nextFn,game,rows,mon,ctx)
  rows=nextFn(game,rows,mon,ctx)
  if not enabled('hm_without_move')or(ctx and ctx.battle)then return rows end
  local PartyMenu=require('src.ui.game3.party_menu');local raw=PartyMenu._party and PartyMenu._party[PartyMenu.cursor]
  if not raw or raw.isEgg or raw.egg or (tonumber(raw.hp)or 0)<=0 then return rows end
  local Space=require('src.core.game3.scripting.space')
  local existing={};for _,r in ipairs(rows or {})do if r.action then existing[r.action]=true end end
  for _,name in ipairs({'CUT','FLY','SURF','STRENGTH','FLASH','ROCK_SMASH','WATERFALL','DIVE'})do
   local action=name:gsub('_',' ')
   if not existing[action]and FieldMoves.hasBadge({store=Space.store,session=session()},name)then
    local move=mod.content.moves:get(name)
    rows[#rows+1]={label=(move and move.name)or action,onSelect=function()
     local Field=require('src.core.game3.field');local Map=require('src.core.game3.map');local Player=require('src.core.game3.player')
     local Collision=require('src.core.game3.collision');local Objects=require('src.core.game3.objects')
     local delta=({up={0,-1},down={0,1},left={-1,0},right={1,0}})[Player.facing or 'down']or {0,1}
     local fx,fy=(Player.cellX or 0)+delta[1],(Player.cellY or 0)+delta[2]
     local def=Map.currentDef();local header=def and(def.header or def)or {}
     local context={party=PartyMenu._party,mon=raw,session=PartyMenu._session or session(),store=Space.store,ctx=Space.vm and Space.vm.ctx,
      facingObject=Objects.at(fx,fy),facing=Player.facing,isFacingWater=Collision.isWater and Collision.isWater(fx,fy),
      isFacingWaterfall=FieldMoves.isWaterfallBehavior(Collision.behavior and Collision.behavior(fx,fy)),isSurfing=Player.surfing==true,
      mapType=def and def.mapType,isCave=header.cave==true,canEscapeRope=header.allowEscaping==true}
     local result=FieldMoves.fromMenu(name,context)
     if not result or not result.ok then PartyMenu.showStdMessage(result and result.text or require('src.core.game3.rom_text').plain('gText_CantUseHere'));return end
     local saved={party=PartyMenu._party,session=PartyMenu._session,slot=PartyMenu.cursor}
     PartyMenu.close();if result.action=='fly'then PartyMenu._flyReturn=saved end
     local Start=require('src.ui.game3.start_menu');if Start.isOpen and Start.isOpen()then Start.close(true)end
     Field.executeFieldMove(result)
    end}
   end
  end
  return rows
 end)
 local Help=require('src.ui.game3.help_system')
 wrap(Help,'update',function(nextFn,...)
  if enabled('disable_help')then if Help.isOpen()then Help.close()end;return false end
  return nextFn(...)
 end)
 wrap(Help,'show',function(nextFn,...)if enabled('disable_help')then return false end;return nextFn(...)end)
 wrap(require('src.core.game3.battle.catching'),'storeCaught',function(nextFn,...)
  local result=nextFn(...)
  if enabled('heal_caught')and result and result.success and result.mon then require('src.core.game3.party').healAll({result.mon})end
  return result
 end)
 mod.hooks:wrap('catch.rate',function(nextFn,ball,mon,def,ctx)
  local st=Battle.getState()
  if enabled('always_catch')and st and st.wild then return true,4 end
  return nextFn(ball,mon,def,ctx)
 end)
 mod.hooks:wrap('exp.gain',function(nextFn,ctx)
  local amount=nextFn(ctx);local mult=safeBattle()and tonumber(option('exp_multiplier',1))or 1
  return math.max(0,math.floor((tonumber(amount)or 0)*math.max(1,math.min(10,mult or 1))))
 end,100)
 local Prize=require('src.core.game3.battle.prize')
 for _,key in ipairs({'calc','calcRse'})do
  wrap(Prize,key,function(nextFn,...)
   local value=nextFn(...);local mult=safeBattle()and tonumber(option('money_multiplier',1))or 1
   return math.floor(value*math.max(1,math.min(10,mult or 1)))
  end)
 end
 local Held=require('src.core.game3.battle.held_items')
 wrap(Held,'consume',function(nextFn,ad,b)
  if enabled('infinite_held')and b and b.mon then
   local st=Battle.getState()
   for _,mon in ipairs(st and st.playerParty or {})do if mon==b.mon then return end end
  end
  return nextFn(ad,b)
 end)
 wrap(require('src.core.game3.daycare'),'step',function(nextFn,s,...)
  local count,slot=nextFn(s,...)
  if not slot and enabled('instant_eggs')then
   for i,mon in ipairs(s and s.party or {})do if (mon.isEgg or mon.egg)and not mon.isBadEgg then return count,i end end
  end
  return count,slot
 end)
 wrap(require('src.core.game3.field_view'),'flashRadius',function(nextFn,...)
  if enabled('auto_flash')then return nil end
  return nextFn(...)
 end)
 local Message=require('src.ui.game3.message')
 wrap(Message,'show',function(nextFn,text,opts,...)
  if enabled('instant_text')then
   local copy={};if type(opts)=='table'then for k,v in pairs(opts)do copy[k]=v end elseif type(opts)=='function'then copy.done=opts end
   copy.speed=0;opts=copy
  end
  return nextFn(text,opts,...)
 end)
 wrap(Message,'tick',function(nextFn,...)
  if enabled('instant_text')and Message.isTyping()and not Message.isRsFieldAutoScroll()then Message.skipReveal()end
  return nextFn(...)
 end)
 local Rs=require('src.ui.game3.rs.field_auto_scroll_message');local printer
 wrap(Rs,'open',function(nextFn,s,...)local out=nextFn(s,...);if out then printer=s end;return out end)
 wrap(Rs,'tick',function(nextFn,...)
  if not enabled('instant_text')or not printer then return nextFn(...)end
  local args=pack(...)
  for i=1,4096 do
   if printer.printer=='char_delay'then printer.delay=0 end
   nextFn(unpack(args,1,args.n))
   if not Rs.isPrinting()or printer.task<2 or printer.printer=='pause'or printer.printer:match('^wait_')then break end
  end
 end)
 local TextBox=require('src.render.TextBox')
 wrap(TextBox,'new',function(nextFn,game,text,done,opts,...)
  if enabled('instant_text')then local copy={};for k,v in pairs(type(opts)=='table'and opts or {})do copy[k]=v end;copy.noLetterDelay=true;opts=copy end
  return nextFn(game,text,done,opts,...)
 end)
 local function shutdown()
  if stopped then return end;stopped=true
  for i=#patches,1,-1 do local p=patches[i];if p[1][p[2]]==p[4]then p[1][p[2]]=p[3]end end
  patches={};printer=nil;if Game._qolJo5kOwner==shutdown then Game._qolJo5kOwner=nil end
 end
 Game._qolJo5kOwner=shutdown
 mod.hooks:wrap('core.quit_to_launcher',function(nextFn,...)shutdown();return nextFn(...)end)
 return shutdown
end
