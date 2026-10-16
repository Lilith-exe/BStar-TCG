-- Printable metadata is authoritative from the generated CSV catalog.
Cards = {
    ['TOKEN_BUNNY'] = {
        id = 'TOKEN_BUNNY',
        name = 'Bunny Token',
        rarity = 'TOKEN',
        type = 'Fighter',
        job = 'Animal',
        level = 'Level 1',
        speed = '3',
        attack = '40',
        defense = '40',
        effectTitle = 'TOKEN',
        effectText = '',
        cardTags = { 'Animal', 'Token' },
        legality = '',
        setCode = '',
        edition = '',
        inventoryImage = '',
    },
    ['ALPH1_EN001_LAYLA_HART'] = {
        id = 'ALPH1_EN001_LAYLA_HART',
        name = 'Layla Hart',
        rarity = 'SECRET',
        type = 'Fighter',
        job = 'SOSMC Treasurer',
        level = 'LEVEL 2',
        speed = '3',
        attack = '40',
        defense = '90',
        effectTitle = 'MOVING FUNDS',
        effectText = 'OPD: You can pay up to 200LP, then choose one of these effects: 1) This card gains half that value in ATK. 2) This card gains half that value in HP. 3) Your opponent loses half that value in LP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN001',
        legality = '',
        inventoryImage = 'ALPH1-EN001_LAYLA_HART.png',
        cardTags = {},
        effectTags = { 'activated', 'choice_required', 'lose_lp', 'stat_modifier', 'damage_lp' },
        effects = {
        {
        trigger = 'activated',
        tags = { 'lose_lp', 'choice_required', 'stat_modifier', 'damage_lp', 'once_per_game' },
        oncePerGame = true,
        promptText = 'Pay up to 200 LP, then choose one effect.',
        form = {
        number = { key = 'paidLp', label = 'LP to pay', min = 0, max = 200, default = 200, maxLifePoints = true },
        options = {
        { id = 'gain_attack', label = 'Gain ATK', description = 'This card gains half the paid LP as ATK.' },
        { id = 'gain_hp', label = 'Gain HP', description = 'This card gains half the paid LP as HP.' },
        { id = 'damage_lp', label = 'Opponent Loses LP', description = 'Your opponent loses half the paid LP.' }
        }
        },
        options = {
        {
        id = 'gain_attack',
        actions = {
        { action = 'lose_lp', amount = { fromResponse = 'paidLp', min = 0, max = 200 } },
        { action = 'modify_stats', stats = { attack = { fromResponse = 'paidLp', multiplier = 0.5, round = 'floor' } } }
        }
        },
        {
        id = 'gain_hp',
        actions = {
        { action = 'lose_lp', amount = { fromResponse = 'paidLp', min = 0, max = 200 } },
        { action = 'modify_stats', stats = { hp = { fromResponse = 'paidLp', multiplier = 0.5, round = 'floor' } } }
        }
        },
        {
        id = 'damage_lp',
        actions = {
        { action = 'lose_lp', amount = { fromResponse = 'paidLp', min = 0, max = 200 } },
        { action = 'damage_opponent_lp', amount = { fromResponse = 'paidLp', multiplier = 0.5, round = 'floor' } }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN002_MR_BSTAR'] = {
        id = 'ALPH1_EN002_MR_BSTAR',
        name = 'Mr Bstar',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '1',
        attack = '10',
        defense = '20',
        effectTitle = 'EFFECT',
        effectText = 'When this card is summoned you can lose 300 LP and draw 2 cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN002',
        legality = 'Semi Limited',
        inventoryImage = 'ALPH1-EN002_MR_BSTAR.png',
        cardTags = {},
        effectTags = { 'on_summon', 'lose_lp', 'draw' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'lose_lp', 'draw' },
        optional = true,
        promptText = 'Do you want to lose 300 LP and draw 2 cards?',
        actions = {
        { action = 'lose_lp', target = 'self', amount = 300 },
        { action = 'draw', target = 'self', amount = 2 }
        }
        }
        },
    },
    ['ALPH1_EN003_ANASTASIA_RZEZNIK_REED'] = {
        id = 'ALPH1_EN003_ANASTASIA_RZEZNIK_REED',
        name = 'Anastasia Rzeznik-Reed',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Chief of SAFR',
        level = 'LEVEL 2',
        speed = '5',
        attack = '40',
        defense = '80',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can add 1 \'SAFR\' fighter from your deck. \'SAFR\' cards you control cannot be destroyed by card effects. This card is unaffected by burn effects.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN003',
        legality = '',
        inventoryImage = 'ALPH1-EN003_ANASTASIA_RZEZNIK-REED.png',
        cardTags = {},
        effectTags = { 'on_summon', 'search_deck', 'destroy_immunity', 'burn_immunity' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 SAFR Fighter card to add to your hand.',
        filter = { type = 'Fighter', jobContains = 'SAFR' }
        }
        }
        },
        {
        trigger = 'would_be_destroyed',
        tags = { 'protection', 'destroy_immunity' },
        condition = {
        destroyReason = 'card_effect',
        targetController = 'self',
        targetFilter = { jobContains = 'SAFR' }
        },
        actions = {
        { action = 'prevent_battle_damage' }
        }
        },
        {
        trigger = 'would_take_status_damage',
        tags = { 'protection', 'burn_immunity' },
        condition = {
        statusId = 'burn',
        targetIsSource = true
        },
        actions = {
        { action = 'prevent_status_effect' }
        }
        }
        },
    },
    ['ALPH1_EN004_WYATT_RAYNE'] = {
        id = 'ALPH1_EN004_WYATT_RAYNE',
        name = 'Wyatt Rayne',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Los Santos Customs Owner',
        level = 'LEVEL 2',
        speed = '4',
        attack = '30',
        defense = '50',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can add 1 \'Los Santos Customs\' card from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN004',
        legality = '',
        inventoryImage = 'ALPH1-EN004_WYATT_RAYNE.png',
        cardTags = {},
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = "Choose 1 Los Santos Customs card to add to your hand.",
        filter = { nameContains = "Los Santos Customs" }
        }
        }
        }
        },
    },
    ['ALPH1_EN005_XENA_COUGAR_MIRANOVA'] = {
        id = 'ALPH1_EN005_XENA_COUGAR_MIRANOVA',
        name = 'Xena "Cougar" Miranova',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'SOSMC President',
        level = 'LEVEL 1',
        speed = '3',
        attack = '30',
        defense = '50',
        effectTitle = 'COUGAR!! ah.. wait..',
        effectText = 'OPT: You can return this card to your hand and SP summon 1 \'Cougar\' from your deck. If you control \'Cougar\' you can tribute that card and SP summon this card from the hand or cemetary.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN005',
        legality = '',
        inventoryImage = 'ALPH1-EN005_XENA_COUGAR_MIRANOVA.png',
        cardTags = {},
        effectTags = { 'activated', 'return_to_hand', 'special_summon', 'tribute', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'return_to_hand', 'special_summon', 'once_per_turn' },
        oncePerTurn = true,
        oncePerTurnKey = 'xena_cougar',
        optional = true,
        promptText = 'Return Xena to your hand and special summon 1 Cougar from your deck?',
        actions = {
        {
        action = 'return_self_to_hand_and_special_summon_from_deck',
        filter = { type = 'Fighter', nameContains = 'Cougar', notCardId = 'ALPH1_EN005_XENA_COUGAR_MIRANOVA' }
        }
        }
        },
        {
        trigger = 'activated',
        activationZones = { 'hand', 'graveyard' },
        tags = { 'tribute', 'special_summon', 'once_per_turn' },
        oncePerTurn = true,
        oncePerTurnKey = 'xena_cougar',
        optional = true,
        condition = { ownControlsNameContains = 'Cougar', ownControlsNotCardId = 'ALPH1_EN005_XENA_COUGAR_MIRANOVA' },
        promptText = 'Tribute 1 Cougar you control to special summon Xena from your hand or cemetery?',
        actions = {
        {
        action = 'tribute_matching_fighter_and_special_summon_self',
        tributeFilter = { type = 'Fighter', nameContains = 'Cougar', notCardId = 'ALPH1_EN005_XENA_COUGAR_MIRANOVA' }
        }
        }
        }
        },
    },
    ['ALPH1_EN006_ANTHONY_MONTISANO'] = {
        id = 'ALPH1_EN006_ANTHONY_MONTISANO',
        name = 'Anthony Montisano',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'BCSO',
        level = 'LEVEL 1',
        speed = '2',
        attack = '30',
        defense = '40',
        effectTitle = 'STOP AND SEARCH',
        effectText = 'Your opponent must discard any \'Contraband\' cards in their hand. This effect can only be used once per game.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN006',
        legality = '',
        inventoryImage = 'ALPH1-EN006_ANTHONY_MONTISANO.png',
        cardTags = {},
        effectTags = { 'activated', 'discard', 'once_per_game' },
        effects = {
        {
        trigger = 'activated',
        tags = { 'discard', 'once_per_game' },
        oncePerGame = true,
        actions = {
        {
        action = 'discard_matching_hand',
        target = 'opponent',
        filter = { nameContains = 'Contraband' }
        }
        }
        }
        },
    },
    ['ALPH1_EN007_BROCK_LEE'] = {
        id = 'ALPH1_EN007_BROCK_LEE',
        name = 'Brock Lee',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'PDM (RIP)',
        level = 'LEVEL 2',
        speed = '3',
        attack = '20',
        defense = '30',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can equip 1 Vehicle card from your deck to a fighter on the field.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN007',
        legality = '',
        inventoryImage = 'ALPH1-EN007_BROCK_LEE.png',
        cardTags = {},
        effectTags = { 'on_summon', 'equip', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'equip', 'search_deck' },
        optional = true,
        promptText = 'Do you want to search your deck for a Vehicle card and equip it?',
        actions = {
        {
        action = 'equip_from_deck',
        choose = true,
        promptText = 'Choose 1 Vehicle card from your deck to equip.',
        filter = { type = 'Vehicle' }
        }
        }
        }
        },
    },
    ['ALPH1_EN008_ALEX_CAVEMAN_ORTIZ'] = {
        id = 'ALPH1_EN008_ALEX_CAVEMAN_ORTIZ',
        name = 'Alex "Caveman" Ortiz',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '1',
        attack = '10',
        defense = '50',
        effectTitle = 'Love the Way you Mine',
        effectText = 'While this card is the only fighter you control, it gains +50 ATK and +20 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN008',
        legality = '',
        inventoryImage = 'ALPH1-EN008_ALEX_CAVEMAN_ORTIZ.png',
        cardTags = {},
        effectTags = { 'continuous', 'stat_modifier' },
        effects = {
        {
        continuous = true,
        tags = { 'stat_modifier' },
        condition = { ownFighterCount = 1 },
        actions = {
        {
        action = 'modify_stats',
        target = 'self',
        stats = { attack = 50, hp = 20 }
        }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN009_ZOE_MIRANOVA'] = {
        id = 'ALPH1_EN009_ZOE_MIRANOVA',
        name = 'Zoe Miranova',
        rarity = 'SECRET',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '5',
        attack = '40',
        defense = '30',
        effectTitle = 'NO ZOEY, NO!',
        effectText = 'Steal your opponents shoes! All opponents fighters lose 4 SPD.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN009',
        legality = '',
        inventoryImage = 'ALPH1-EN009_ZOE_MIRANOVA.png',
        cardTags = {},
        effectTags = { 'on_summon', 'stat_modifier' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'stat_modifier' },
        actions = {
        {
        action = 'modify_stats',
        target = 'all_opponent_fighters',
        stats = { speed = -4 }
        }
        }
        }
        },
    },
    ['ALPH1_EN010_NIKOLAS_HAAJA'] = {
        id = 'ALPH1_EN010_NIKOLAS_HAAJA',
        name = 'Nikolas Haaja',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Taxi Co. owner',
        level = 'LEVEL 2',
        speed = '2',
        attack = '10',
        defense = '40',
        effectTitle = 'WHERE CAN I TAKE YA?',
        effectText = 'On summon you can add any Location card from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN010',
        legality = '',
        inventoryImage = 'ALPH1-EN010_NIKOLAS_HAAJA.png',
        cardTags = {},
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Location card to add to your hand.',
        filter = { type = 'Location' }
        }
        }
        }
        },
    },
    ['ALPH1_EN011_FINNAGEN_SKYTECH'] = {
        id = 'ALPH1_EN011_FINNAGEN_SKYTECH',
        name = 'Finnagen Skytech',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'EMS',
        level = 'LEVEL 1',
        speed = '2',
        attack = '40',
        defense = '60',
        effectTitle = 'EMT/DRIFTER',
        effectText = 'On summon, If you control 2 or more vehicle cards, add 1 \'ECG\' from your deck to your hand. If you control less than 2, you can add 1 \'bandage\' card from your deck to your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN011',
        legality = '',
        inventoryImage = 'ALPH1-EN011_FINNAGEN_SKYTECH.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN012_COUGAR'] = {
        id = 'ALPH1_EN012_COUGAR',
        name = 'Cougar',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '5',
        attack = '50',
        defense = '30',
        effectTitle = 'POACHED',
        effectText = 'If this card is killed in battle, summon 1 \'USFW\' card from your deck or hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN012',
        legality = '',
        inventoryImage = 'ALPH1-EN012_COUGAR.png',
        cardTags = { 'Animal' },
        effectTags = { 'on_destroyed_by_battle', 'special_summon' },
        effects = {
        {
        trigger = 'on_destroyed_by_battle',
        tags = { 'special_summon' },
        actions = {
        {
        action = 'special_summon_from_hand_or_deck',
        filter = { type = 'Fighter', jobContains = 'USFW' }
        }
        }
        }
        },
    },
    ['ALPH1_EN013_TOLL_BOOTH'] = {
        id = 'ALPH1_EN013_TOLL_BOOTH',
        name = 'Toll booth',
        rarity = 'SECRET',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'THIS IS BALANCED.. RIGHT?',
        effectText = 'Discard this card, each time your opponent SP summons a fighter this turn, draw 1 card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN013',
        legality = '',
        inventoryImage = 'ALPH1-EN013_TOLL_BOOTH.png',
        cardTags = {},
        effectTags = { 'activated', 'response', 'discard', 'special_summon', 'draw', 'turn_modifier' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'hand', 'itemZone' },
        tags = { 'discard', 'special_summon', 'draw', 'turn_modifier' },
        optional = true,
        promptText = 'Discard Toll Booth to draw 1 each time your opponent special summons this turn?',
        actions = {
        { action = 'destroy_card', reason = 'effect_cost', suppressResponseWindow = true, skipReplacement = true },
        { action = 'add_special_summon_draw_watcher', target = 'opponent', amount = 1 }
        }
        },
        {
        trigger = 'response',
        responseZones = { 'hand', 'itemZone' },
        tags = { 'discard', 'special_summon', 'draw', 'turn_modifier' },
        condition = {
        responseEventsAny = { 'summon', 'card_played', 'effect_activated', 'draw', 'move_card', 'equip' }
        },
        actions = {
        { action = 'destroy_card', reason = 'effect_cost', suppressResponseWindow = true, skipReplacement = true },
        { action = 'add_special_summon_draw_watcher', target = 'opponent', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN014_LAYLA_HART'] = {
        id = 'ALPH1_EN014_LAYLA_HART',
        name = 'Layla Hart',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Hardcore Comics owner',
        level = 'LEVEL 1',
        speed = '4',
        attack = '30',
        defense = '50',
        effectTitle = 'YOUR PACK IS IN THE TRAY!',
        effectText = 'You can banish this card from your cemetery to draw 3 cards, then discard 1. Your opponent also draws 1 card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN014',
        legality = '',
        inventoryImage = 'ALPH1-EN014_LAYLA_HART.png',
        cardTags = {},
        effectTags = { 'activated', 'cemetery', 'banish', 'draw', 'discard' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'graveyard' },
        tags = { 'cemetery', 'banish', 'draw', 'discard' },
        optional = true,
        promptText = 'Banish Layla from your cemetery to draw 3 cards, discard 1, and let your opponent draw 1?',
        actions = {
        { action = 'banish_self_from_graveyard' },
        { action = 'draw', target = 'self', amount = 3 },
        { action = 'select_send_matching_to_graveyard', zone = 'hand', reason = 'discard', promptText = 'Choose 1 card from your hand to discard.', filter = {} },
        { action = 'draw', target = 'opponent', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN015_ZACK_GATOR'] = {
        id = 'ALPH1_EN015_ZACK_GATOR',
        name = 'Zack Gator',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'USFW',
        level = 'LEVEL 1',
        speed = '3',
        attack = '30',
        defense = '40',
        effectTitle = 'HE PROTECC',
        effectText = 'While this card is on the field, all animal cards you control gain +40 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN015',
        legality = '',
        inventoryImage = 'ALPH1-EN015_ZACK_GATOR.png',
        cardTags = {},
        effectTags = { 'continuous', 'stat_modifier', 'animal' },
        effects = {
        {
        continuous = true,
        tags = { 'stat_modifier', 'animal' },
        actions = {
        {
        action = 'modify_stats',
        target = 'all_self_fighters',
        filter = { cardTag = 'Animal' },
        stats = { hp = 40 }
        }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN016_HAYES_TOWING'] = {
        id = 'ALPH1_EN016_HAYES_TOWING',
        name = 'Hayes Towing',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Once per turn, you can pay 50LP to take control of one of your opponents vehicle cards and equip it to a fighter of your choice. You opponent can sacrafice 1 card they control to send the vehicle back to their hand',
        edition = '1st Edition',
        setCode = 'ALPH1-EN016',
        legality = '',
        inventoryImage = 'ALPH1-EN016_HAYES_TOWING.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN017_REDEMPTION_LUNA_RAYNE'] = {
        id = 'ALPH1_EN017_REDEMPTION_LUNA_RAYNE',
        name = 'Redemption Luna Rayne',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'SOSMC',
        level = 'LEVEL 1',
        speed = '3',
        attack = '20',
        defense = '30',
        effectTitle = 'TAG TEAM',
        effectText = 'OPT on summon, if you control no other fighters, you can special summon 1 level 1 Trey Rayne from your hand or deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN017',
        legality = '',
        inventoryImage = 'ALPH1-EN017_REDEMPTION_LUNA_RAYNE.png',
        cardTags = {},
        effectTags = { 'on_summon', 'special_summon', 'once_per_turn' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'special_summon', 'once_per_turn' },
        optional = true,
        oncePerTurn = true,
        condition = { ownFighterCount = 1 },
        promptText = 'Do you want to special summon 1 Level 1 Trey Rayne from your hand or deck?',
        actions = {
        { action = 'special_summon_from_hand_or_deck', filter = { type = 'Fighter', level = 1, nameContains = 'Trey Rayne' } }
        }
        }
        },
    },
    ['ALPH1_EN018_REDEMPTION_TREY_RAYNE'] = {
        id = 'ALPH1_EN018_REDEMPTION_TREY_RAYNE',
        name = 'Redemption Trey Rayne',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'SOSMC',
        level = 'LEVEL 1',
        speed = '3',
        attack = '20',
        defense = '30',
        effectTitle = 'TAG TEAM',
        effectText = 'OPT on summon, if you control no other fighters, you can special summon 1 level 1 Luna Rayne from your hand or deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN018',
        legality = '',
        inventoryImage = 'ALPH1-EN018_REDEMPTION_TREY_RAYNE.png',
        cardTags = {},
        effectTags = { 'on_summon', 'special_summon', 'once_per_turn' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'special_summon', 'once_per_turn' },
        optional = true,
        oncePerTurn = true,
        condition = { ownFighterCount = 1 },
        promptText = 'Do you want to special summon 1 Level 1 Luna Rayne from your hand or deck?',
        actions = {
        { action = 'special_summon_from_hand_or_deck', filter = { type = 'Fighter', level = 1, nameContains = 'Luna Rayne' } }
        }
        }
        },
    },
    ['ALPH1_EN020_MAX_TURNER_MIRANOVA'] = {
        id = 'ALPH1_EN020_MAX_TURNER_MIRANOVA',
        name = 'Max Turner Miranova',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '2',
        attack = '40',
        defense = '30',
        effectTitle = 'BROTHERS',
        effectText = 'If you control \'Wyatt Rayne\', you can special summon this card from your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN020',
        legality = '',
        inventoryImage = 'ALPH1-EN020_MAX_TURNER_MIRANOVA.png',
        cardTags = {},
        effectTags = { 'activated', 'special_summon' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'hand' },
        tags = { 'special_summon' },
        optional = true,
        condition = { ownControlsNameContains = 'Wyatt Rayne' },
        promptText = 'Do you want to special summon Max Turner Miranova from your hand?',
        actions = {
        { action = 'special_summon_self_from_hand' }
        }
        }
        },
    },
    ['ALPH1_EN021_WYATT_RAYNE'] = {
        id = 'ALPH1_EN021_WYATT_RAYNE',
        name = 'Wyatt Rayne',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '2',
        attack = '30',
        defense = '40',
        effectTitle = 'BROTHERS',
        effectText = 'If you control \'Max Turner Miranova\', you can special summon this card from your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN021',
        legality = '',
        inventoryImage = 'ALPH1-EN021_WYATT_RAYNE.png',
        cardTags = {},
        effectTags = { 'activated', 'special_summon' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'hand' },
        tags = { 'special_summon' },
        optional = true,
        condition = { ownControlsNameContains = 'Max Turner Miranova' },
        promptText = 'Do you want to special summon Wyatt Rayne from your hand?',
        actions = {
        { action = 'special_summon_self_from_hand' }
        }
        }
        },
    },
    ['ALPH1_EN022_JAY_MOZZY'] = {
        id = 'ALPH1_EN022_JAY_MOZZY',
        name = 'Jay Mozzy',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Mayor of Los Santos',
        level = 'LEVEL 2',
        speed = '4',
        attack = '40',
        defense = '60',
        effectTitle = 'EFFECT',
        effectText = 'Once per turn, you can discard 1 card from your hand. If the card was a location card, you can search for 1 location or item card from your deck. If the card was a fighter card, you can search for 1 Level 2 fighter from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN022',
        legality = '',
        inventoryImage = 'ALPH1-EN022_JAY_MOZZY.png',
        cardTags = {},
        effectTags = { 'activated', 'discard', 'search_deck', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'discard', 'search_deck' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Discard 1 card to search based on its type?',
        actions = {
        {
        action = 'select_discard_hand_branch',
        promptText = 'Choose 1 card to discard. Location discards search Location/Item; Fighter discards search Level 2 Fighter.',
        branches = {
        LOCATION = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Location or Item card to add to your hand.',
        filter = { typesAny = { 'Location', 'Item' } }
        }
        },
        FIGHTER = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Level 2 Fighter to add to your hand.',
        filter = { type = 'Fighter', level = 2 }
        }
        }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN023_XENA_MIRANOVA'] = {
        id = 'ALPH1_EN023_XENA_MIRANOVA',
        name = 'Xena Miranova',
        rarity = 'SECRET',
        type = 'Fighter',
        job = 'Chief EMS',
        level = 'LEVEL 2',
        speed = '4',
        attack = '40',
        defense = '90',
        effectTitle = '5MG OF MORPHINE STAT!',
        effectText = 'Each time an item card is used, place 1 \'Healing\' token on this card. You can remove 3 \'Healing\' tokens to restore 1 fighters HP to its base value.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN023',
        legality = '',
        inventoryImage = 'ALPH1-EN023_XENA_MIRANOVA.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN024_BOBBY_FURY'] = {
        id = 'ALPH1_EN024_BOBBY_FURY',
        name = 'Bobby Fury',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Block Buds Owner',
        level = 'LEVEL 1',
        speed = '1',
        attack = '30',
        defense = '40',
        effectTitle = 'GET BAKED',
        effectText = 'Add 1 \'Doobie\' card to your hand. Also target 1 fighter on the field, reduce its SPD to 1.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN024',
        legality = '',
        inventoryImage = 'ALPH1-EN024_BOBBY_FURY.png',
        cardTags = {},
        effectTags = { 'on_summon', 'search_deck', 'stat_modifier', 'target' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck', 'stat_modifier', 'target' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Doobie card to add to your hand.',
        filter = { nameContains = 'Doobie' }
        },
        {
        action = 'select_set_stats',
        owner = 'any',
        zone = 'fighterZones',
        promptText = 'Choose 1 fighter on the field to reduce its SPD to 1.',
        filter = { type = 'Fighter' },
        stats = { speed = 1 }
        }
        }
        }
        },
    },
    ['ALPH1_EN025_BANDAGE'] = {
        id = 'ALPH1_EN025_BANDAGE',
        name = 'Bandage',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Heal 1 of your fighters for +30 HP. Also flip a coin, if tails, remove any \'bleed\' effect.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN025',
        legality = '',
        inventoryImage = 'ALPH1-EN025_BANDAGE.png',
        cardTags = {},
        effectTags = { 'on_play', 'heal', 'coin_flip', 'target', 'status' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'heal', 'target', 'status' },
        actions = {
        {
        action = 'select_heal_fighter',
        target = 'self',
        promptText = 'Choose 1 fighter to heal for 30 HP.',
        amount = 30,
        removeStatus = 'bleed',
        removeStatusOnCoin = true,
        removeStatusCoinResult = 'tails',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN026_KATANA'] = {
        id = 'ALPH1_EN026_KATANA',
        name = 'Katana',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = 'SPD +3',
        attack = 'ATK +20',
        defense = '',
        effectTitle = 'FORGED IN JAPAN',
        effectText = 'Attacks with this weapon apply \'bleed\'. Bleed: Reduce the fighters HP by 20 and SPD by 1 each turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN026',
        legality = '',
        inventoryImage = 'ALPH1-EN026_KATANA.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN027_WULFRIK_CHAOSBANE'] = {
        id = 'ALPH1_EN027_WULFRIK_CHAOSBANE',
        name = 'Wulfrik Chaosbane',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '2',
        attack = '20',
        defense = '40',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can summon up to 2 \'Crow\' cards from the deck or cemetery. You cannot attack the turn you activate this effect.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN027',
        legality = '',
        inventoryImage = 'ALPH1-EN027_WULFRIK_CHAOSBANE.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN028_CROW'] = {
        id = 'ALPH1_EN028_CROW',
        name = 'Crow',
        rarity = 'SUPER',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '6',
        attack = '10',
        defense = '10',
        effectTitle = 'CAW',
        effectText = 'Your opponent must CAW! or they lose the duel.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN028',
        legality = '',
        inventoryImage = 'ALPH1-EN028_CROW.png',
        cardTags = { 'Animal' },
        effectTags = { 'on_summon', 'caw', 'duel_loss' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'caw', 'flavor' },
        optional = true,
        promptText = 'Did your opponent CAW?',
        confirmText = 'Yes',
        cancelText = 'No',
        actions = {},
        cancelActions = {
        {
        action = 'show_duel_modal',
        target = 'self',
        title = 'Crow',
        text = 'I think we can let it slide, dont you? ;)',
        confirmText = 'Okay',
        log = false
        }
        }
        }
        },
    },
    ['ALPH1_EN029_BOB_HODGES'] = {
        id = 'ALPH1_EN029_BOB_HODGES',
        name = 'Bob Hodges',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '2',
        attack = '10',
        defense = '40',
        effectTitle = 'NORTHERN KINDA GUY',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN029',
        legality = '',
        inventoryImage = 'ALPH1-EN029_BOB_HODGES.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN030_BOB_HODGES'] = {
        id = 'ALPH1_EN030_BOB_HODGES',
        name = 'Bob Hodges',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'BCSO',
        level = 'LEVEL 2',
        speed = '2',
        attack = '30',
        defense = '80',
        effectTitle = 'BUSH IMMUNITY',
        effectText = 'If you control a \'Bobs Bush\' card, this card cannot be targeted by opponents card effects.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN030',
        legality = '',
        inventoryImage = 'ALPH1-EN030_BOB_HODGES.png',
        cardTags = {},
        effectTags = { 'continuous', 'target_immunity' },
        effects = {
        {
        trigger = 'would_be_targeted',
        tags = { 'target_immunity', 'protection' },
        condition = {
        ownControlsNameContains = 'Bob\'s Bush',
        targetIsSource = true,
        targetingPlayer = 'opponent',
        targetReason = 'card_effect'
        },
        actions = {
        { action = 'prevent_targeting' }
        }
        }
        },
    },
    ['ALPH1_EN031_YUKA_KASEN'] = {
        id = 'ALPH1_EN031_YUKA_KASEN',
        name = 'Yuka Kasen',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Diamond Casino Manager',
        level = 'LEVEL 1',
        speed = '5',
        attack = '40',
        defense = '50',
        effectTitle = 'DON\'T TEST ME',
        effectText = 'Roll a 6 sided dice, if 3 or higher, destroy 1 of your opponents cards. If you roll a 1, destroy one of your own cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN031',
        legality = '',
        inventoryImage = 'ALPH1-EN031_YUKA_KASEN.png',
        cardTags = {},
        effectTags = { 'activated', 'dice_roll', 'destroy' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'dice_roll', 'destroy' },
        optional = true,
        promptText = 'Roll a 6-sided die: 3+ lets you choose an opponent card to destroy, 1 makes you choose one of your own cards?',
        actions = {
        { action = 'roll_select_destroy_field_card', sides = 6, highThreshold = 3, highTarget = 'opponent', lowThreshold = 1, lowTarget = 'self' }
        }
        }
        },
    },
    ['ALPH1_EN032_SEN_GANBE'] = {
        id = 'ALPH1_EN032_SEN_GANBE',
        name = 'Sen Ganbe',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Casino Resort Manager',
        level = 'LEVEL 1',
        speed = '6',
        attack = '40',
        defense = '40',
        effectTitle = 'RETURN TO SENDER',
        effectText = 'When a \'Casino\' card is attacked, roll a 6 sided dice. If you roll 4 or higher, the attacker is destroyed instead.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN032',
        legality = '',
        inventoryImage = 'ALPH1-EN032_SEN_GANBE.png',
        cardTags = {},
        effectTags = { 'on_attack_declared', 'dice_roll', 'destroy', 'casino' },
        effects = {
        {
        trigger = 'on_attack_declared',
        activationZones = { 'fighterZone' },
        tags = { 'dice_roll', 'destroy', 'casino' },
        condition = {
        defendingPlayer = 'self',
        defenderFilter = { nameContains = 'Casino' }
        },
        actions = {
        { action = 'roll_destroy_attacker', sides = 6, threshold = 4 }
        }
        }
        },
    },
    ['ALPH1_EN033_HIROSHI_YAMATO'] = {
        id = 'ALPH1_EN033_HIROSHI_YAMATO',
        name = 'Hiroshi Yamato',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Casino Night Club Manager',
        level = 'LEVEL 1',
        speed = '4',
        attack = '50',
        defense = '30',
        effectTitle = 'UHH I DON\'T THINK SO!',
        effectText = 'When a \'Casino\' location, item or event card is targeted for destruction, flip a coin, if heads the card is not destroyed.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN033',
        legality = '',
        inventoryImage = 'ALPH1-EN033_HIROSHI_YAMATO.png',
        cardTags = {},
        effectTags = { 'would_be_destroyed', 'coin_flip', 'protection' },
        effects = {
        {
        trigger = 'would_be_destroyed',
        tags = { 'coin_flip', 'protection' },
        condition = {
        destroyReason = 'card_effect',
        targetController = 'self',
        targetFilter = { nameContains = 'Casino' }
        },
        actions = {
        { action = 'coin_flip_prevent_destruction', headsPrevents = true }
        }
        }
        },
    },
    ['ALPH1_EN034_HAO_YAMATO'] = {
        id = 'ALPH1_EN034_HAO_YAMATO',
        name = 'Hao Yamato',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'Diamond Casino Director',
        level = 'LEVEL 2',
        speed = '4',
        attack = '30',
        defense = '70',
        effectTitle = 'ORGANISE',
        effectText = 'Add 1 \'Casino\' card to your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN034',
        legality = '',
        inventoryImage = 'ALPH1-EN034_HAO_YAMATO.png',
        cardTags = {},
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Casino card to add to your hand.',
        filter = { nameContains = 'Casino' }
        }
        }
        }
        },
    },
    ['ALPH1_EN035_KENCH_DAWSON'] = {
        id = 'ALPH1_EN035_KENCH_DAWSON',
        name = 'Kench Dawson',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'Wizard',
        level = 'LEVEL 1',
        speed = '3',
        attack = '50',
        defense = '60',
        effectTitle = 'ABRA KADABUNNY?',
        effectText = 'If your opponent summons 3 or more fighters this turn, tribute all of their fighters for 1x L1 \'Bunny token\' with 40 ATK, 40 HP and 3 SPD. Then summon this card to your field.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN035',
        legality = '',
        inventoryImage = 'ALPH1-EN035_KENCH_DAWSON.png',
        cardTags = {},
        effectTags = { 'response', 'summon', 'token', 'tribute', 'special_summon' },
        effects = {
        {
        trigger = 'response',
        responseZones = { 'hand' },
        condition = { responseEvent = 'summon', opponentSummonsThisTurnMin = 3 },
        tags = { 'summon', 'token', 'tribute', 'special_summon' },
        actions = {
        { action = 'tribute_opponent_fighters_for_bunny_and_special_summon_self', tokenCardId = 'TOKEN_BUNNY' }
        }
        }
        },
    },
    ['ALPH1_EN036_JUSTIN_JB_BAILEY'] = {
        id = 'ALPH1_EN036_JUSTIN_JB_BAILEY',
        name = 'Justin \'JB\' Bailey',
        rarity = 'SUPER',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 2',
        speed = '8',
        attack = '40',
        defense = '70',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN036',
        legality = '',
        inventoryImage = 'ALPH1-EN036_JUSTIN_\'JB\'_BAILEY.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN037_FRANKIE_HAWTHORN'] = {
        id = 'ALPH1_EN037_FRANKIE_HAWTHORN',
        name = 'Frankie Hawthorn',
        rarity = 'SUPER',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '3',
        attack = '20',
        defense = '70',
        effectTitle = 'SCUBIE SCUBIE SCUBA',
        effectText = 'This card cannot attack or take damage from animal cards. If this card is equipped with \'Terminus\', that card gains x2 stats. Once per turn place 1 \'Coral\' counter on this card. You can remove 3 coral counters to gain +100 LP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN037',
        legality = '',
        inventoryImage = 'ALPH1-EN037_FRANKIE_HAWTHORN.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN038_KENCH_DAWSON'] = {
        id = 'ALPH1_EN038_KENCH_DAWSON',
        name = 'Kench Dawson',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Weazel News',
        level = 'LEVEL 2',
        speed = '5',
        attack = '30',
        defense = '60',
        effectTitle = 'THIS JUST IN!',
        effectText = 'Target 1 of your fighters in the cemetery. This card gains the effect of the card you targeted for this turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN038',
        legality = '',
        inventoryImage = 'ALPH1-EN038_KENCH_DAWSON.png',
        cardTags = {},
        effectTags = { 'activated', 'cemetery', 'copy_effect', 'target' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'cemetery', 'copy_effect', 'target' },
        actions = {
        { action = 'select_copy_graveyard_fighter_effects', filter = { type = 'Fighter' } }
        }
        }
        },
    },
    ['ALPH1_EN039_JAKE_HAWTHORN'] = {
        id = 'ALPH1_EN039_JAKE_HAWTHORN',
        name = 'Jake Hawthorn',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'BCSO',
        level = 'Level 2',
        speed = '2',
        attack = '50',
        defense = '40',
        effectTitle = 'CID',
        effectText = 'Discard this card, you can choose 1 card in your opponents hand at random, your opponent must reveal it.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN039',
        legality = '',
        inventoryImage = 'ALPH1-EN039_JAKE_HAWTHORN.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN040_MATT_JACKSON'] = {
        id = 'ALPH1_EN040_MATT_JACKSON',
        name = 'Matt Jackson',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Hardcore Comics',
        level = 'LEVEL 1',
        speed = '3',
        attack = '30',
        defense = '50',
        effectTitle = 'Manufacture',
        effectText = 'Discard 1 card, then search 1 \'Backpack\' card from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN040',
        legality = '',
        inventoryImage = 'ALPH1-EN040_MATT_JACKSON.png',
        cardTags = {},
        effectTags = { 'activated', 'discard', 'search_deck' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'discard', 'search_deck' },
        optional = true,
        promptText = 'Discard 1 card to search 1 Backpack card from your deck?',
        actions = {
        { action = 'discard_hand', target = 'self', amount = 1 },
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Backpack card to add to your hand.',
        filter = { nameContains = 'Backpack' }
        }
        }
        }
        },
    },
    ['ALPH1_EN041_AMNESTY'] = {
        id = 'ALPH1_EN041_AMNESTY',
        name = 'Amnesty',
        rarity = 'SUPER',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'All weapons must be destroyed by both players. Neither player takes damage to their LP this turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN041',
        legality = '',
        inventoryImage = 'ALPH1-EN041_AMNESTY.png',
        cardTags = {},
        effectTags = { 'on_play', 'destroy', 'weapon', 'prevent_lp_loss' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'destroy', 'weapon', 'prevent_lp_loss' },
        actions = {
        { action = 'destroy_all_equipment', target = 'both', filter = { type = 'Weapon' } },
        { action = 'add_player_status', target = 'self', status = 'prevent_lp_loss', name = 'LP Damage Prevented', timing = 'end_turn', turns = 1 },
        { action = 'add_player_status', target = 'opponent', status = 'prevent_lp_loss', name = 'LP Damage Prevented', timing = 'end_turn', turns = 1 }
        }
        }
        },
    },
    ['ALPH1_EN042_LEPRECHAUN_MISCHIEF_2026'] = {
        id = 'ALPH1_EN042_LEPRECHAUN_MISCHIEF_2026',
        name = 'Leprechaun Mischief 2026',
        rarity = 'SECRET',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'RESET!',
        effectText = 'Both players shuffle all cards back into the deck and redraw 4 cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN042',
        legality = '',
        inventoryImage = 'ALPH1-EN042_LEPRECHAUN_MISCHIEF_2026.png',
        cardTags = {},
        effectTags = { 'on_play', 'shuffle', 'draw' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'shuffle', 'draw' },
        actions = {
        { action = 'shuffle_all_to_deck_and_redraw', redraw = 4 }
        }
        }
        },
    },
    ['ALPH1_EN043_HEADPOP'] = {
        id = 'ALPH1_EN043_HEADPOP',
        name = 'Headpop',
        rarity = 'SUPER',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'CODE 0',
        effectText = 'Send one of your opponents fighters to the cemetery.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN043',
        legality = '',
        inventoryImage = 'ALPH1-EN043_HEADPOP.png',
        cardTags = {},
        effectTags = { 'on_play', 'destroy' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'destroy' },
        actions = {
        {
        action = 'select_destroy_field_card',
        target = 'opponent',
        zone = 'fighterZones',
        promptText = 'Choose 1 opponent fighter to send to the cemetery.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN044_MASS_HEADPOP'] = {
        id = 'ALPH1_EN044_MASS_HEADPOP',
        name = 'Mass Headpop',
        rarity = 'ULTRA',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'CODE 0',
        effectText = 'Send all fighters on the field to the cemetary.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN044',
        legality = '',
        inventoryImage = 'ALPH1-EN044_MASS_HEADPOP.png',
        cardTags = {},
        effectTags = { 'on_play', 'destroy' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'destroy' },
        actions = {
        { action = 'destroy_all_fighters', target = 'both' }
        }
        }
        },
    },
    ['ALPH1_EN045_VACATION_TO_BAHAMAS'] = {
        id = 'ALPH1_EN045_VACATION_TO_BAHAMAS',
        name = 'Vacation to Bahamas',
        rarity = 'RARE',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'BYE BYE!',
        effectText = 'Reduce your LP by -20, then target 1 of your opponents fighters and remove it from play for the rest of this game.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN045',
        legality = '',
        inventoryImage = 'ALPH1-EN045_VACATION_TO_BAHAMAS.png',
        cardTags = {},
        effectTags = { 'on_play', 'pay_lp', 'banish', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'pay_lp', 'banish', 'target' },
        costs = {
        { action = 'lose_lp', target = 'self', amount = 20 }
        },
        actions = {
        {
        action = 'select_banish_field_card',
        target = 'opponent',
        zone = 'fighterZones',
        promptText = 'Choose 1 opponent fighter to remove from play.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN046_PINK_GRAPPLE_GUN'] = {
        id = 'ALPH1_EN046_PINK_GRAPPLE_GUN',
        name = 'Pink Grapple Gun',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Yoink!',
        effectText = 'When one of your fighters is attacked, send this card to the cemetery, negate the attack and return your fighter to your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN046',
        legality = '',
        inventoryImage = 'ALPH1-EN046_PINK_GRAPPLE_GUN.png',
        cardTags = {},
        effectTags = { 'response', 'on_attack_declared', 'return_to_hand', 'negate_attack' },
        effects = {
        {
        trigger = 'response',
        responseZones = { 'hand', 'itemZone' },
        tags = { 'on_attack_declared', 'return_to_hand', 'negate_attack' },
        condition = {
        responseEvent = 'attack_declared',
        defendingPlayer = 'self',
        battleTargetType = 'fighter'
        },
        actions = {
        { action = 'destroy_card', reason = 'response_cost' },
        { action = 'return_event_defender_to_hand' }
        }
        }
        },
    },
    ['ALPH1_EN047_ECG'] = {
        id = 'ALPH1_EN047_ECG',
        name = 'ECG',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Revive',
        effectText = 'Revive one of your fighters from your cemetery.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN047',
        legality = '',
        inventoryImage = 'ALPH1-EN047_ECG.png',
        cardTags = {},
        effectTags = { 'on_play', 'revive' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'revive' },
        actions = {
        {
        action = 'select_revive_from_graveyard',
        promptText = 'Choose 1 fighter from your cemetery to revive.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN048_BLUE_METH'] = {
        id = 'ALPH1_EN048_BLUE_METH',
        name = 'Blue Meth',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Heisennburg',
        effectText = 'The equipped fighter gains +50 HP for 3 turns. On the 4th turn, its HP becomes 1.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN048',
        legality = '',
        inventoryImage = 'ALPH1-EN048_BLUE_METH.png',
        cardTags = { 'Contraband', 'drug' },
        effectTags = { 'on_play', 'stat_modifier', 'delayed_task', 'drug' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'stat_modifier', 'delayed_task', 'drug' },
        actions = {
        { action = 'modify_stats', target = 'equipped_fighter', stats = { hp = 50 } },
        {
        action = 'schedule_delayed_actions',
        turns = 3,
        timing = 'end_turn',
        label = 'Blue Meth crash',
        actions = {
        { action = 'set_hp', target = 'equipped_fighter', amount = 1 }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN049_METH'] = {
        id = 'ALPH1_EN049_METH',
        name = 'Meth',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Pinkman',
        effectText = 'The equipped fighter gains +20 HP for 2 turns. On the 3rd turn, it loses 30 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN049',
        legality = '',
        inventoryImage = 'ALPH1-EN049_METH.png',
        cardTags = { 'Contraband', 'drug' },
        effectTags = { 'on_play', 'stat_modifier', 'delayed_task', 'drug' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'stat_modifier', 'delayed_task', 'drug' },
        actions = {
        { action = 'modify_stats', target = 'equipped_fighter', stats = { hp = 20 } },
        {
        action = 'schedule_delayed_actions',
        turns = 2,
        timing = 'end_turn',
        label = 'Meth crash',
        actions = {
        { action = 'modify_stats', target = 'equipped_fighter', stats = { hp = -50 } }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN050_FENANYL'] = {
        id = 'ALPH1_EN050_FENANYL',
        name = 'Fenanyl',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'High Risk High Reward',
        effectText = 'Increase your LP by +150 for 4 turns, on the 5th turn reduce your LP to 0.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN050',
        legality = '',
        inventoryImage = 'ALPH1-EN050_FENANYL.png',
        cardTags = { 'Contraband', 'drug' },
        effectTags = { 'on_play', 'gain_lp', 'delayed_task', 'drug' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'delayed_task', 'drug' },
        actions = {
        { action = 'gain_lp', amount = 150 },
        {
        action = 'schedule_delayed_actions',
        turns = 1,
        timing = 'end_turn',
        label = 'Fenanyl LP boost turn 2',
        actions = {
        { action = 'gain_lp', amount = 150 }
        }
        },
        {
        action = 'schedule_delayed_actions',
        turns = 2,
        timing = 'end_turn',
        label = 'Fenanyl LP boost turn 3',
        actions = {
        { action = 'gain_lp', amount = 150 }
        }
        },
        {
        action = 'schedule_delayed_actions',
        turns = 3,
        timing = 'end_turn',
        label = 'Fenanyl LP boost turn 4',
        actions = {
        { action = 'gain_lp', amount = 150 }
        }
        },
        {
        action = 'schedule_delayed_actions',
        turns = 4,
        timing = 'end_turn',
        label = 'Fenanyl crash',
        actions = {
        { action = 'lose_lp', amount = 99999 }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN051_HEROINE'] = {
        id = 'ALPH1_EN051_HEROINE',
        name = 'Heroine',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Smackhead',
        effectText = 'Increase your LP by +30 for 3 turns, on the 4th turn reduce your LP by -80.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN051',
        legality = '',
        inventoryImage = 'ALPH1-EN051_HEROINE.png',
        cardTags = { 'Contraband', 'drug' },
        effectTags = { 'on_play', 'gain_lp', 'delayed_task', 'drug' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'delayed_task', 'drug' },
        actions = {
        { action = 'gain_lp', amount = 30 },
        {
        action = 'schedule_delayed_actions',
        turns = 1,
        timing = 'end_turn',
        label = 'Heroine LP boost turn 2',
        actions = {
        { action = 'gain_lp', amount = 30 }
        }
        },
        {
        action = 'schedule_delayed_actions',
        turns = 2,
        timing = 'end_turn',
        label = 'Heroine LP boost turn 3',
        actions = {
        { action = 'gain_lp', amount = 30 }
        }
        },
        {
        action = 'schedule_delayed_actions',
        turns = 3,
        timing = 'end_turn',
        label = 'Heroine crash',
        actions = {
        { action = 'lose_lp', amount = 80 }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN052_HANDCUFFS'] = {
        id = 'ALPH1_EN052_HANDCUFFS',
        name = 'Handcuffs',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Target 1 fighter your opponent controls, it cannot attack for 2 turns. If you control an \'LEO\' fighter, your opponents fighter can\'t attack for 3 turns.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN052',
        legality = '',
        inventoryImage = 'ALPH1-EN052_HANDCUFFS.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN053_TASER'] = {
        id = 'ALPH1_EN053_TASER',
        name = 'Taser',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'TASER TASER TASER!',
        effectText = 'Target 1 fighter your opponent controls, it cannot activate effects or be promoted for 2 turns.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN053',
        legality = '',
        inventoryImage = 'ALPH1-EN053_TASER.png',
        cardTags = { 'Police' },
        effectTags = { 'on_play', 'status', 'police' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'status', 'police' },
        actions = {
        {
        action = 'select_apply_status',
        target = 'opponent',
        statuses = {
        { id = 'cannot_activate', name = 'Tased', turns = 2, timing = 'end_turn' },
        { id = 'cannot_promote', name = 'No Promote', turns = 2, timing = 'end_turn' }
        },
        promptText = 'Choose 1 opponent fighter. It cannot activate effects or be promoted for 2 turns.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN054_LOCKPICK'] = {
        id = 'ALPH1_EN054_LOCKPICK',
        name = 'Lockpick',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = '*OUR* vehicle',
        effectText = 'Take control of 1 \'Vehicle\' card on your opponents field.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN054',
        legality = '',
        inventoryImage = 'ALPH1-EN054_LOCKPICK.png',
        cardTags = {},
        effectTags = { 'on_play', 'control', 'vehicle', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'control', 'vehicle', 'target' },
        actions = {
        {
        action = 'select_take_control_equipment',
        target = 'opponent',
        zone = 'field',
        title = 'Lockpick',
        chooseFighterTitle = 'Lockpick',
        chooseFighterText = 'Choose a fighter to equip the stolen vehicle to.',
        promptText = 'Choose 1 opponent Vehicle card to take control of.',
        filter = { type = 'Vehicle' },
        allowReclaim = false
        }
        }
        }
        },
    },
    ['ALPH1_EN055_MAX_SLAYTER'] = {
        id = 'ALPH1_EN055_MAX_SLAYTER',
        name = 'Max Slayter',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'Pizza This Owner',
        level = 'Level 1',
        speed = '4',
        attack = '30',
        defense = '40',
        effectTitle = 'Business relations',
        effectText = 'All \'Owner\' cards you control gain +4 SPD and +20 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN055',
        legality = '',
        inventoryImage = 'ALPH1-EN055_MAX_SLAYTER.png',
        cardTags = {},
        effectTags = { 'continuous', 'stat_modifier' },
        effects = {
        {
        continuous = true,
        tags = { 'stat_modifier' },
        actions = {
        {
        action = 'modify_stats',
        target = 'all_self_fighters',
        filter = { jobContains = 'Owner' },
        stats = { speed = 4, hp = 20 }
        }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN056_CASPER_CORTEZ'] = {
        id = 'ALPH1_EN056_CASPER_CORTEZ',
        name = 'Casper Cortez',
        rarity = 'SUPER',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '6',
        attack = '60',
        defense = '80',
        effectTitle = 'Berserk',
        effectText = 'If this card takes non-lethal damage, its ATK increases by +40 and SPD increases by +3 for 3 turns.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN056',
        legality = '',
        inventoryImage = 'ALPH1-EN056_CASPER_CORTEZ.png',
        cardTags = {},
        effectTags = { 'on_battle_damage', 'stat_modifier', 'delayed_task' },
        effects = {
        {
        trigger = 'on_battle_damage',
        tags = { 'stat_modifier', 'delayed_task' },
        condition = { sourceSurvivedBattleDamage = true },
        actions = {
        { action = 'modify_stats', stats = { attack = 40, speed = 3 } },
        {
        action = 'schedule_delayed_actions',
        turns = 3,
        timing = 'end_turn',
        label = 'Casper Cortez berserk expires',
        actions = {
        { action = 'modify_stats', stats = { attack = -40, speed = -3 } }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN057_TURBO'] = {
        id = 'ALPH1_EN057_TURBO',
        name = 'Turbo',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = 'SPD x2',
        attack = '',
        defense = '',
        effectTitle = 'STUTUTU',
        effectText = 'This card lasts for 3 turns before being destroyed.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN057',
        legality = '',
        inventoryImage = 'ALPH1-EN057_TURBO.png',
        cardTags = { 'Vehicle Upgrade' },
        effectTags = { 'on_play', 'delayed_task', 'vehicle_upgrade' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'delayed_task', 'vehicle_upgrade' },
        actions = {
        {
        action = 'schedule_delayed_actions',
        turns = 3,
        timing = 'end_turn',
        label = 'Turbo expires',
        actions = {
        { action = 'destroy_card' }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN058_TRANSMISSION_STAGE_4'] = {
        id = 'ALPH1_EN058_TRANSMISSION_STAGE_4',
        name = 'Transmission Stage 4',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Changing Gears',
        effectText = 'Target 1 \'Vehicle\' card. You can change the fighter it is equiped to.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN058',
        legality = '',
        inventoryImage = 'ALPH1-EN058_TRANSMISSION_STAGE_4.png',
        cardTags = { 'Vehicle Upgrade' },
        effectTags = { 'on_play', 'vehicle_upgrade', 'equip', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'vehicle_upgrade', 'equip', 'target' },
        optional = true,
        promptText = 'Move 1 Vehicle card you control to another fighter?',
        actions = {
        {
        action = 'select_move_equipment_to_fighter',
        target = 'self',
        zone = 'field',
        promptText = 'Choose 1 Vehicle card to move.',
        filter = { type = 'Vehicle' },
        fighterOwner = 'self'
        }
        }
        }
        },
    },
    ['ALPH1_EN059_DUMPSTER'] = {
        id = 'ALPH1_EN059_DUMPSTER',
        name = 'Dumpster',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Trash',
        effectText = 'Discard 1 random card from your opponents hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN059',
        legality = '',
        inventoryImage = 'ALPH1-EN059_DUMPSTER.png',
        cardTags = {},
        effectTags = { 'on_play', 'discard' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'discard' },
        actions = {
        { action = 'discard_hand', target = 'opponent', amount = 1, random = true }
        }
        }
        },
    },
    ['ALPH1_EN060_BACKPACK'] = {
        id = 'ALPH1_EN060_BACKPACK',
        name = 'Backpack',
        rarity = 'RARE',
        type = 'Item',
        job = 'Continuous',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Hidden Pocket',
        effectText = 'While active, your opponent cannot target cards in your hand or support zones except this card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN060',
        legality = '',
        inventoryImage = 'ALPH1-EN060_BACKPACK.png',
        cardTags = {},
        effectTags = { 'continuous', 'target_immunity', 'protection' },
        effects = {
        {
        trigger = 'would_be_targeted',
        tags = { 'target_immunity', 'protection' },
        condition = {
        targetController = 'self',
        targetingPlayer = 'opponent',
        targetReason = 'card_effect',
        targetNotSource = true,
        targetZoneAny = { 'hand', 'itemZones', 'equipmentZones', 'locationZone' }
        },
        actions = {
        { action = 'prevent_targeting' }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN061_INFERNUS_CTX_EVO'] = {
        id = 'ALPH1_EN061_INFERNUS_CTX_EVO',
        name = 'Infernus CTX EVO',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +12',
        attack = '',
        defense = '',
        effectTitle = 'Limited',
        effectText = 'You can only have 1 of this card on the field at a time.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN061',
        legality = '',
        inventoryImage = 'ALPH1-EN061_INFERNUS_CTX_EVO.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN062_INSIGHTFUL'] = {
        id = 'ALPH1_EN062_INSIGHTFUL',
        name = 'Insightful',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Draw 2 cards, then skip your next 2 draw phases.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN062',
        legality = '',
        inventoryImage = 'ALPH1-EN062_INSIGHTFUL.png',
        cardTags = {},
        effectTags = { 'on_play', 'draw', 'turn_modifier' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'draw' },
        actions = {
        { action = 'draw', target = 'self', amount = 2 },
        { action = 'skip_draw_phases', target = 'self', amount = 2 }
        }
        }
        },
    },
    ['ALPH1_EN063_HOSTAGE_DEMANDS'] = {
        id = 'ALPH1_EN063_HOSTAGE_DEMANDS',
        name = 'Hostage Demands',
        rarity = 'ULTRA',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'No Air One',
        effectText = 'Declare 1 card type, your opponent cannot use cards of that type until your next turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN063',
        legality = '',
        inventoryImage = 'ALPH1-EN063_HOSTAGE_DEMANDS.png',
        cardTags = {},
        effectTags = { 'on_play', 'lock', 'card_type' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'lock', 'card_type' },
        optional = true,
        promptText = 'Declare a card type your opponent cannot use until your next turn.',
        form = {
        options = {
        { id = 'FIGHTER', label = 'Fighter' },
        { id = 'ITEM', label = 'Item' },
        { id = 'LOCATION', label = 'Location' },
        { id = 'EVENT', label = 'Event' },
        { id = 'VEHICLE', label = 'Vehicle' },
        { id = 'WEAPON', label = 'Weapon' }
        }
        },
        options = {
        {
        id = 'FIGHTER',
        actions = {
        { action = 'add_player_status', target = 'opponent', status = 'card_type_lock', name = 'Fighter Locked', cardType = 'FIGHTER', timing = 'end_turn', turns = 1 }
        }
        },
        {
        id = 'ITEM',
        actions = {
        { action = 'add_player_status', target = 'opponent', status = 'card_type_lock', name = 'Item Locked', cardType = 'ITEM', timing = 'end_turn', turns = 1 }
        }
        },
        {
        id = 'LOCATION',
        actions = {
        { action = 'add_player_status', target = 'opponent', status = 'card_type_lock', name = 'Location Locked', cardType = 'LOCATION', timing = 'end_turn', turns = 1 }
        }
        },
        {
        id = 'EVENT',
        actions = {
        { action = 'add_player_status', target = 'opponent', status = 'card_type_lock', name = 'Event Locked', cardType = 'EVENT', timing = 'end_turn', turns = 1 }
        }
        },
        {
        id = 'VEHICLE',
        actions = {
        { action = 'add_player_status', target = 'opponent', status = 'card_type_lock', name = 'Vehicle Locked', cardType = 'VEHICLE', timing = 'end_turn', turns = 1 }
        }
        },
        {
        id = 'WEAPON',
        actions = {
        { action = 'add_player_status', target = 'opponent', status = 'card_type_lock', name = 'Weapon Locked', cardType = 'WEAPON', timing = 'end_turn', turns = 1 }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN064_CASINO_LUCKY_WHEEL'] = {
        id = 'ALPH1_EN064_CASINO_LUCKY_WHEEL',
        name = 'Casino Lucky Wheel',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = 'Cont',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Try Your Luck',
        effectText = 'Once per turn you can pay between 10 and 100 LP. Roll a 6 sided dice. If you roll a 5 or 6, gain twice the LP you paid. If you roll a 3 or 4, gain back the LP you spent on this card. If you roll 1 or 2 do nothing.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN064',
        legality = '',
        inventoryImage = 'ALPH1-EN064_CASINO_LUCKY_WHEEL.png',
        cardTags = {},
        effectTags = { 'activated', 'dice_roll', 'gain_lp', 'pay_lp', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'itemZone' },
        tags = { 'dice_roll', 'gain_lp', 'pay_lp' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Pay LP and spin Casino Lucky Wheel?',
        form = {
        number = { key = 'amount', min = 10, max = 100, default = 10, maxLifePoints = true }
        },
        costs = {
        { action = 'lose_lp', target = 'self', amount = { fromResponse = 'amount', min = 10, max = 100 } }
        },
        actions = {
        { action = 'roll_lucky_wheel', sides = 6 }
        }
        }
        },
    },
    ['ALPH1_EN065_FIREHOUSE'] = {
        id = 'ALPH1_EN065_FIREHOUSE',
        name = 'Firehouse',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'All \'SAFR\' cards you control gain +3 SPD. Also you can use any level 1 SAFR card to promote to any level 2 SAFR card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN065',
        legality = '',
        inventoryImage = 'ALPH1-EN065_FIREHOUSE.png',
        cardTags = {},
        effectTags = { 'continuous', 'stat_modifier', 'promotion_rule' },
        effects = {
        {
        continuous = true,
        tags = { 'stat_modifier' },
        actions = {
        {
        action = 'modify_stats',
        target = 'all_self_fighters',
        filter = { jobContains = 'SAFR' },
        stats = { speed = 3 }
        }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN066_LOS_SANTOS_CUSTOMS'] = {
        id = 'ALPH1_EN066_LOS_SANTOS_CUSTOMS',
        name = 'Los Santos Customs',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Performance Upgrade',
        effectText = 'Add 1 \'Vehicle Upgrade\' card to your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN066',
        legality = '',
        inventoryImage = 'ALPH1-EN066_LOS_SANTOS_CUSTOMS.png',
        cardTags = {},
        effectTags = { 'on_play', 'search_deck' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Vehicle Upgrade card to add to your hand.',
        filter = { type = 'Item', cardTag = 'Vehicle Upgrade' }
        }
        }
        }
        },
    },
    ['ALPH1_EN067_TROOPER_STATION'] = {
        id = 'ALPH1_EN067_TROOPER_STATION',
        name = 'Trooper Station',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Call for Backup',
        effectText = 'Add one \'SAST\', \'BCSO\' or \'LSPD\' item card from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN067',
        legality = '',
        inventoryImage = 'ALPH1-EN067_TROOPER_STATION.png',
        cardTags = {},
        effectTags = { 'on_play', 'search_deck' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 SAST, BCSO, or LSPD item card to add to your hand.',
        filter = { type = 'Item', cardTag = 'Police' }
        }
        }
        }
        },
    },
    ['ALPH1_EN068_BOB_S_BUSH'] = {
        id = 'ALPH1_EN068_BOB_S_BUSH',
        name = 'Bob\'s Bush',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = 'TRAP',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Sneaky',
        effectText = 'When an opponents fighter delcares an attack. Summon 1 \'Bob Hodges (BCSO)\' card from your deck. Decrease your opponents fighters SPD by -3.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN068',
        legality = '',
        inventoryImage = 'ALPH1-EN068_BOB\'S_BUSH.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN069_DRAUGUR'] = {
        id = 'ALPH1_EN069_DRAUGUR',
        name = 'Draugur',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = 'Declasse',
        level = '',
        speed = 'SPD +4',
        attack = '',
        defense = 'HP +20',
        effectTitle = 'Built to last',
        effectText = 'The first time this card would be destroyed by card effect, it is not.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN069',
        legality = '',
        inventoryImage = 'ALPH1-EN069_DRAUGUR.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN070_INVICTUS'] = {
        id = 'ALPH1_EN070_INVICTUS',
        name = 'Invictus',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = 'Canis',
        level = '',
        speed = 'SPD +3',
        attack = '',
        defense = '',
        effectTitle = 'Rapid Response',
        effectText = 'If this card is equipped to a \'SAMS\' fighter, increase SPD by another +2.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN070',
        legality = '',
        inventoryImage = 'ALPH1-EN070_INVICTUS.png',
        cardTags = {},
        effectTags = { 'continuous', 'equip', 'stat_modifier' },
        effects = {
        {
        continuous = true,
        tags = { 'equip', 'stat_modifier' },
        actions = {
        {
        action = 'modify_stats',
        target = 'equipped_fighter',
        filter = { jobContains = 'SAMS' },
        stats = { speed = 2 }
        }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN071_GREEN_PANTO'] = {
        id = 'ALPH1_EN071_GREEN_PANTO',
        name = 'Green Panto',
        rarity = 'RARE',
        type = 'Vehicle',
        job = 'Benefactor',
        level = '',
        speed = 'SPD +1',
        attack = '',
        defense = '',
        effectTitle = 'Panto-monium',
        effectText = 'When this card is sent to the cemetery, you can add 1 \'Green Panto\' card from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN071',
        legality = '',
        inventoryImage = 'ALPH1-EN071_GREEN_PANTO.png',
        cardTags = {},
        effectTags = { 'on_sent_to_cemetery', 'search_deck', 'vehicle' },
        effects = {
        {
        trigger = 'on_sent_to_cemetery',
        activationZones = { 'graveyard' },
        tags = { 'search_deck', 'vehicle' },
        optional = true,
        promptText = 'Add 1 Green Panto card from your deck to your hand?',
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Green Panto card to add to your hand.',
        filter = { type = 'Vehicle', nameContains = 'Green Panto' }
        }
        }
        }
        },
    },
    ['ALPH1_EN072_RUSTY_REBEL'] = {
        id = 'ALPH1_EN072_RUSTY_REBEL',
        name = 'Rusty Rebel',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = 'Karin',
        level = '',
        speed = 'SPD -1',
        attack = '',
        defense = '',
        effectTitle = 'Trusty Rusty',
        effectText = 'This card can be attached to any fighter card on the field.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN072',
        legality = '',
        inventoryImage = 'ALPH1-EN072_RUSTY_REBEL.png',
        cardTags = {},
        effectTags = { 'activated', 'equip', 'any_fighter', 'target' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'hand' },
        tags = { 'equip', 'any_fighter', 'target' },
        optional = true,
        promptText = 'Attach Rusty Rebel to any fighter on the field?',
        actions = {
        {
        action = 'select_attach_self_to_fighter',
        owner = 'any',
        zone = 'fighterZones',
        promptText = 'Choose any fighter on the field to equip Rusty Rebel to.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN073_RUNE'] = {
        id = 'ALPH1_EN073_RUNE',
        name = 'Rune',
        rarity = 'RARE',
        type = 'Vehicle',
        job = 'Cheburek',
        level = '',
        speed = 'SPD -2',
        attack = '',
        defense = '',
        effectTitle = 'Carboard Kit?',
        effectText = 'After this card has been equipped your fighter for 2 turns, you can target 1 of your opponents fighters, it is now equipped by this card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN073',
        legality = '',
        inventoryImage = 'ALPH1-EN073_RUNE.png',
        cardTags = {},
        effectTags = { 'on_play', 'equip', 'delayed_task', 'target', 'control' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'equip', 'delayed_task' },
        actions = {
        {
        action = 'schedule_delayed_actions',
        turns = 2,
        timing = 'end_turn',
        label = 'Cheburek Rune transfer becomes available',
        actions = {
        {
        action = 'select_attach_self_to_fighter',
        owner = 'opponent',
        zone = 'fighterZones',
        optional = true,
        promptText = 'Move Cheburek Rune to an opponent fighter?',
        filter = { type = 'Fighter' }
        }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN074_CERAMIC_PISTOL'] = {
        id = 'ALPH1_EN074_CERAMIC_PISTOL',
        name = 'Ceramic Pistol',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +30',
        defense = '',
        effectTitle = 'Concealment',
        effectText = 'This card is concealed to any card which destroys \'Contraband\' cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN074',
        legality = '',
        inventoryImage = 'ALPH1-EN074_CERAMIC_PISTOL.png',
        cardTags = { 'Contraband' },
        effectTags = { 'equip', 'stat_modifier', 'protection', 'contraband' },
        effects = {
        {
        trigger = 'would_be_destroyed',
        tags = { 'protection', 'contraband' },
        condition = {
        destroyReason = 'card_effect',
        targetIsSource = true,
        sourceEffectTextContains = 'Contraband'
        },
        actions = {
        { action = 'prevent_destruction' }
        }
        }
        },
    },
    ['ALPH1_EN075_HUNTING_RIFLE'] = {
        id = 'ALPH1_EN075_HUNTING_RIFLE',
        name = 'Hunting Rifle',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +20',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'This card is only effective against \'Animal\' cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN075',
        legality = '',
        inventoryImage = 'ALPH1-EN075_HUNTING_RIFLE.png',
        cardTags = {},
        effectTags = { 'equip', 'stat_modifier', 'animal' },
        effects = {
        {
        continuous = true,
        tags = { 'weapon', 'animal', 'battle_modifier' },
        actions = {}
        }
        },
    },
    ['ALPH1_EN076_FLAMETHROWER'] = {
        id = 'ALPH1_EN076_FLAMETHROWER',
        name = 'Flamethrower',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +10',
        defense = '',
        effectTitle = 'We Didn\'t Start the Fire!',
        effectText = 'If the equipped fighter attacks your opponents fighter, apply burn. Burn: reduce the fighters HP by 15 each turn. If the equipped card attacks directly, apply burn to your opponents LP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN076',
        legality = '',
        inventoryImage = 'ALPH1-EN076_FLAMETHROWER.png',
        cardTags = { 'Contraband' },
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN077_TECH_9'] = {
        id = 'ALPH1_EN077_TECH_9',
        name = 'Tech 9',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = 'SPD +2',
        attack = 'ATK +30',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'A leathal compact weapon with blazing fire rate!',
        edition = '1st Edition',
        setCode = 'ALPH1-EN077',
        legality = '',
        inventoryImage = 'ALPH1-EN077_TECH_9.png',
        cardTags = { 'Contraband' },
        effectTags = { 'equip', 'stat_modifier', 'contraband' },
        effects = {
        {
        continuous = true,
        tags = { 'weapon', 'stat_modifier', 'contraband' },
        actions = {}
        }
        },
    },
    ['ALPH1_EN078_BRADLEY_BK_KRAY'] = {
        id = 'ALPH1_EN078_BRADLEY_BK_KRAY',
        name = 'Bradley \'BK\' Kray',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Triad',
        level = 'Level 2',
        speed = '8',
        attack = '70',
        defense = '100',
        effectTitle = 'RATATATATA',
        effectText = 'If this card is equipped with an \'SMG\' or \'PDW\', it can make 2 attacks this battle phase.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN078',
        legality = '',
        inventoryImage = 'ALPH1-EN078_BRADLEY_\'BK\'_KRAY.png',
        cardTags = {},
        effectTags = { 'continuous', 'extra_attack', 'weapon' },
        effects = {
        {
        continuous = true,
        tags = { 'extra_attack', 'weapon' },
        condition = { equippedNameContainsAny = { 'SMG', 'PDW' } },
        actions = {
        { action = 'grant_extra_attacks', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN079_KIN_RODINE'] = {
        id = 'ALPH1_EN079_KIN_RODINE',
        name = 'Kin Rodine',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Bstar Fitness',
        level = 'Level 2',
        speed = '7',
        attack = '60',
        defense = '80',
        effectTitle = 'MMA Master',
        effectText = 'Boost another fighters ATK and SPD by x2 for 2 turns.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN079',
        legality = '',
        inventoryImage = 'ALPH1-EN079_KIN_RODINE.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN080_JAMIE_THOMAS'] = {
        id = 'ALPH1_EN080_JAMIE_THOMAS',
        name = 'Jamie Thomas',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '6',
        attack = '40',
        defense = '60',
        effectTitle = 'EFFECT',
        effectText = 'On summon: Target 2 location or item cards in your cemetary. Shuffle 1 back into your deck and add the other to your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN080',
        legality = '',
        inventoryImage = 'ALPH1-EN080_JAMIE_THOMAS.png',
        cardTags = {},
        effectTags = { 'on_summon', 'cemetery', 'shuffle', 'add_to_hand', 'multi_select' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'cemetery', 'shuffle', 'add_to_hand', 'multi_select' },
        optional = true,
        promptText = 'Choose 2 Location/Item cards in your cemetery; first selected goes to deck, second to hand?',
        actions = {
        {
        action = 'select_graveyard_split_deck_hand',
        minChoices = 2,
        maxChoices = 2,
        promptText = 'Choose exactly 2 Location/Item cards. First selected shuffles into deck; second selected goes to hand.',
        filter = { typesAny = { 'Location', 'Item' } }
        }
        }
        }
        },
    },
    ['ALPH1_EN081_CLYDE_RILEY_SR'] = {
        id = 'ALPH1_EN081_CLYDE_RILEY_SR',
        name = 'Clyde Riley Sr.',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Chief of SAMS',
        level = 'Level 1',
        speed = '4',
        attack = '30',
        defense = '70',
        effectTitle = 'Staff Roster',
        effectText = 'Shuffle up to 3 of your fighters from the cemetery back into your deck, then draw 1 card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN081',
        legality = '',
        inventoryImage = 'ALPH1-EN081_CLYDE_RILEY_SR..png',
        cardTags = { 'SAMS', 'SAFR', 'EMS' },
        effectTags = { 'on_summon', 'cemetery', 'shuffle', 'draw', 'multi_select' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'cemetery', 'shuffle', 'draw' },
        optional = true,
        promptText = 'Shuffle up to 3 fighters from your cemetery into your deck, then draw 1?',
        actions = {
        {
        action = 'select_graveyard_to_deck',
        minChoices = 0,
        maxChoices = 3,
        thenDraw = 1,
        promptText = 'Choose up to 3 fighters from your cemetery to shuffle into your deck.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN082_WILLIAM_TAZENTINE'] = {
        id = 'ALPH1_EN082_WILLIAM_TAZENTINE',
        name = 'William Tazentine',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '3',
        attack = '10',
        defense = '30',
        effectTitle = 'Business Tax',
        effectText = 'On summon: Gain 20 LP for all location cards in your hand, cemetary and on the field. After 3 turns banish this card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN082',
        legality = '',
        inventoryImage = 'ALPH1-EN082_WILLIAM_TAZENTINE.png',
        cardTags = {},
        effectTags = { 'on_summon', 'gain_lp', 'location', 'delayed_banish' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'gain_lp', 'location' },
        actions = {
        {
        action = 'gain_lp_per_matching_card',
        amountPerCard = 20,
        zones = { 'hand', 'graveyard', 'field' },
        filter = { type = 'Location' }
        },
        {
        action = 'schedule_delayed_actions',
        turns = 3,
        timing = 'start_turn',
        label = 'William Tazentine self-banish',
        actions = {
        { action = 'banish_card' }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN083_RADIO'] = {
        id = 'ALPH1_EN083_RADIO',
        name = 'Radio',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'NEED BACKUP!',
        effectText = 'If a fighter you control is sent to the cemetary, add 1 fighter from the same group/job as the one destroyed.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN083',
        legality = '',
        inventoryImage = 'ALPH1-EN083_RADIO.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN084_INDIGO_CLEMONTINE'] = {
        id = 'ALPH1_EN084_INDIGO_CLEMONTINE',
        name = 'Indigo Clemontine',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 2',
        speed = '7',
        attack = '30',
        defense = '60',
        effectTitle = 'All things balanced',
        effectText = 'If your LP is lower than your opponents, this cards ATK becomes equal to half of the difference (rounded up) until the end of your opponents next turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN084',
        legality = '',
        inventoryImage = 'ALPH1-EN084_INDIGO_CLEMONTINE.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN085_VEHICLE_ARMOUR'] = {
        id = 'ALPH1_EN085_VEHICLE_ARMOUR',
        name = 'Vehicle Armour',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = 'Level 1',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'While this card is on the field, any damage you take is halved. Also fighters you control with an equipped vehicle, cannot be attacked.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN085',
        legality = '',
        inventoryImage = 'ALPH1-EN085_VEHICLE_ARMOUR.png',
        cardTags = { 'Vehicle Upgrade' },
        effectTags = { 'continuous', 'prevent_lp_loss', 'vehicle_upgrade', 'attack_protection' },
        effects = {
        {
        trigger = 'would_lose_lp',
        tags = { 'prevent_lp_loss', 'vehicle_upgrade' },
        condition = { targetController = 'self' },
        actions = {
        { action = 'halve_lp_loss' }
        }
        }
        },
        continuous = true,
    },
    ['ALPH1_EN086_TRIAD_COMPOUND'] = {
        id = 'ALPH1_EN086_TRIAD_COMPOUND',
        name = 'Triad compound',
        rarity = 'SUPER',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Shaolin Temple',
        effectText = 'Once per turn you can summon up to two level 2 or lower \'Triad\' fighters. Upon activation, all opponents fighters lose -20 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN086',
        legality = '',
        inventoryImage = 'ALPH1-EN086_TRIAD_COMPOUND.png',
        cardTags = {},
        effectTags = { 'activated', 'special_summon', 'triad', 'stat_modifier', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'locationZone' },
        tags = { 'special_summon', 'triad', 'stat_modifier' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Special summon up to two Level 2 or lower Triad fighters, then damage all opponent fighters?',
        actions = {
        { action = 'special_summon_from_hand_or_deck', filter = { type = 'Fighter', jobContains = 'Triad', levelMax = 2 } },
        { action = 'special_summon_from_hand_or_deck', filter = { type = 'Fighter', jobContains = 'Triad', levelMax = 2 } },
        { action = 'modify_stats', target = 'all_opponent_fighters', stats = { hp = -20 } }
        }
        }
        },
    },
    ['ALPH1_EN087_TAYLOR_BANDIT'] = {
        id = 'ALPH1_EN087_TAYLOR_BANDIT',
        name = 'Taylor Bandit',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Dynasty 8',
        level = 'Level 1',
        speed = '4',
        attack = '50',
        defense = '60',
        effectTitle = 'Any D8 Around?',
        effectText = 'Pay 30 LP. Search your deck for 1 \'location\' card. You can then destroy 1 of your opponents \'location\' cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN087',
        legality = '',
        inventoryImage = 'ALPH1-EN087_TAYLOR_BANDIT.png',
        cardTags = {},
        effectTags = { 'activated', 'pay_lp', 'search_deck', 'destroy', 'location' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'pay_lp', 'search_deck', 'destroy', 'location' },
        optional = true,
        promptText = 'Pay 30 LP to search a Location, then destroy an opponent Location?',
        costs = {
        { action = 'lose_lp', target = 'self', amount = 30 }
        },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Location card to add to your hand.',
        filter = { type = 'Location' }
        },
        {
        action = 'select_destroy_field_card',
        target = 'opponent',
        zone = 'field',
        promptText = 'Choose 1 opponent Location card to destroy.',
        filter = { type = 'Location' }
        }
        }
        }
        },
    },
    ['ALPH1_EN088_PALETO_PAWN'] = {
        id = 'ALPH1_EN088_PALETO_PAWN',
        name = 'Paleto Pawn',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'FOOOOOR DE BUSINESS',
        effectText = 'OPT: You can send 1 card from the top of you deck to the cemetery. Then you can add 1 card of a different type from your cemetery to the top of your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN088',
        legality = '',
        inventoryImage = 'ALPH1-EN088_PALETO_PAWN.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN089_MIKE_LAW'] = {
        id = 'ALPH1_EN089_MIKE_LAW',
        name = 'Mike Law',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'LSPD Chief',
        level = 'Level 2',
        speed = '6',
        attack = '70',
        defense = '100',
        effectTitle = 'Switching Tactics',
        effectText = 'Once per turn you can switch the ATK and HP of this card. You cannot attack the turn you activate this effect.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN089',
        legality = '',
        inventoryImage = 'ALPH1-EN089_MIKE_LAW.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN090_LOTTO'] = {
        id = 'ALPH1_EN090_LOTTO',
        name = 'Lotto!',
        rarity = 'COMMON',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Lotto!',
        effectText = 'Roll a 100 sided dice. If you roll 90 or above, gain +200 LP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN090',
        legality = '',
        inventoryImage = 'ALPH1-EN090_LOTTO!.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN091_DAMIEN_GRAVES'] = {
        id = 'ALPH1_EN091_DAMIEN_GRAVES',
        name = 'Damien Graves',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Larry\'s Car Lot',
        level = 'Level 1',
        speed = '3',
        attack = '30',
        defense = '40',
        effectTitle = '*Slaps Roof of Car*',
        effectText = 'You can discard 1 \'Larrys Car Lot\' from your hand. This card gains that effect for 3 turns. "If you draw a \'Vehicle\' card. You can draw 1 more card."',
        edition = '1st Edition',
        setCode = 'ALPH1-EN091',
        legality = '',
        inventoryImage = 'ALPH1-EN091_DAMIEN_GRAVES.png',
        cardTags = {},
        effectTags = { 'activated', 'discard', 'draw', 'vehicle', 'duration' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'discard', 'draw', 'vehicle', 'duration' },
        actions = {
        {
        action = 'discard_named_hand_card_then_watch_drawn_type',
        discardFilter = { type = 'Location', nameContainsAny = { 'Larrys Car Lot', 'Colemans Car Lot' } },
        cardType = 'Vehicle',
        amount = 1,
        turns = 3
        }
        }
        }
        },
    },
    ['ALPH1_EN092_LARRY_S_CAR_LOT'] = {
        id = 'ALPH1_EN092_LARRY_S_CAR_LOT',
        name = 'Larry\'s Car Lot',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'TRADE DE CAH',
        effectText = 'If you draw a \'Vehicle\' card. You can draw 1 more card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN092',
        legality = '',
        inventoryImage = 'ALPH1-EN092_LARRY\'S_CAR_LOT.png',
        cardTags = {},
        effectTags = { 'on_draw', 'draw', 'vehicle' },
        effects = {
        {
        trigger = 'on_draw',
        tags = { 'draw', 'vehicle' },
        optional = true,
        promptText = 'You drew a Vehicle. Draw 1 more card?',
        condition = { drawnType = 'Vehicle' },
        actions = {
        { action = 'draw', target = 'self', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN093_REX_S_DINER'] = {
        id = 'ALPH1_EN093_REX_S_DINER',
        name = 'Rex\'s Diner',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'OPT: You can heal each of your fighters for +15 HP. If you control a BCSO fighter, this healing is doubled.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN093',
        legality = '',
        inventoryImage = 'ALPH1-EN093_REX\'S_DINER.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN094_KENZIE_HALL'] = {
        id = 'ALPH1_EN094_KENZIE_HALL',
        name = 'Kenzie Hall',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'level 1',
        speed = '4',
        attack = '30',
        defense = '40',
        effectTitle = 'THATS MY HUSBAND.',
        effectText = 'If an \'Alan Hall\' fighter you control is destroyed by battle, inflict damage to your opponent equal to the attacking fighters attack.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN094',
        legality = '',
        inventoryImage = 'ALPH1-EN094_KENZIE_HALL.png',
        cardTags = {},
        effectTags = { 'on_friendly_destroyed_by_battle', 'damage_lp' },
        effects = {
        {
        trigger = 'on_friendly_destroyed_by_battle',
        tags = { 'damage_lp' },
        condition = { eventDestroyedNameContains = 'Alan Hall' },
        actions = {
        { action = 'damage_opponent_equal_attacker_attack' }
        }
        }
        },
    },
    ['ALPH1_EN095_CHADWICK_SLAMMER'] = {
        id = 'ALPH1_EN095_CHADWICK_SLAMMER',
        name = 'Chadwick Slammer',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'FIB',
        level = 'Level 1',
        speed = '3',
        attack = '20',
        defense = '40',
        effectTitle = 'Slammer Special',
        effectText = 'Pay half your LP. Destroy all fighters your opponent controls. Then discard all \'FIB\' cards from your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN095',
        legality = '',
        inventoryImage = 'ALPH1-EN095_CHADWICK_SLAMMER.png',
        cardTags = {},
        effectTags = { 'activated', 'pay_lp', 'destroy', 'discard' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'pay_lp', 'destroy', 'discard' },
        optional = true,
        promptText = 'Pay half your LP to destroy all opponent fighters, then discard all FIB cards from your hand?',
        costs = {
        { action = 'pay_half_lp', target = 'self' }
        },
        actions = {
        { action = 'destroy_all_fighters', target = 'opponent' },
        { action = 'discard_matching_hand', target = 'self', filter = { jobContains = 'FIB' } }
        }
        }
        },
    },
    ['ALPH1_EN096_XAVIER_WU'] = {
        id = 'ALPH1_EN096_XAVIER_WU',
        name = 'Xavier Wu',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Triad',
        level = 'Level 2',
        speed = '6',
        attack = '60',
        defense = '100',
        effectTitle = 'Arsenal',
        effectText = 'If you control 3 or more weapon cards, all fighters you control cannot be targeted by card effects.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN096',
        legality = '',
        inventoryImage = 'ALPH1-EN096_XAVIER_WU.png',
        cardTags = {},
        effectTags = { 'continuous', 'target_immunity', 'weapon' },
        effects = {
        {
        trigger = 'would_be_targeted',
        tags = { 'target_immunity', 'protection', 'weapon' },
        condition = {
        ownEquipmentTypeCountMin = 3,
        equipmentType = 'Weapon',
        targetController = 'self',
        targetFilter = { type = 'Fighter' },
        targetingPlayer = 'opponent',
        targetReason = 'card_effect'
        },
        actions = {
        { action = 'prevent_targeting' }
        }
        }
        },
    },
    ['ALPH1_EN097_LOGAN_BANDIT_DAWSON'] = {
        id = 'ALPH1_EN097_LOGAN_BANDIT_DAWSON',
        name = 'Logan Bandit Dawson',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Triad',
        level = 'Level 2',
        speed = '5',
        attack = '50',
        defense = '110',
        effectTitle = 'Kaboom',
        effectText = 'Once per turn you can place 1 \'Sticky Bomb\' counter on one of your opponents fighters. You can remove all \'sticky bomb\' counters from all cards, dealing -30HP for each counter. You cannot detonate sticky bombs the turn you place them.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN097',
        legality = '',
        inventoryImage = 'ALPH1-EN097_LOGAN_BANDIT_DAWSON.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN098_KITT_REED_WU'] = {
        id = 'ALPH1_EN098_KITT_REED_WU',
        name = 'Kitt Reed Wu',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Triad',
        level = 'Level 2',
        speed = '8',
        attack = '80',
        defense = '90',
        effectTitle = 'Duck and Weave',
        effectText = 'Each time one of your fighters dodges an attack, draw 1 card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN098',
        legality = '',
        inventoryImage = 'ALPH1-EN098_KITT_REED_WU.png',
        cardTags = {},
        effectTags = { 'on_dodge', 'draw' },
        effects = {
        {
        trigger = 'on_dodge',
        tags = { 'draw' },
        condition = { defendingPlayer = 'self' },
        actions = {
        { action = 'draw', target = 'self', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN099_SPARTAN_ARSENAL'] = {
        id = 'ALPH1_EN099_SPARTAN_ARSENAL',
        name = 'Spartan Arsenal',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If you draw a \'weapon\' card, you can draw 1 more card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN099',
        legality = '',
        inventoryImage = 'ALPH1-EN099_SPARTAN_ARSENAL.png',
        cardTags = {},
        effectTags = { 'on_draw', 'draw', 'weapon' },
        effects = {
        {
        trigger = 'on_draw',
        tags = { 'draw', 'weapon' },
        optional = true,
        promptText = 'You drew a Weapon. Draw 1 more card?',
        condition = { drawnType = 'Weapon' },
        actions = {
        { action = 'draw', target = 'self', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN100_GUN_BENCH'] = {
        id = 'ALPH1_EN100_GUN_BENCH',
        name = 'Gun Bench',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'You can discard this card from your hand. For the rest of this turn, every time your opponent plays a weapon card, draw 1 card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN100',
        legality = '',
        inventoryImage = 'ALPH1-EN100_GUN_BENCH.png',
        cardTags = {},
        effectTags = { 'activated', 'discard', 'draw', 'weapon' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'hand' },
        tags = { 'discard', 'draw', 'weapon' },
        optional = true,
        promptText = 'Discard Gun Bench to draw whenever your opponent plays a Weapon this turn?',
        actions = {
        { action = 'destroy_card', reason = 'card_effect' },
        { action = 'add_played_type_draw_watcher', target = 'opponent', cardType = 'Weapon', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN101_MARINE_BEACH_RECYCLING'] = {
        id = 'ALPH1_EN101_MARINE_BEACH_RECYCLING',
        name = 'Marine Beach Recycling',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Recycle',
        effectText = 'Once per turn, you can discard any number of item cards, draw that many cards from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN101',
        legality = '',
        inventoryImage = 'ALPH1-EN101_MARINE_BEACH_RECYCLING.png',
        cardTags = {},
        effectTags = { 'activated', 'discard', 'draw', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'locationZone' },
        tags = { 'discard', 'draw' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Discard any number of Item cards to draw that many cards?',
        actions = {
        {
        action = 'select_send_matching_to_graveyard',
        zone = 'hand_and_field',
        minChoices = 1,
        maxChoices = 10,
        thenDrawPerCard = 1,
        reason = 'discard',
        promptText = 'Choose Item cards to discard.',
        filter = { type = 'Item' }
        }
        }
        }
        },
    },
    ['ALPH1_EN102_AMMO_SOUTH'] = {
        id = 'ALPH1_EN102_AMMO_SOUTH',
        name = 'Ammo South',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Once per turn you can return any \'weapon\' card to your hand, then add 1 \'weapon\' card from your cemetary to your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN102',
        legality = '',
        inventoryImage = 'ALPH1-EN102_AMMO_SOUTH.png',
        cardTags = {},
        effectTags = { 'activated', 'weapon', 'return_to_hand', 'cemetery', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'locationZone' },
        tags = { 'weapon', 'return_to_hand', 'cemetery' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Return a Weapon you control to hand, then add a Weapon from your cemetery to hand?',
        actions = {
        {
        action = 'select_return_field_to_hand',
        owner = 'self',
        zone = 'field',
        promptText = 'Choose 1 Weapon you control to return to hand.',
        filter = { type = 'Weapon' }
        },
        {
        action = 'select_graveyard_to_hand',
        owner = 'self',
        promptText = 'Choose 1 Weapon from your cemetery to add to hand.',
        filter = { type = 'Weapon' }
        }
        }
        }
        },
    },
    ['ALPH1_EN103_SMG'] = {
        id = 'ALPH1_EN103_SMG',
        name = 'SMG',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +20',
        defense = '',
        effectTitle = 'Dual Wield',
        effectText = 'You can equip up to 2 copies of \'SMG\' to any fighter.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN103',
        legality = '',
        inventoryImage = 'ALPH1-EN103_SMG.png',
        cardTags = { 'Contraband' },
        maxCopiesPerFighter = 2,
        effectTags = { 'continuous', 'weapon', 'equip_restriction' },
        effects = {
        {
        continuous = true,
        tags = { 'weapon', 'equip_restriction' },
        actions = {}
        }
        },
    },
    ['ALPH1_EN104_COMBAT_PDW'] = {
        id = 'ALPH1_EN104_COMBAT_PDW',
        name = 'Combat PDW',
        rarity = 'SUPER',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +30',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'The equipped fighter can attack 2 opponents fighters per turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN104',
        legality = '',
        inventoryImage = 'ALPH1-EN104_COMBAT_PDW.png',
        cardTags = { 'Contraband' },
        effectTags = { 'continuous', 'extra_attack', 'weapon' },
        effects = {
        {
        continuous = true,
        tags = { 'extra_attack', 'weapon' },
        actions = {
        { action = 'grant_extra_attacks', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN105_PFISTER_COMET_CTX'] = {
        id = 'ALPH1_EN105_PFISTER_COMET_CTX',
        name = 'Pfister Comet CTX',
        rarity = 'SUPER',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +10',
        attack = '',
        defense = '',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN105',
        legality = '',
        inventoryImage = 'ALPH1-EN105_PFISTER_COMET_CTX.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN106_SPIKE_STRIP'] = {
        id = 'ALPH1_EN106_SPIKE_STRIP',
        name = 'Spike Strip',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Kill all Tyres!',
        effectText = 'Destroy all of your opponents \'vehicle\' cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN106',
        legality = '',
        inventoryImage = 'ALPH1-EN106_SPIKE_STRIP.png',
        cardTags = { 'Police' },
        effectTags = { 'on_play', 'destroy', 'vehicle' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'destroy', 'vehicle' },
        actions = {
        { action = 'destroy_all_equipment', target = 'opponent', filter = { type = 'Vehicle' } }
        }
        }
        },
    },
    ['ALPH1_EN107_FUEL_SHORTAGE'] = {
        id = 'ALPH1_EN107_FUEL_SHORTAGE',
        name = 'Fuel Shortage',
        rarity = 'RARE',
        type = 'Continuous Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'All opponents vehicles lose half of their SPD. You must pay 20 LP each turn to keep this card active.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN107',
        legality = '',
        inventoryImage = 'ALPH1-EN107_FUEL_SHORTAGE.png',
        cardTags = {},
        continuous = true,
        effectTags = { 'continuous', 'vehicle', 'stat_modifier', 'upkeep', 'lose_lp' },
        effects = {
        {
        continuous = true,
        tags = { 'vehicle', 'stat_modifier' },
        actions = {
        { action = 'modify_stats', target = 'opponent_equipment', filter = { type = 'Vehicle' }, statMultipliers = { speed = -0.5 } }
        }
        },
        {
        trigger = 'main_phase_start',
        condition = { phase = 'main' },
        tags = { 'upkeep', 'lose_lp' },
        actions = {
        { action = 'lose_lp', target = 'self', amount = 20 }
        }
        }
        },
    },
    ['ALPH1_EN108_HOUSE_ROBBERY'] = {
        id = 'ALPH1_EN108_HOUSE_ROBBERY',
        name = 'House robbery',
        rarity = 'SUPER',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = '5 FINGER DISCOUNT',
        effectText = 'Take control of 2 of your opponents \'item\', \'weapon\', or \'vehicle\' cards.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN108',
        legality = '',
        inventoryImage = 'ALPH1-EN108_HOUSE_ROBBERY.png',
        cardTags = {},
        effectTags = { 'on_play', 'take_control', 'item', 'weapon', 'vehicle', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'take_control', 'item', 'weapon', 'vehicle', 'target' },
        actions = {
        {
        action = 'select_take_control_field_cards',
        minChoices = 1,
        maxChoices = 2,
        filter = { typesAny = { 'Item', 'Weapon', 'Vehicle' } },
        promptText = 'Choose up to 2 opponent Item, Weapon, or Vehicle cards to take control of.'
        }
        }
        }
        },
    },
    ['ALPH1_EN109_PALETO_HEIST'] = {
        id = 'ALPH1_EN109_PALETO_HEIST',
        name = 'Paleto Heist',
        rarity = 'COMMON',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'This card cannot be played unless by the effect of \'Bank Card\'. Gain +300 LP and draw until you have 4 cards in your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN109',
        legality = '',
        inventoryImage = 'ALPH1-EN109_PALETO_HEIST.png',
        cardTags = {},
        requiresEffectPlay = true,
        effectTags = { 'on_play', 'gain_lp', 'draw', 'bank_card' },
        effects = {
        {
        trigger = 'on_play',
        condition = { playedByEffect = true },
        tags = { 'gain_lp', 'draw' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 300 },
        { action = 'draw_until_hand_size', target = 'self', handSize = 4 }
        }
        }
        },
    },
    ['ALPH1_EN110_BANK_CARD'] = {
        id = 'ALPH1_EN110_BANK_CARD',
        name = 'Bank Card',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If this card remains on your field for 3 turns, you can play \'Paleto Heist\' from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN110',
        legality = '',
        inventoryImage = 'ALPH1-EN110_BANK_CARD.png',
        cardTags = {},
        continuous = true,
        effectTags = { 'on_play', 'delayed', 'play_from_deck' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'delayed', 'play_from_deck' },
        actions = {
        {
        action = 'schedule_delayed_actions',
        timing = 'start_turn',
        turns = 3,
        label = 'Bank Card Paleto Heist',
        requireSourceZone = 'itemZones',
        actions = {
        { action = 'play_event_from_deck', filter = { type = 'Event', nameContains = 'Paleto Heist' } }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN111_POLICE_CHASE'] = {
        id = 'ALPH1_EN111_POLICE_CHASE',
        name = 'Police Chase',
        rarity = 'COMMON',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'PIT MANOVEUR',
        effectText = 'If you control any \'LEO\' card, target the lowest SPD vehicle card on the field, then banish it and its equipped fighter.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN111',
        legality = '',
        inventoryImage = 'ALPH1-EN111_POLICE_CHASE.png',
        cardTags = {},
        effectTags = { 'on_play', 'banish', 'vehicle', 'police' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'banish', 'vehicle', 'police' },
        condition = { ownFieldCardMatches = { cardTagsAny = { 'Police', 'LEO' } } },
        actions = {
        { action = 'banish_lowest_speed_vehicle_and_equipped_fighter' }
        }
        }
        },
    },
    ['ALPH1_EN112_DRACO'] = {
        id = 'ALPH1_EN112_DRACO',
        name = 'Draco',
        rarity = 'SUPER',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +40',
        defense = '',
        effectTitle = '7.62',
        effectText = 'The equipped card inflicts piercing damage.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN112',
        legality = '',
        inventoryImage = 'ALPH1-EN112_DRACO.png',
        cardTags = { 'Contraband' },
        effectTags = { 'continuous', 'piercing', 'weapon' },
        effects = {
        {
        continuous = true,
        tags = { 'piercing', 'weapon' },
        actions = {}
        }
        },
    },
    ['ALPH1_EN113_SOSMC_CLUBHOUSE'] = {
        id = 'ALPH1_EN113_SOSMC_CLUBHOUSE',
        name = 'SOSMC Clubhouse',
        rarity = 'ULTRA',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'SFFS',
        effectText = 'SOSMC cards you control gain +2 SPD. Once per turn you can discard 1 card to activate 1 of these effects: 1. Add 1 \'SOSMC\' card to your hand. 2. Special summon 1 \'SOSMC\' card from your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN113',
        legality = '',
        inventoryImage = 'ALPH1-EN113_SOSMC_CLUBHOUSE.png',
        cardTags = {},
        effectTags = { 'continuous', 'activated', 'sosmc', 'stat_modifier', 'discard', 'search_deck', 'special_summon', 'once_per_turn' },
        effects = {
        {
        continuous = true,
        tags = { 'sosmc', 'stat_modifier' },
        actions = {
        { action = 'modify_stats', target = 'all_self_fighters', filter = { jobContains = 'SOSMC' }, stats = { speed = 2 } }
        }
        },
        {
        trigger = 'activated',
        activationZones = { 'locationZone' },
        tags = { 'discard', 'search_deck', 'sosmc' },
        optional = true,
        oncePerTurn = true,
        oncePerTurnKey = 'sosmc_clubhouse',
        promptText = 'Discard 1 card to add 1 SOSMC card from your deck to your hand?',
        actions = {
        { action = 'select_send_matching_to_graveyard', zone = 'hand', reason = 'discard', promptText = 'Choose 1 card from your hand to discard.', filter = {} },
        { action = 'search_deck_to_hand', choose = true, promptText = 'Choose 1 SOSMC card to add to hand.', filter = { jobContains = 'SOSMC' } }
        }
        },
        {
        trigger = 'activated',
        activationZones = { 'locationZone' },
        tags = { 'discard', 'special_summon', 'sosmc' },
        optional = true,
        oncePerTurn = true,
        oncePerTurnKey = 'sosmc_clubhouse',
        promptText = 'Discard 1 card to special summon 1 SOSMC fighter from your hand?',
        actions = {
        { action = 'select_send_matching_to_graveyard', zone = 'hand', reason = 'discard', promptText = 'Choose 1 card from your hand to discard.', filter = {} },
        { action = 'special_summon_from_hand', filter = { type = 'Fighter', jobContains = 'SOSMC' } }
        }
        }
        },
    },
    ['ALPH1_EN114_ELI_MALLORY'] = {
        id = 'ALPH1_EN114_ELI_MALLORY',
        name = 'Eli Mallory',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'EMS',
        level = 'Level 2',
        speed = '3',
        attack = '30',
        defense = '70',
        effectTitle = 'HEROES NEVER DIE!',
        effectText = 'While this card is on the field, your other fighters cannot be destroyed by battle.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN114',
        legality = '',
        inventoryImage = 'ALPH1-EN114_ELI_MALLORY.png',
        cardTags = {},
        effectTags = { 'would_be_destroyed', 'battle_immunity', 'protection' },
        effects = {
        {
        trigger = 'would_be_destroyed',
        tags = { 'battle_immunity', 'protection' },
        condition = {
        destroyReason = 'battle',
        targetController = 'self',
        targetNotSource = true,
        targetFilter = { type = 'Fighter' }
        },
        actions = {
        { action = 'prevent_destruction' }
        }
        }
        },
    },
    ['ALPH1_EN115_KINDRED_RODIN'] = {
        id = 'ALPH1_EN115_KINDRED_RODIN',
        name = 'Kindred Rodin',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'SOSMC Sgt at Arms',
        level = 'Level 2',
        speed = '4',
        attack = '30',
        defense = '90',
        effectTitle = 'PAY YOUR FINE',
        effectText = 'While this card is on the field, your opponent must pay 100LP declare an attack.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN115',
        legality = '',
        inventoryImage = 'ALPH1-EN115_KINDRED_RODIN.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN116_CLYDE_RILEY_JR'] = {
        id = 'ALPH1_EN116_CLYDE_RILEY_JR',
        name = 'Clyde Riley JR',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '4',
        attack = '40',
        defense = '20',
        effectTitle = 'EFFECT',
        effectText = 'If this card is discarded, you can place 1 random card from your opponents hand, at the bottom of their deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN116',
        legality = '',
        inventoryImage = 'ALPH1-EN116_CLYDE_RILEY_JR.png',
        cardTags = {},
        effectTags = { 'on_sent_to_cemetery', 'discard', 'hand_disruption', 'deck_bottom' },
        effects = {
        {
        trigger = 'on_sent_to_cemetery',
        tags = { 'discard', 'hand_disruption', 'deck_bottom' },
        optional = true,
        condition = { sentReason = 'discard' },
        promptText = 'Clyde Riley JR was discarded. Put a random opponent hand card on the bottom of their deck?',
        actions = {
        { action = 'move_random_opponent_hand_to_deck_bottom' }
        }
        }
        },
    },
    ['ALPH1_EN117_OXYCODONE'] = {
        id = 'ALPH1_EN117_OXYCODONE',
        name = 'Oxycodone',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Last Stand',
        effectText = 'If your fighter would take lethal damage, you can discard this card, the fighter survives with 1 HP. At the end of your next turn, send that fighter to the cemetary',
        edition = '1st Edition',
        setCode = 'ALPH1-EN117',
        legality = '',
        inventoryImage = 'ALPH1-EN117_OXYCODONE.png',
        cardTags = { 'Contraband', 'drug' },
        effectTags = { 'would_take_battle_damage', 'lethal_damage', 'discard', 'delayed' },
        effects = {
        {
        trigger = 'would_take_battle_damage',
        activationZones = { 'hand' },
        condition = { lethalBattleDamage = true },
        tags = { 'lethal_damage', 'discard', 'delayed' },
        costs = {
        { action = 'discard_self_from_hand' }
        },
        actions = {
        { action = 'lethal_battle_damage_survive_1_then_cemetery' }
        }
        }
        },
    },
    ['ALPH1_EN118_HAKOUCHOU_DRAG'] = {
        id = 'ALPH1_EN118_HAKOUCHOU_DRAG',
        name = 'Hakouchou Drag',
        rarity = 'RARE',
        type = 'Vehicle',
        job = 'Shitzu',
        level = '',
        speed = 'SPD +6',
        attack = '',
        defense = '',
        effectTitle = 'Deathtrap',
        effectText = 'On each of your main phase, roll a D6, if you roll a 1 or 6, destroy this card and the equipped fighter takes -20 HP damage.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN118',
        legality = '',
        inventoryImage = 'ALPH1-EN118_HAKOUCHOU_DRAG.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN119_SKATEBOARD'] = {
        id = 'ALPH1_EN119_SKATEBOARD',
        name = 'Skateboard',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Coinfl.. *uhh* Kickflip',
        effectText = 'Flip a coin, if heads draw a card. If tails your opponent draws a card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN119',
        legality = '',
        inventoryImage = 'ALPH1-EN119_SKATEBOARD.png',
        cardTags = {},
        effectTags = { 'on_play', 'coin_flip', 'draw' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'coin_flip', 'draw' },
        actions = {
        { action = 'coin_flip_draw', headsTarget = 'self', tailsTarget = 'opponent', amount = 1 }
        }
        }
        },
    },
    ['ALPH1_EN120_OUTFIT_BAG'] = {
        id = 'ALPH1_EN120_OUTFIT_BAG',
        name = 'Outfit Bag',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Quick Change!',
        effectText = 'Send 1 of your fighters back to your hand, summon 1 fighter with the same name from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN120',
        legality = '',
        inventoryImage = 'ALPH1-EN120_OUTFIT_BAG.png',
        cardTags = {},
        effectTags = { 'on_play', 'return_to_hand', 'special_summon', 'same_name', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'return_to_hand', 'special_summon', 'same_name', 'target' },
        actions = {
        {
        action = 'select_swap_fighter_same_name_from_deck',
        promptText = 'Choose 1 fighter to return to hand and replace with a same-name fighter from your deck.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
    },
    ['ALPH1_EN121_XP_POTION'] = {
        id = 'ALPH1_EN121_XP_POTION',
        name = 'XP potion',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Speedy Promo',
        effectText = 'You can promote 1 fighter the turn they were summoned.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN121',
        legality = '',
        inventoryImage = 'ALPH1-EN121_XP_POTION.png',
        cardTags = {},
        effectTags = { 'on_play', 'promotion_rule' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'promotion_rule' },
        actions = {
        { action = 'add_player_status', target = 'self', status = 'allow_same_turn_promotion', name = 'Same-turn Promotion', timing = 'end_turn', turns = 1 }
        }
        }
        },
    },
    ['ALPH1_EN122_AIR_FRESHENER'] = {
        id = 'ALPH1_EN122_AIR_FRESHENER',
        name = 'Air freshener',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'De-Stress',
        effectText = 'Once per turn, gain +10 LP for every vehicle card you control',
        edition = '1st Edition',
        setCode = 'ALPH1-EN122',
        legality = '',
        inventoryImage = 'ALPH1-EN122_AIR_FRESHENER.png',
        cardTags = {},
        effectTags = { 'activated', 'gain_lp', 'vehicle', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'itemZone' },
        tags = { 'gain_lp', 'vehicle' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Gain 10 LP for every Vehicle card you control?',
        actions = {
        { action = 'gain_lp_per_matching_card', amountPerCard = 10, zones = { 'field' }, filter = { type = 'Vehicle' } }
        }
        }
        },
    },
    ['ALPH1_EN123_IFAKS'] = {
        id = 'ALPH1_EN123_IFAKS',
        name = 'IFAKS',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Heal me daddy!',
        effectText = 'When one of your fighters is targeted for an attack, discard this card from your hand. Negate the attack and end the battle phase.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN123',
        legality = '',
        inventoryImage = 'ALPH1-EN123_IFAKS.png',
        cardTags = {},
        effectTags = { 'response', 'attack_declared', 'discard', 'negate_attack' },
        effects = {
        {
        trigger = 'response',
        responseZones = { 'hand' },
        condition = { responseEvent = 'attack_declared' },
        tags = { 'attack_declared', 'discard', 'negate_attack' },
        actions = {
        { action = 'discard_self_from_hand' },
        { action = 'cancel_pending_battle' }
        }
        }
        },
    },
    ['ALPH1_EN124_SNS_CLIP'] = {
        id = 'ALPH1_EN124_SNS_CLIP',
        name = 'SNS clip',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +0',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Loop\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN124',
        legality = '',
        inventoryImage = 'ALPH1-EN124_SNS_CLIP.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN125_FUGITIVE'] = {
        id = 'ALPH1_EN125_FUGITIVE',
        name = 'Fugitive',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = 'Cheval',
        level = '',
        speed = 'SPD +4',
        attack = '',
        defense = '',
        effectTitle = 'First Car',
        effectText = 'Each turn during the end phase, reduce the speed of this card by -1 until it becomes 1.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN125',
        legality = '',
        inventoryImage = 'ALPH1-EN125_FUGITIVE.png',
        cardTags = {},
        effectTags = { 'end_phase', 'vehicle', 'stat_modifier' },
        effects = {
        {
        trigger = 'end_phase',
        tags = { 'vehicle', 'stat_modifier' },
        actions = {
        { action = 'modify_equipment_bonus', stat = 'speed', amount = -1, minValue = 1 }
        }
        }
        },
    },
    ['ALPH1_EN126_BRAVADO_BISON'] = {
        id = 'ALPH1_EN126_BRAVADO_BISON',
        name = 'Bravado Bison',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +1',
        attack = '',
        defense = '',
        effectTitle = 'Little Big Bison',
        effectText = 'This card also applies +1 SPD to all other fighters you control.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN126',
        legality = '',
        inventoryImage = 'ALPH1-EN126_BRAVADO_BISON.png',
        cardTags = {},
        effectTags = { 'continuous', 'vehicle', 'stat_modifier' },
        effects = {
        {
        continuous = true,
        tags = { 'vehicle', 'stat_modifier' },
        actions = {
        { action = 'modify_stats', target = 'all_self_fighters', excludeEquippedFighter = true, stats = { speed = 1 } }
        }
        }
        },
    },
    ['ALPH1_EN127_POLICE_BUFFALO_HELLFIRE'] = {
        id = 'ALPH1_EN127_POLICE_BUFFALO_HELLFIRE',
        name = 'Police Buffalo Hellfire',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +6',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If equipped to an LEO card, it gains +2 SPD and +30 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN127',
        legality = '',
        inventoryImage = 'ALPH1-EN127_POLICE_BUFFALO_HELLFIRE.png',
        cardTags = { 'Police' },
        effectTags = { 'continuous', 'vehicle', 'police', 'stat_modifier' },
        effects = {
        {
        continuous = true,
        tags = { 'vehicle', 'police', 'stat_modifier' },
        actions = {
        { action = 'modify_stats', target = 'equipped_fighter', filter = { cardTagsAny = { 'Police', 'LEO' } }, stats = { speed = 2, hp = 30 } }
        }
        }
        },
    },
    ['ALPH1_EN128_DOOBIE'] = {
        id = 'ALPH1_EN128_DOOBIE',
        name = 'Doobie',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Spark Up!',
        effectText = 'Choose one of your fighters, it loses -2 SPD and gains +30 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN128',
        legality = '',
        inventoryImage = 'ALPH1-EN128_DOOBIE.png',
        cardTags = {},
        effectTags = { 'on_play', 'stat_modifier', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'stat_modifier', 'target' },
        actions = {
        {
        action = 'select_modify_stats',
        owner = 'self',
        zone = 'fighterZones',
        promptText = 'Choose 1 fighter to lose 2 SPD and gain 30 HP.',
        filter = { type = 'Fighter' },
        stats = { speed = -2, hp = 30 }
        }
        }
        }
        },
    },
    ['ALPH1_EN129_STAGE_3_BRAKES'] = {
        id = 'ALPH1_EN129_STAGE_3_BRAKES',
        name = 'Stage 3 Brakes',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Slam the Brakes',
        effectText = 'Target 1 of your opponents vehicles. For this turn it loses all SPD bonus.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN129',
        legality = '',
        inventoryImage = 'ALPH1-EN129_STAGE_3_BRAKES.png',
        cardTags = { 'Vehicle Upgrade' },
        effectTags = { 'on_play', 'vehicle_upgrade', 'vehicle', 'stat_modifier', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'vehicle_upgrade', 'vehicle', 'stat_modifier', 'target' },
        actions = {
        {
        action = 'select_modify_equipment_bonus',
        owner = 'opponent',
        zone = 'field',
        promptText = 'Choose 1 opponent Vehicle to lose its SPD bonus this turn.',
        filter = { type = 'Vehicle' },
        stat = 'speed',
        setTo = 0,
        duration = 'turn'
        }
        }
        }
        },
    },
    ['ALPH1_EN130_STAGE_4_ENGINE'] = {
        id = 'ALPH1_EN130_STAGE_4_ENGINE',
        name = 'Stage 4 Engine',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Forged Internals',
        effectText = 'Target 1 vehicle you control, it gains +50% SPD.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN130',
        legality = '',
        inventoryImage = 'ALPH1-EN130_STAGE_4_ENGINE.png',
        cardTags = { 'Vehicle Upgrade' },
        effectTags = { 'on_play', 'vehicle_upgrade', 'vehicle', 'stat_modifier', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'vehicle_upgrade', 'vehicle', 'stat_modifier', 'target' },
        actions = {
        {
        action = 'select_modify_equipment_bonus',
        owner = 'self',
        zone = 'field',
        promptText = 'Choose 1 Vehicle you control to gain +50% SPD.',
        filter = { type = 'Vehicle' },
        stat = 'speed',
        multiplier = 0.5
        }
        }
        }
        },
    },
    ['ALPH1_EN131_STAGE_4_SUSPENSION'] = {
        id = 'ALPH1_EN131_STAGE_4_SUSPENSION',
        name = 'Stage 4 Suspension',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Boing!',
        effectText = 'Target 1 vehicle you control, the first time it would be destroyed by a card effect, it survives.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN131',
        legality = '',
        inventoryImage = 'ALPH1-EN131_STAGE_4_SUSPENSION.png',
        cardTags = { 'Vehicle Upgrade' },
        effectTags = { 'on_play', 'protection', 'vehicle_upgrade' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'protection', 'vehicle_upgrade' },
        optional = true,
        promptText = 'Target 1 vehicle you control to survive its next card-effect destruction?',
        actions = {
        {
        action = 'select_apply_status',
        owner = 'self',
        zone = 'field',
        promptText = 'Choose 1 vehicle you control.',
        filter = { type = 'Vehicle' },
        statuses = {
        {
        id = 'first_destruction_shield',
        name = 'Destruction Shield'
        }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN132_SAINT_ROSES_CHURCH'] = {
        id = 'ALPH1_EN132_SAINT_ROSES_CHURCH',
        name = 'Saint Roses Church',
        rarity = 'ULTRA',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Let Us Pray',
        effectText = 'If your opponent would gain LP, they lose it instead. Gain LP equal to half what your opponent loses via this effect.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN132',
        legality = '',
        inventoryImage = 'ALPH1-EN132_SAINT_ROSES_CHURCH.png',
        cardTags = {},
        effectTags = { 'would_gain_lp', 'lp_replacement', 'gain_lp', 'damage_lp' },
        effects = {
        {
        trigger = 'would_gain_lp',
        tags = { 'lp_replacement', 'gain_lp', 'damage_lp' },
        condition = {
        targetController = 'opponent'
        },
        actions = {
        { action = 'invert_lp_gain', selfGainMultiplier = 0.5 }
        }
        }
        },
    },
    ['ALPH1_EN133_WADE_WOLSON'] = {
        id = 'ALPH1_EN133_WADE_WOLSON',
        name = 'Wade Wolson',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Philanthropist',
        level = 'Level 2',
        speed = '2',
        attack = '20',
        defense = '20',
        effectTitle = 'Come Find Me!',
        effectText = 'Shuffle this card into your opponents deck, when your opponent draws this card, they lose -80LP, then you draw 1 card. This card is then sent to your cemetary.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN133',
        legality = '',
        inventoryImage = 'ALPH1-EN133_WADE_WOLSON.png',
        cardTags = {},
        effectTags = { 'activated', 'deck', 'draw_trap', 'lose_lp', 'draw' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'deck', 'draw_trap', 'lose_lp', 'draw' },
        actions = {
        { action = 'plant_self_in_opponent_deck', lpLoss = 80, ownerDraw = 1 }
        }
        }
        },
    },
    ['ALPH1_EN134_DAILY_SPIN'] = {
        id = 'ALPH1_EN134_DAILY_SPIN',
        name = 'Daily Spin',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Fingers Crossed!',
        effectText = 'Discard 1 level 2 fighter to draw a card.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN134',
        legality = '',
        inventoryImage = 'ALPH1-EN134_DAILY_SPIN.png',
        cardTags = {},
        effectTags = { 'on_play', 'discard', 'draw', 'level_2' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'discard', 'draw', 'level_2' },
        actions = {
        {
        action = 'select_send_matching_to_graveyard',
        zone = 'hand',
        minChoices = 1,
        maxChoices = 1,
        thenDraw = 1,
        reason = 'discard',
        promptText = 'Choose 1 Level 2 Fighter from your hand to discard.',
        filter = { type = 'Fighter', level = 2 }
        }
        }
        }
        },
    },
    ['ALPH1_EN135_BAILEY_BLEWITT'] = {
        id = 'ALPH1_EN135_BAILEY_BLEWITT',
        name = 'Bailey Blewitt',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'FIB',
        level = 'Level 2',
        speed = '4',
        attack = '50',
        defense = '60',
        effectTitle = 'Surveilance',
        effectText = 'Once per turn, when you activate this effect: your opponent must chose 1 of these effects. 1) Your opponent must show you their hand or 2) Your opponent loses 40 LP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN135',
        legality = '',
        inventoryImage = 'ALPH1-EN135_BAILEY_BLEWITT.png',
        cardTags = {},
        effectTags = { 'activated', 'once_per_turn', 'opponent_choice', 'reveal', 'lose_lp' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        oncePerTurn = true,
        promptPlayer = 'opponent',
        promptTitle = 'Bailey Blewitt',
        promptText = 'Choose how Bailey Blewitt resolves.',
        confirmText = 'Choose',
        cancelText = '',
        form = {
        options = {
        { id = 'reveal', label = 'Reveal Hand', description = 'Reveal your hand to your opponent.' },
        { id = 'lose_lp', label = 'Lose 40 LP', description = 'Lose 40 LP instead.' }
        }
        },
        options = {
        {
        id = 'reveal',
        actions = {
        { action = 'reveal_hand', target = 'opponent' }
        }
        },
        {
        id = 'lose_lp',
        actions = {
        { action = 'lose_lp', target = 'opponent', amount = 40 }
        }
        }
        }
        },
        },
    },
    ['ALPH1_EN136_EXTENDED_CLIP'] = {
        id = 'ALPH1_EN136_EXTENDED_CLIP',
        name = 'Extended Clip',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Reloading!!',
        effectText = 'Target one of your fighter cards, it can make 2 attacks this turn.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN136',
        legality = '',
        inventoryImage = 'ALPH1-EN136_EXTENDED_CLIP.png',
        cardTags = {},
        effectTags = { 'on_play', 'extra_attack', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'extra_attack', 'target' },
        actions = {
        {
        action = 'select_apply_status',
        owner = 'self',
        zone = 'fighterZones',
        promptText = 'Choose 1 fighter to make 2 attacks this turn.',
        filter = { type = 'Fighter' },
        statuses = {
        {
        id = 'extra_attacks',
        name = 'Extra Attack',
        amount = 1,
        timing = 'end_turn',
        turns = 1
        }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN137_SNS_TRIGGER'] = {
        id = 'ALPH1_EN137_SNS_TRIGGER',
        name = 'SNS Trigger',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +0',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Loop\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN137',
        legality = '',
        inventoryImage = 'ALPH1-EN137_SNS_TRIGGER.png',
        cardTags = {},
        effectTags = { 'activated', 'weapon', 'combo', 'search_deck' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'equipmentZone' },
        oncePerTurn = true,
        tags = { 'weapon', 'combo', 'search_deck' },
        actions = {
        {
        action = 'complete_equipment_combo_to_hand',
        requiredNames = { 'SNS clip', 'SNS Trigger', 'SNS Loop' },
        searchFilter = { type = 'Weapon', nameContains = 'SNS Pistol' }
        }
        }
        }
        },
    },
    ['ALPH1_EN138_SNS_LOOP'] = {
        id = 'ALPH1_EN138_SNS_LOOP',
        name = 'SNS Loop',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +0',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Loop\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN138',
        legality = '',
        inventoryImage = 'ALPH1-EN138_SNS_LOOP.png',
        cardTags = {},
        effectTags = { 'activated', 'weapon', 'combo', 'search_deck' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'equipmentZone' },
        oncePerTurn = true,
        tags = { 'weapon', 'combo', 'search_deck' },
        actions = {
        {
        action = 'complete_equipment_combo_to_hand',
        requiredNames = { 'SNS clip', 'SNS Trigger', 'SNS Loop' },
        searchFilter = { type = 'Weapon', nameContains = 'SNS Pistol' }
        }
        }
        }
        },
    },
    ['ALPH1_EN139_SNS_PISTOL'] = {
        id = 'ALPH1_EN139_SNS_PISTOL',
        name = 'SNS Pistol',
        rarity = 'SUPER',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = 'ATK +50',
        defense = '',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN139',
        legality = '',
        inventoryImage = 'ALPH1-EN139_SNS_PISTOL.png',
        cardTags = {},
        effectTags = {},
        effects = {},
    },
    ['ALPH1_EN140_RIGHT_ARM_OF_THE_LIGHTBRINGER'] = {
        id = 'ALPH1_EN140_RIGHT_ARM_OF_THE_LIGHTBRINGER',
        name = 'Right Arm of the Lightbringer',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '1',
        attack = '10',
        defense = '0',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN140',
        legality = 'Limited',
        inventoryImage = 'ALPH1-EN140_RIGHT_ARM_OF_THE_LIGHTBRINGER.png',
        cardTags = {},
        effectTags = {},
        effects = {},
    },
    ['ALPH1_EN141_LEFT_ARM_OF_THE_LIGHTBRINGER'] = {
        id = 'ALPH1_EN141_LEFT_ARM_OF_THE_LIGHTBRINGER',
        name = 'Left Arm of the Lightbringer',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '1',
        attack = '10',
        defense = '0',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN141',
        legality = 'Limited',
        inventoryImage = 'ALPH1-EN141_LEFT_ARM_OF_THE_LIGHTBRINGER.png',
        cardTags = {},
        effectTags = {},
        effects = {},
    },
    ['ALPH1_EN142_LEFT_LEG_OF_THE_LIGHTBRINGER'] = {
        id = 'ALPH1_EN142_LEFT_LEG_OF_THE_LIGHTBRINGER',
        name = 'Left Leg of the Lightbringer',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '1',
        attack = '10',
        defense = '0',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN142',
        legality = 'Limited',
        inventoryImage = 'ALPH1-EN142_LEFT_LEG_OF_THE_LIGHTBRINGER.png',
        cardTags = {},
        effectTags = {},
        effects = {},
    },
    ['ALPH1_EN143_RIGHT_LEG_OF_THE_LIGHTBRINGER'] = {
        id = 'ALPH1_EN143_RIGHT_LEG_OF_THE_LIGHTBRINGER',
        name = 'Right Leg of the Lightbringer',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '1',
        attack = '10',
        defense = '0',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN143',
        legality = 'Limited',
        inventoryImage = 'ALPH1-EN143_RIGHT_LEG_OF_THE_LIGHTBRINGER.png',
        cardTags = {},
        effectTags = {},
        effects = {},
    },
    ['ALPH1_EN144_LUCIAN_LIGHTBRINGER'] = {
        id = 'ALPH1_EN144_LUCIAN_LIGHTBRINGER',
        name = 'Lucian Lightbringer',
        rarity = 'GHOST',
        type = 'Fighter',
        job = 'Deity',
        level = 'Level X',
        speed = '50',
        attack = '2000',
        defense = '2000',
        effectTitle = 'Kneel Before!',
        effectText = 'This card can only be summoned by discarding \'Right Arm of the Lightbringer\', \'Left Arm of the Lightbringer\', \'Left Leg of the Lightbringer\' and \'Right Leg of the Lightbringer\' from your hand.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN144',
        legality = 'Limited',
        inventoryImage = 'ALPH1-EN144_LUCIAN_LIGHTBRINGER.png',
        cardTags = {},
        effectTags = { 'activated', 'hand', 'special_summon', 'discard' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'hand' },
        tags = { 'hand', 'special_summon', 'discard' },
        actions = {
        {
        action = 'discard_named_hand_cards_and_special_summon_self',
        requiredNames = {
        'Right Arm of the Lightbringer',
        'Left Arm of the Lightbringer',
        'Left Leg of the Lightbringer',
        'Right Leg of the Lightbringer'
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN145_PILLBOX_HOSPITAL'] = {
        id = 'ALPH1_EN145_PILLBOX_HOSPITAL',
        name = 'Pillbox Hospital',
        rarity = 'RARE',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'A Spoonful O\' Medicine',
        effectText = 'While this card is on the field you can summon level 2 \'EMS\' cards without promotion. Also \'EMS\' cards you control gain +30 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN145',
        legality = '',
        inventoryImage = 'ALPH1-EN145_PILLBOX_HOSPITAL.png',
        cardTags = {},
        effectTags = { 'continuous', 'ems', 'stat_modifier', 'summon_rule' },
        effects = {
        {
        continuous = true,
        tags = { 'ems', 'stat_modifier' },
        actions = {
        { action = 'modify_stats', target = 'all_self_fighters', filter = { jobContains = 'EMS' }, stats = { hp = 30 } }
        }
        }
        },
    },
    ['ALPH1_EN146_TERMINUS'] = {
        id = 'ALPH1_EN146_TERMINUS',
        name = 'Terminus',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = 'Canis',
        level = '',
        speed = 'SPD +3',
        attack = '',
        defense = 'HP +20',
        effectTitle = '',
        effectText = '',
        edition = '1st Edition',
        setCode = 'ALPH1-EN146',
        legality = '',
        inventoryImage = 'ALPH1-EN146_TERMINUS.png',
        cardTags = {},
        effectTags = {},
        effects = {},
        pendingEffectReview = true,
    },
    ['ALPH1_EN147_BANK_LOAN'] = {
        id = 'ALPH1_EN147_BANK_LOAN',
        name = 'Bank Loan',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Small Loan of 1Mil Dollars',
        effectText = 'Draw 2 cards, in the end phase send your whole hand to the cemetery.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN147',
        legality = '',
        inventoryImage = 'ALPH1-EN147_BANK_LOAN.png',
        cardTags = {},
        effectTags = { 'on_play', 'draw', 'discard', 'delayed' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'draw', 'discard', 'delayed' },
        actions = {
        { action = 'draw', target = 'self', amount = 2 },
        {
        action = 'schedule_delayed_actions',
        timing = 'end_turn',
        turns = 1,
        label = 'Bank Loan hand discard',
        actions = {
        { action = 'discard_hand', target = 'self', amount = 99 }
        }
        }
        }
        }
        },
    },
    ['ALPH1_EN148_ALAN_HALL'] = {
        id = 'ALPH1_EN148_ALAN_HALL',
        name = 'Alan Hall',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'IAG Director',
        level = 'Level 1',
        speed = '4',
        attack = '30',
        defense = '50',
        effectTitle = 'Under Investigation!',
        effectText = 'If you or your opponent control any \'First Responder\' card, you can special summon this card from your cemetary.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN148',
        legality = '',
        inventoryImage = 'ALPH1-EN148_ALAN_HALL.png',
        cardTags = {},
        effectTags = { 'activated', 'cemetery', 'special_summon', 'first_responder' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'graveyard' },
        tags = { 'cemetery', 'special_summon', 'first_responder' },
        condition = { anyFieldCardMatches = { cardTagsAny = { 'EMS', 'SAFR', 'SAMS', 'Police', 'USFW', 'DOJ' } } },
        actions = {
        { action = 'special_summon_self_from_graveyard' }
        }
        }
        },
    },
    ['ALPH1_EN149_BLOOD_DONATION'] = {
        id = 'ALPH1_EN149_BLOOD_DONATION',
        name = 'Blood Donation',
        rarity = 'RARE',
        type = 'Event',
        job = 'Giving in Vein',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Steal 30 LP from your opponent.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN149',
        legality = '',
        inventoryImage = 'ALPH1-EN149_BLOOD_DONATION.png',
        cardTags = {},
        effectTags = { 'on_play', 'steal_lp', 'damage_lp', 'gain_lp' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'steal_lp' },
        actions = {
        { action = 'steal_lp', amount = 30 }
        }
        }
        },
    },
    ['ALPH1_EN150_AMBULANCE'] = {
        id = 'ALPH1_EN150_AMBULANCE',
        name = 'Ambulance',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +3',
        attack = '',
        defense = '',
        effectTitle = 'Whambulance',
        effectText = 'Each turn heal 20 HP.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN150',
        legality = '',
        inventoryImage = 'ALPH1-EN150_AMBULANCE.png',
        cardTags = {},
        effectTags = { 'end_phase', 'heal' },
        effects = {
        {
        trigger = 'end_phase',
        tags = { 'heal' },
        actions = {
        { action = 'heal_equipped_fighter', amount = 20 }
        }
        }
        },
    },
    ['ALPH1_EN151_POLYMORPH_POTION'] = {
        id = 'ALPH1_EN151_POLYMORPH_POTION',
        name = 'Polymorph Potion',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Morph',
        effectText = 'Shuffle 2 or more cards from your hand into your deck, then draw as many cards you shuffled.',
        edition = '1st Edition',
        setCode = 'ALPH1-EN151',
        legality = '',
        inventoryImage = 'ALPH1-EN151_POLYMORPH_POTION.png',
        cardTags = {},
        effectTags = { 'on_play', 'shuffle', 'draw', 'hand' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'shuffle', 'draw', 'hand' },
        actions = {
        {
        action = 'select_hand_to_deck',
        minChoices = 2,
        maxChoices = 99,
        thenDrawPerCard = 1,
        promptText = 'Choose 2 or more cards from your hand to shuffle into your deck, then draw that many.'
        }
        }
        }
        },
    },
}
