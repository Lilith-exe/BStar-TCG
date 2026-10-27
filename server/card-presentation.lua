-- This is the only projection of private copy metadata into ordinary BStar UI.
BStarCardPresentation = {}
local P=BStarCardPresentation
function P.sleeveId(info)
    local sleeve=type(info)=='table' and info.sleeve
    return type(sleeve)=='table' and sleeve.version==1 and type(sleeve.type)=='string' and
        BStarSleeveConfig.types[sleeve.type] and sleeve.type or nil
end
function P.condition(info)
    if BStarConditionRules then return BStarConditionRules.category(info or {}) end
    local value=type(info)=='table' and info.condition
    if type(value)~='number' or value~=value or value==math.huge or value==-math.huge then return nil end
    local limits=BStarSleeveConfig.condition
    if value>=limits.goodMin then return 'Good' elseif value>=limits.playedMin then return 'Played' else return 'Damaged' end
end
function P.public(info) return {sleeveId=P.sleeveId(info),conditionCategory=P.condition(info)} end
function P.apply(card,info)
    card.sleeveId=P.sleeveId(info);card.conditionCategory=P.condition(info);return card
end
function P.inventory(info)
    local result={}
    for _,key in ipairs({'cardId','copyId','inventoryImage','label','rarity','type','effectTags','continuous','setCode','edition','image'}) do result[key]=info[key] end
    P.apply(result,info)
    -- qb-inventory honours display=false instead of dumping every metadata key.
    result.display=false
    result.description=(result.conditionCategory and (result.conditionCategory..' · ') or '')..(result.sleeveId and 'Protected card' or 'Unprotected card')
    return result
end
function P.matchesInventory(info,token,equal)
    -- Accept already-issued legacy tokens until their next journalled update;
    -- all newly written pocket tokens use the public projection.
    if equal(info,token) then return true end
    -- Display fields are derived from the current server configuration. A
    -- threshold/design update must not invalidate an otherwise valid token.
    local expected=P.inventory(info);expected.sleeveId=nil;expected.conditionCategory=nil;expected.display=nil;expected.description=nil
    local actual={};for key,value in pairs(token or {}) do if key~='sleeveId' and key~='conditionCategory' and key~='display' and key~='description' then actual[key]=value end end
    return equal(expected,actual)
end
function P.catalog()
    local types={}
    for id,t in pairs(BStarSleeveConfig.types) do
        local colour=type(t.frontColour)=='string' and t.frontColour:match('^#%x%x%x%x%x%x$') and t.frontColour or '#cbd5e1'
        local style=({clear=true,matte=true,gloss=true})[t.frontStyle] and t.frontStyle or 'clear'
        local back=t.back
        local valid=type(back)=='string' and not back:find('..',1,true) and back:match('^images/sleeves/[%w_/%-]+%.%w+$')
        if valid then
            local ext=back:match('%.(%w+)$');valid=ext=='png' or ext=='webp' or ext=='svg'
            if valid and not LoadResourceFile(GetCurrentResourceName(),'html/'..back) then valid=false end
        end
        if back=='images/assets/card_back_default.png' then valid=true end
        types[id]={id=id,label=t.label,frontColour=colour,frontStyle=style,back=valid and back or 'images/assets/card_back_default.png'}
    end
    return types
end
-- Grade calculation is server-only; no authorised station or exact-data network endpoint exists.
-- Future grading must supply an independently authorised station workflow.
BStarGrading = { enabled=false }
function BStarGrading.inspect() return nil,'Professional grading is not available; an authorised station workflow is required.' end

function P.pocketInfo(item)
    if item.info.copyId then
        local row=MySQL.single.await("SELECT * FROM bstar_card_copies WHERE id=? AND location='pocket'",{item.info.copyId})
        assert(row,'Card metadata is unavailable; recover the pending operation first')
        local info=json.decode(row.info)
        assert(P.matchesInventory(info,item.info,BStarBulk.storage.equal),'Card metadata needs recovery')
        return info
    end
    return item.info
end

function P.addVariant(card,info,amount,copyId)
    local public=P.public(info);card.variants=card.variants or {}
    for _,variant in ipairs(card.variants) do
        if variant.sleeveId==public.sleeveId and variant.conditionCategory==public.conditionCategory and variant.legacy==(not copyId) then variant.amount=variant.amount+amount;return end
    end
    public.amount=amount;public.copyId=copyId;public.legacy=not copyId;card.variants[#card.variants+1]=public
end

local publicTokenKeys={display=true,description=true,cardId=true,copyId=true,inventoryImage=true,label=true,rarity=true,type=true,effectTags=true,continuous=true,setCode=true,edition=true,image=true,sleeveId=true,conditionCategory=true}
function P.needsProjection(info)
    if type(info)=='table' and info.display~=false then return true end
    for key in pairs(info or {}) do if not publicTokenKeys[key] then return true end end
    return false
end
