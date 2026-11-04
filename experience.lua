-- Integer pools conserve total XP before native recipient-specific bonuses.
local X={}
function X.eligible(mon)
 return type(mon)=='table' and (tonumber(mon.species or mon.speciesId)or 0)>0 and (tonumber(mon.hp)or 0)>0
   and not mon.egg and not mon.isEgg and mon.species~=412 and (tonumber(mon.level)or 1)<100
end
function X.allocate(total,participants,eligible)
 total=math.max(0,math.floor(tonumber(total)or 0))
 local active,bench,seen={},{},{}
 for _,i in ipairs(participants or {})do seen[i]=true end
 for _,i in ipairs(eligible or {})do local list=seen[i]and active or bench;list[#list+1]=i end
 local result={}
 local function divide(pool,list)
  if #list==0 then return end
  local base=math.floor(pool/#list);local extra=pool%#list
  for n,i in ipairs(list)do result[i]=base+(n<=extra and 1 or 0)end
 end
 if #active==0 then divide(total,bench)
 elseif #bench==0 then divide(total,active)
 else local half=math.floor(total/2);divide(total-half,active);divide(half,bench)end
 return result
end
return X
