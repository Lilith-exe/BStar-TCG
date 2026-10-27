-- Pure rules: no SQL, inventory, client metadata or grading authorisation here.
BStarConditionRules = {}
local R,C = BStarConditionRules,BStarConditionConfig
local function finite(v) return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge end
local function number(v,min,max) return finite(v) and v>=min and (not max or v<=max) end
function R.validate()
    assert(number(C.daySeconds,1) and number(C.hourSeconds,1),'Condition periods must be positive')
    assert(number(C.sweepSeconds,1) and number(C.checkpointSeconds,1),'Condition scheduling must be positive')
    assert(number(C.maxBatch,1,200) and C.maxBatch%1==0,'Condition batches must be 1-200')
    local total=0
    for _,range in ipairs(C.starting) do
        assert(number(range.min,0,100) and number(range.max,range.min,100) and range.min%1==0 and range.max%1==0 and number(range.weight,1),'Invalid starting condition range')
        total=total+range.weight
    end
    assert(total==100,'Starting condition weights must total 100')
    total=0
    for _,rate in ipairs(C.daily.loose) do assert(number(rate.loss,0,100) and number(rate.weight,1),'Invalid loose daily wear');total=total+rate.weight end
    assert(total==100,'Loose wear weights must total 100')
    for _,location in ipairs({'box','binder'}) do assert(number(C.daily[location].loss,0,100) and number(C.daily[location].noWearChance,0,100),'Invalid daily wear') end
    assert(number(C.daily.protected.loss,0,100) and number(C.daily.protected.wearChance,0,100),'Invalid protected wear')
    assert(number(C.bulk.graceSeconds,0) and number(C.bulk.minLoss,0,100) and number(C.bulk.maxLoss,C.bulk.minLoss,100),'Invalid bulk wear')
    assert(number(C.duelWear,0,100),'Invalid duel wear')
    assert(number(C.public.playedMin,0,100) and number(C.public.goodMin,C.public.playedMin+1,100),'Invalid public condition thresholds')
end
R.validate()

local function weighted(entries, random)
    local total=0;for _,e in ipairs(entries) do total=total+e.weight end
    local roll=random(1,total)
    for _,e in ipairs(entries) do roll=roll-e.weight;if roll<=0 then return e end end
end
local function recordedGrade(value)
    if finite(value) then return true end
    if type(value)~='string' then return false end
    local label=value:lower():gsub('%s+','')
    return tonumber(value)~=nil or label=='gem10' or label=='destroyed'
end
function R.graded(info)
    if info.graded==true or info.slabbed==true or type(info.slab)=='table' or recordedGrade(info.grade) then return true end
    local grading=info.grading
    if type(grading)~='table' then return false end
    if grading.graded==true or recordedGrade(grading.grade) then return true end
    for _,entry in pairs(type(grading.history)=='table' and grading.history or {}) do
        if type(entry)=='table' and recordedGrade(entry.grade) then return true end
    end
    return false
end
function R.protected(info)
    local sleeve=info.sleeve
    -- Unknown historical sleeves are protected conservatively, never refunded by guessing a type.
    if sleeve==nil or sleeve==false then return false end
    if type(sleeve)=='table' and sleeve.version==1 and sleeve.type==false then return false end
    return true
end
function R.mode(info, location)
    if R.graded(info) then return 'graded' end
    if R.protected(info) then return 'protected' end
    return (location=='box' or location=='binder' or location=='pile') and location or 'loose'
end
function R.initialise(info, now, random)
    random=random or math.random
    if not finite(info.condition) and not R.graded(info) then
        local range=weighted(C.starting,random);info.condition=random(range.min,range.max)
    end
    if finite(info.condition) then info.condition=math.max(0,math.min(100,info.condition)) end
    if type(info.conditionWear)~='table' or info.conditionWear.version~=1 then
        info.conditionWear={version=1,at=now,mode=R.mode(info,'pile'),seconds={}}
    end
    return info
end
function R.mark(info,location,now)
    if not info.conditionWear then return end
    info.conditionWear.at=now;info.conditionWear.mode=R.mode(info,location);info.conditionWear.location=location
end
local function dailyLoss(mode,random)
    if mode=='protected' then return random(1,100)<=C.daily.protected.wearChance and C.daily.protected.loss or 0 end
    if mode=='box' or mode=='binder' then
        local rate=C.daily[mode];return random(1,100)<=rate.noWearChance and 0 or rate.loss
    end
    if mode=='loose' then return weighted(C.daily.loose,random).loss end
    return 0
end
function R.settle(info,location,now,onlineSeconds,random)
    random=random or math.random
    local existing=type(info.conditionWear)=='table' and info.conditionWear.version==1
    R.initialise(info,now,random)
    local clock=info.conditionWear;clock.seconds=clock.seconds or {}
    local mode=existing and clock.location==location and clock.mode or R.mode(info,location)
    if not R.graded(info) then
        local elapsed=math.max(0,now-(tonumber(clock.at) or now))
        if mode~='pile' and mode~='graded' then
            local seconds=(tonumber(clock.seconds[mode]) or 0)+elapsed
            local days=math.floor(seconds/C.daySeconds);clock.seconds[mode]=seconds%C.daySeconds
            -- Once destroyed, elapsed periods cannot revive or delete a card.
            for _=1,days do
                info.condition=math.max(0,info.condition-dailyLoss(mode,random))
                if info.condition==0 then break end
            end
        end
        if location=='pile' and not R.protected(info) then
            local grace=tonumber(info.pileGraceUntil) or ((tonumber(info.pileEnteredAt) or now)+C.bulk.graceSeconds)
            local eligible=math.max(0,math.min(tonumber(onlineSeconds) or 0,now-grace))
            clock.bulkSeconds=(tonumber(clock.bulkSeconds) or 0)+eligible
            local hours=math.floor(clock.bulkSeconds/C.hourSeconds);clock.bulkSeconds=clock.bulkSeconds%C.hourSeconds
            for _=1,hours do
                info.condition=math.max(0,info.condition-random(C.bulk.minLoss,C.bulk.maxLoss))
                if info.condition==0 then break end
            end
        end
    end
    R.mark(info,location,now);return info
end
function R.duel(info,duelId)
    R.initialise(info,os.time())
    if info.conditionLastDuel==duelId then return false end
    if not R.graded(info) and not R.protected(info) then info.condition=math.max(0,info.condition-C.duelWear) end
    info.conditionLastDuel=duelId;return true
end
function R.playable(info) return not finite(info.condition) or info.condition>0 end
function R.category(info)
    if not finite(info.condition) then return nil end
    return info.condition>=C.public.goodMin and 'Good' or info.condition>=C.public.playedMin and 'Played' or 'Damaged'
end
-- Server-only calculation. Calling this never authorises a grading station.
function R.grade(value)
    assert(finite(value) and value>=0 and value<=100,'Invalid condition')
    if value==100 then return 10,'Gem 10' end
    if value==0 then return 0,'Destroyed' end
    local grade=math.min(10,math.floor(value/10)+1)
    return grade,tostring(grade)
end
