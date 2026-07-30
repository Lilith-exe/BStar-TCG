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
        inventoryImage = ''
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN001',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN001_LAYLA_HART.png'
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
        cardTags = {},
        legality = 'Semi Limited',
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
        setCode = 'ALPH1-EN002',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN002_MR_BSTAR.png'
    },

    ['ALPH1_EN003_MAX_TURNER_MIRANOVA'] = {
        id = 'ALPH1_EN003_MAX_TURNER_MIRANOVA',
        name = 'Max Turner Miranova',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Chief of SAFR',
        level = 'LEVEL 2',
        speed = '5',
        attack = '40',
        defense = '80',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can add 1 \'SAFR\' fighter from your deck. \'SAFR\' cards you control cannot be destroyed by card effects. This card is unaffected by burn effects.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN003',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN003_MAX_TURNER_MIRANOVA.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN004',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN004_WYATT_RAYNE.png'
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
        effectTitle = 'WHITE SHORTS',
        effectText = 'OPT: You can return this card to your hand and SP summon 1 \'Cougar\' from your deck. If you control \'Cougar\' you can tribute that card and SP summon this card from the hand or cemetary.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN005',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN005_XENA_COUGAR_MIRANOVA.png'
    },

    ['ALPH1_EN006_AARON_MILLER'] = {
        id = 'ALPH1_EN006_AARON_MILLER',
        name = 'Aaron Miller',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'BCSO',
        level = 'LEVEL 1',
        speed = '2',
        attack = '30',
        defense = '40',
        effectTitle = 'STOP AND SEARCH',
        effectText = 'Your opponent must discard any \'Contraband\' cards in their hand. This effect can only be used once per game.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN006',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN006_AARON_MILLER.png'
    },

    ['ALPH1_EN007_BROCK_LEE'] = {
        id = 'ALPH1_EN007_BROCK_LEE',
        name = 'Brock Lee',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'PDM',
        level = 'LEVEL 2',
        speed = '3',
        attack = '20',
        defense = '30',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can equip 1 Vehicle card from your deck to a fighter on the field.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN007',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN007_BROCK_LEE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN008',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN008_ALEX_CAVEMAN_ORTIZ.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN009',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN009_ZOE_MIRANOVA.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN010',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN010_NIKOLAS_HAAJA.png'
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
        effectText = 'On summon, If you control 2 or more vehicle cards, add 1 \'AED\' from your deck to your hand. If you control less than 2, you can add 1 \'bandage\' card from your deck to your hand.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        condition = { ownEquipmentCountMin = 2 },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 AED card to add to your hand.',
        filter = { nameContains = 'AED' }
        }
        }
        },
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        optional = true,
        condition = { ownEquipmentCountMax = 1 },
        promptText = 'Do you want to add 1 Bandage card from your deck to your hand?',
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Bandage card to add to your hand.',
        filter = { nameContains = 'Bandage' }
        }
        }
        }
        },
        setCode = 'ALPH1-EN011',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN011_FINNAGEN_SKYTECH.png'
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
        cardTags = { 'Animal' },
        legality = '',
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
        setCode = 'ALPH1-EN012',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN012_COUGAR.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN013',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN013_TOLL_BOOTH.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN014',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN014_LAYLA_HART.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN015',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN015_ZACK_GATOR.png'
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
        effectText = 'Once per turn, you can pay 50LP to take control of one of your opponents vehicle cards and equip it to a fighter of your choice. You opponent can sacrafice 1 card they control to send the vehicle back to their hand.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'control', 'vehicle', 'once_per_turn', 'target' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'locationZone' },
        tags = { 'control', 'vehicle', 'target' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Pay 50 LP to take control of 1 opponent vehicle card?',
        costs = {
        {
        action = 'lose_lp',
        target = 'self',
        amount = 50
        }
        },
        actions = {
        {
        action = 'select_take_control_equipment',
        target = 'opponent',
        zone = 'field',
        promptText = 'Choose 1 opponent vehicle card to take control of.',
        filter = { type = 'Vehicle' }
        }
        }
        }
        },
        setCode = 'ALPH1-EN016',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN016_HAYES_TOWING.png'
    },

    ['ALPH1_EN017_REDEMPTION_LUNA_RAYNE'] = {
        id = 'ALPH1_EN017_REDEMPTION_LUNA_RAYNE',
        name = 'Redemption Luna Rayne',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '3',
        attack = '20',
        defense = '30',
        effectTitle = 'TAG TEAM',
        effectText = 'OPT on summon, if you control no other fighters, you can special summon 1 level 1 Trey Rayne from your hand or deck.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN017',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN017_REDEMPTION_LUNA_RAYNE.png'
    },

    ['ALPH1_EN018_REDEMPTION_TREY_RAYNE'] = {
        id = 'ALPH1_EN018_REDEMPTION_TREY_RAYNE',
        name = 'Redemption Trey Rayne',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '3',
        attack = '20',
        defense = '30',
        effectTitle = 'TAG TEAM',
        effectText = 'OPT on summon, if you control no other fighters, you can special summon 1 level 1 Luna Rayne from your hand or deck.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN018',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN018_REDEMPTION_TREY_RAYNE.png'
    },

    ['ALPH1_EN019_NIKOLAS_HAAJA'] = {
        id = 'ALPH1_EN019_NIKOLAS_HAAJA',
        name = 'Nikolas Haaja',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '1',
        attack = '10',
        defense = '30',
        effectTitle = 'EFFECT',
        effectText = 'After 2 turns, promote this card to a level 2 \'Nikolas\' card from your deck.',
        cardTags = {},
        legality = '',
        effectTags = { 'delayed', 'promotion', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'delayed', 'promotion', 'search_deck' },
        actions = {
        {
        action = 'schedule_delayed_actions',
        turns = 2,
        timing = 'start_turn',
        label = 'Nikolas Haaja delayed promotion',
        actions = {
        {
        action = 'promote_self_from_deck',
        filter = { type = 'Fighter', level = 2, nameContains = 'Nikolas' }
        }
        }
        }
        }
        }
        },
        setCode = 'ALPH1-EN019',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN019_NIKOLAS_HAAJA.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN020',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN020_MAX_TURNER_MIRANOVA.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN021',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN021_WYATT_RAYNE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN022',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN022_JAY_MOZZY.png'
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
        effectText = 'Each time an item card is used, place 1 \'Healing\' counter on this card. You can remove 3 \'Healing\' counters to restore 1 fighter\'s HP to its base value.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'heal', 'activated', 'counter' },
        effects = {
        {
        trigger = 'on_play',
        activationZones = { 'fighterZone' },
        tags = { 'counter' },
        optional = false,
        condition = { playedCardType = 'Item' },
        actions = {
        { action = 'add_counter', counter = 'Healing', amount = 1 }
        }
        },
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'heal', 'counter', 'target' },
        condition = { sourceCounterMin = { counter = 'Healing', amount = 3 } },
        optional = true,
        promptText = 'Remove 3 Healing counters to restore 1 fighter to its base HP?',
        costs = {
        { action = 'remove_counter', counter = 'Healing', amount = 3 }
        },
        actions = {
        {
        action = 'select_heal_fighter',
        target = 'self',
        promptText = 'Choose 1 fighter to restore to base HP.',
        filter = { type = 'Fighter' },
        toBase = true
        }
        }
        }
        },
        setCode = 'ALPH1-EN023',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN023_XENA_MIRANOVA.png'
    },

    ['ALPH1_EN024_JAY_MOZZY'] = {
        id = 'ALPH1_EN024_JAY_MOZZY',
        name = 'Jay Mozzy',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'High notes owner',
        level = 'LEVEL 1',
        speed = '1',
        attack = '30',
        defense = '40',
        effectTitle = 'GET BAKED',
        effectText = 'Add 1 \'Doobie\' card to your hand. Also target 1 fighter on the field, reduce its SPD to 1.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN024',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN024_JAY_MOZZY.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN025',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN025_BANDAGE.png'
    },

    ['ALPH1_EN026_BROCK_LEE'] = {
        id = 'ALPH1_EN026_BROCK_LEE',
        name = 'Brock Lee',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '1',
        attack = '10',
        defense = '30',
        effectTitle = 'WABBIT',
        effectText = 'Add 1 \'Twitchy Wabbit\' card to your hand.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Twitchy Wabbit card to add to your hand.',
        filter = { nameContains = 'Twitchy Wabbit' }
        }
        }
        }
        },
        setCode = 'ALPH1-EN026',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN026_BROCK_LEE.png'
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
        defense = '30',
        effectTitle = 'EFFECT',
        effectText = 'This card takes no damage from \'Crow\' cards.',
        cardTags = {},
        legality = '',
        effectTags = { 'damage_immunity' },
        effects = {
        {
        trigger = 'would_take_battle_damage',
        tags = { 'damage_immunity', 'protection' },
        condition = {
        targetIsSource = true,
        eventAttackerNameContains = 'Crow'
        },
        actions = {
        { action = 'prevent_destruction' }
        }
        }
        },
        setCode = 'ALPH1-EN027',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN027_WULFRIK_CHAOSBANE.png'
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
        cardTags = { 'Animal' },
        legality = '',
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
        setCode = 'ALPH1-EN028',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN028_CROW.png'
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
        effectText = 'Add 1 \'Paleto\' location card from your deck.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'search_deck' },
        actions = {
        {
        action = 'search_deck_to_hand',
        choose = true,
        promptText = 'Choose 1 Paleto Location card to add to your hand.',
        filter = { type = 'Location', nameContains = 'Paleto' }
        }
        }
        }
        },
        setCode = 'ALPH1-EN029',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN029_BOB_HODGES.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN030',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN030_BOB_HODGES.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN031',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN031_YUKA_KASEN.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN032',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN032_SEN_GANBE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN033',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN033_HIROSHI_YAMATO.png'
    },

    ['ALPH1_EN034_HAO_YAMATO'] = {
        id = 'ALPH1_EN034_HAO_YAMATO',
        name = 'Hao Yamato',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Diamond Casino Director',
        level = 'LEVEL 2',
        speed = '4',
        attack = '30',
        defense = '70',
        effectTitle = 'ORGANISE',
        effectText = 'Add 1 \'Casino\' card to your hand.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN034',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN034_HAO_YAMATO.png'
    },

    ['ALPH1_EN035_KENCHIE_DAWSON'] = {
        id = 'ALPH1_EN035_KENCHIE_DAWSON',
        name = 'Kenchie Dawson',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'Wizard',
        level = 'LEVEL 1',
        speed = '3',
        attack = '50',
        defense = '60',
        effectTitle = 'ABRA KADABUNNY?',
        effectText = 'If your opponent summons 3 or more fighters this turn, tribute all of their fighters for 1x L1 \'Bunny token\' with 40 ATK, 40 HP and 3 SPD. Then summon this card to your field.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN035',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN035_KENCHIE_DAWSON.png'
    },

    ['ALPH1_EN036'] = {
        id = 'ALPH1_EN036',
        name = '',
        rarity = '',
        type = '',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = '',
        effectText = '',
        cardTags = {},
        legality = '',
        setCode = 'ALPH1-EN036',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN036.png'
    },

    ['ALPH1_EN037_LUKE_TAYLOR'] = {
        id = 'ALPH1_EN037_LUKE_TAYLOR',
        name = 'Luke Taylor',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Taylor\'s Ranch Owner',
        level = 'LEVEL 1',
        speed = '4',
        attack = '50',
        defense = '40',
        effectTitle = '',
        effectText = '',
        cardTags = {},
        legality = '',
        setCode = 'ALPH1-EN037',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN037_LUKE_TAYLOR.png'
    },

    ['ALPH1_EN038_KENCHIE_DAWSON'] = {
        id = 'ALPH1_EN038_KENCHIE_DAWSON',
        name = 'Kenchie Dawson',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Weazel News',
        level = 'LEVEL 2',
        speed = '5',
        attack = '30',
        defense = '60',
        effectTitle = 'THIS JUST IN!',
        effectText = 'Target 1 of your fighters in the cemetery. This card gains the effect of the card you targeted for this turn.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN038',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN038_KENCHIE_DAWSON.png'
    },

    ['ALPH1_EN039'] = {
        id = 'ALPH1_EN039',
        name = '',
        rarity = '',
        type = '',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = '',
        effectText = '',
        cardTags = {},
        legality = '',
        setCode = 'ALPH1-EN039',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN039.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN040',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN040_MATT_JACKSON.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN041',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN041_AMNESTY.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN042',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN042_LEPRECHAUN_MISCHIEF_2026.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN043',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN043_HEADPOP.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN044',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN044_MASS_HEADPOP.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN045',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN045_VACATION_TO_BAHAMAS.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN046',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN046_PINK_GRAPPLE_GUN.png'
    },

    ['ALPH1_EN047_AED'] = {
        id = 'ALPH1_EN047_AED',
        name = 'AED',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Revive',
        effectText = 'Revive one of your fighters from your cemetery.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN047',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN047_AED.png'
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
        cardTags = { 'Contraband', 'drug' },
        legality = '',
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
        setCode = 'ALPH1-EN048',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN048_BLUE_METH.png'
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
        cardTags = { 'Contraband', 'drug' },
        legality = '',
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
        setCode = 'ALPH1-EN049',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN049_METH.png'
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
        cardTags = { 'Contraband', 'drug' },
        legality = '',
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
        setCode = 'ALPH1-EN050',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN050_FENANYL.png'
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
        cardTags = { 'Contraband', 'drug' },
        legality = '',
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
        setCode = 'ALPH1-EN051',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN051_HEROINE.png'
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
        effectText = 'If you control a \'SAST\' fighter, target 1 fighter your opponent controls, it cannot attack for 2 turns.',
        cardTags = { 'Police' },
        legality = '',
        effectTags = { 'on_play', 'status', 'police' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'status', 'police' },
        condition = { ownControlsNameContains = 'SAST' },
        actions = {
        {
        action = 'select_apply_status',
        target = 'opponent',
        status = 'cannot_attack',
        name = 'Restrained',
        turns = 2,
        promptText = 'Choose 1 opponent fighter. It cannot attack for 2 turns.',
        filter = { type = 'Fighter' }
        }
        }
        }
        },
        setCode = 'ALPH1-EN052',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN052_HANDCUFFS.png'
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
        cardTags = { 'Police' },
        legality = '',
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
        setCode = 'ALPH1-EN053',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN053_TASER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN054',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN054_LOCKPICK.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN055',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN055_MAX_SLAYTER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN056',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN056_CASPER_CORTEZ.png'
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
        cardTags = { 'Vehicle Upgrade' },
        legality = '',
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
        setCode = 'ALPH1-EN057',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN057_TURBO.png'
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
        cardTags = { 'Vehicle Upgrade' },
        legality = '',
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
        setCode = 'ALPH1-EN058',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN058_TRANSMISSION_STAGE_4.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN059',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN059_DUMPSTER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN060',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN060_BACKPACK.png'
    },

    ['ALPH1_EN061_TWITCHY_WABBIT'] = {
        id = 'ALPH1_EN061_TWITCHY_WABBIT',
        name = 'Twitchy Wabbit',
        rarity = 'COMMON',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Equip to 1 \'Brock Lee\' card. It gains 20 HP and 10 SPD.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'equip', 'stat_modifier', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'equip', 'target' },
        actions = {
        {
        action = 'select_attach_self_to_fighter',
        target = 'self',
        zone = 'fighterZones',
        promptText = 'Choose 1 Brock Lee card to equip Twitchy Wabbit to.',
        filter = { type = 'Fighter', nameContains = 'Brock Lee' },
        forceEquipmentSlot = 'equipment',
        triggerOnPlay = false
        }
        }
        },
        {
        continuous = true,
        tags = { 'stat_modifier' },
        actions = {
        { action = 'modify_stats', target = 'equipped_fighter', stats = { hp = 20, speed = 10 } }
        }
        }
        },
        setCode = 'ALPH1-EN061',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN061_TWITCHY_WABBIT.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN062',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN062_INSIGHTFUL.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN063',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN063_HOSTAGE_DEMANDS.png'
    },

    ['ALPH1_EN064_CASINO_LUCKY_WHEEL'] = {
        id = 'ALPH1_EN064_CASINO_LUCKY_WHEEL',
        name = 'Casino Lucky Wheel',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Try Your Luck',
        effectText = 'Once per turn you can pay between 10 and 100 LP. Roll a 6 sided dice. If you roll a 5 or 6, gain twice the LP you paid. If you roll a 3 or 4, gain back the LP you spent on this card. If you roll 1 or 2 do nothing.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN064',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN064_CASINO_LUCKY_WHEEL.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN065',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN065_FIREHOUSE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN066',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN066_LOS_SANTOS_CUSTOMS.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN067',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN067_TROOPER_STATION.png'
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
        effectText = 'When an opponents fighter delcares an attack, you can summon 1 \'Bob Hodges (BCSO)\' card from your deck. Decrease your opponents fighters SPD by -3.',
        cardTags = {},
        legality = '',
        continuous = true,
        effectTags = { 'response', 'trap', 'on_attack_declared', 'special_summon', 'stat_modifier' },
        effects = {
        {
        trigger = 'response',
        responseZones = { 'itemZone' },
        tags = { 'trap', 'on_attack_declared', 'special_summon', 'stat_modifier' },
        optional = true,
        promptText = 'Activate Bob\'s Bush to summon Bob Hodges and reduce opponent fighter SPD?',
        condition = {
        responseEvent = 'attack_declared',
        attackingPlayer = 'opponent'
        },
        actions = {
        {
        action = 'special_summon_from_deck',
        filter = { type = 'Fighter', nameContains = 'Bob Hodges' }
        },
        {
        action = 'modify_stats',
        target = 'all_opponent_fighters',
        duration = 'turn',
        stats = { speed = -3 }
        }
        }
        }
        },
        setCode = 'ALPH1-EN068',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN068_BOB\'S_BUSH.png'
    },

    ['ALPH1_EN069_BRAVADO_BUFFALO_STX'] = {
        id = 'ALPH1_EN069_BRAVADO_BUFFALO_STX',
        name = 'Bravado Buffalo STX',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +4',
        attack = '',
        defense = '',
        effectTitle = '',
        effectText = '',
        cardTags = {},
        legality = '',
        effectTags = { 'equip', 'stat_modifier' },
        setCode = 'ALPH1-EN069',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN069_BRAVADO_BUFFALO_STX.png'
    },

    ['ALPH1_EN070_ALEUTIAN'] = {
        id = 'ALPH1_EN070_ALEUTIAN',
        name = 'Aleutian',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +3',
        attack = '',
        defense = '',
        effectTitle = 'Rapid Response',
        effectText = 'If this card is equipped to a \'SAMS\' fighter, increase SPD by another +2.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN070',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN070_ALEUTIAN.png'
    },

    ['ALPH1_EN071_GREEN_PANTO'] = {
        id = 'ALPH1_EN071_GREEN_PANTO',
        name = 'Green Panto',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +1',
        attack = '',
        defense = '',
        effectTitle = 'Panto-monium',
        effectText = 'When this card is sent to the cemetery, you can add 1 \'Green Panto\' card from your deck.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN071',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN071_GREEN_PANTO.png'
    },

    ['ALPH1_EN072_RUSTY_REBEL'] = {
        id = 'ALPH1_EN072_RUSTY_REBEL',
        name = 'Rusty Rebel',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD -1',
        attack = '',
        defense = '',
        effectTitle = 'Trusty Rusty',
        effectText = 'This card can be attached to any fighter card on the field.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN072',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN072_RUSTY_REBEL.png'
    },

    ['ALPH1_EN073_CHEBUREK_RUNE'] = {
        id = 'ALPH1_EN073_CHEBUREK_RUNE',
        name = 'Cheburek Rune',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD -2',
        attack = '',
        defense = '',
        effectTitle = 'Carboard Kit?',
        effectText = 'After this card has been equipped your fighter for 2 turns, you can target 1 of your opponents fighters, it is now equipped by this card.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN073',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN073_CHEBUREK_RUNE.png'
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
        cardTags = { 'Contraband' },
        legality = '',
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
        setCode = 'ALPH1-EN074',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN074_CERAMIC_PISTOL.png'
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
        cardTags = {},
        legality = '',
        effectTags = { 'equip', 'stat_modifier', 'animal' },
        effects = {
        {
        continuous = true,
        tags = { 'weapon', 'animal', 'battle_modifier' },
        actions = {}
        }
        },
        setCode = 'ALPH1-EN075',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN075_HUNTING_RIFLE.png'
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
        effectText = 'If the equipped fighter attacks your opponents fighter, apply burn. Burn: reduce the fighters HP by 10 each turn. If the equipped card attacks directly, apply burn to your opponents LP.',
        cardTags = { 'Contraband' },
        legality = '',
        effectTags = { 'equip', 'stat_modifier', 'burn', 'contraband' },
        effects = {
        {
        trigger = 'on_battle_damage',
        tags = { 'burn', 'status' },
        condition = {
        equippedFighterIsAttacker = true,
        battleTargetType = 'fighter',
        battleDamageToDefenderMin = 1
        },
        actions = {
        {
        action = 'add_status',
        target = 'event_defender',
        status = 'burn',
        name = 'Burn',
        amount = 5,
        timing = 'end_turn'
        }
        }
        },
        {
        trigger = 'on_battle_damage',
        tags = { 'burn', 'status' },
        condition = {
        equippedFighterIsAttacker = true,
        battleTargetType = 'direct',
        battleDamageToPlayerMin = 1
        },
        actions = {
        {
        action = 'add_player_status',
        target = 'event_defender_player',
        status = 'burn',
        name = 'Burn',
        amount = 5,
        timing = 'end_turn'
        }
        }
        }
        },
        setCode = 'ALPH1-EN076',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN076_FLAMETHROWER.png'
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
        cardTags = { 'Contraband' },
        legality = '',
        effectTags = { 'equip', 'stat_modifier', 'contraband' },
        effects = {
        {
        continuous = true,
        tags = { 'weapon', 'stat_modifier', 'contraband' },
        actions = {}
        }
        },
        setCode = 'ALPH1-EN077',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN077_TECH_9.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN078',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN078_BRADLEY_\'BK\'_KRAY.png'
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
        effectText = 'Boost another fighters ATK and HP by +20 for 2 turns.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'stat_modifier', 'target', 'delayed_task' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'stat_modifier', 'target' },
        optional = true,
        promptText = 'Boost another fighter by +20 ATK and +20 HP for 2 turns?',
        actions = {
        {
        action = 'select_modify_stats',
        target = 'self',
        promptText = 'Choose another fighter to boost.',
        filter = { type = 'Fighter', notSourceUid = true },
        stats = { attack = 20, hp = 20 },
        durationTurns = 2,
        durationTiming = 'end_turn',
        durationLabel = 'Kin Rodine boost expires'
        }
        }
        }
        },
        setCode = 'ALPH1-EN079',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN079_KIN_RODINE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN080',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN080_JAMIE_THOMAS.png'
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
        cardTags = { 'SAMS', 'SAFR', 'EMS' },
        legality = '',
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
        setCode = 'ALPH1-EN081',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN081_CLYDE_RILEY_SR_.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN082',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN082_WILLIAM_TAZENTINE.png'
    },

    ['ALPH1_EN083_TERRANCE_REDFIELD_RILEY'] = {
        id = 'ALPH1_EN083_TERRANCE_REDFIELD_RILEY',
        name = 'Terrance Redfield Riley',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'IAG',
        level = 'Level 2',
        speed = '2',
        attack = '30',
        defense = '50',
        effectTitle = '#Blame Terrance',
        effectText = 'Send 1 \'Vehicle\' Card from your hand or field to the graveyard, then you can target up to 1 vehicle card and 1 weapon card your opponent controls and destroy them.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'vehicle', 'destroy', 'weapon', 'target' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'vehicle', 'destroy', 'weapon', 'target' },
        optional = true,
        promptText = 'Send 1 Vehicle you control to destroy up to 1 opponent Vehicle and 1 opponent Weapon?',
        actions = {
        {
        action = 'select_send_matching_to_graveyard',
        zone = 'hand_and_field',
        promptText = 'Choose 1 Vehicle from your hand or field to send to the cemetery.',
        filter = { type = 'Vehicle' }
        },
        {
        action = 'select_destroy_field_card',
        target = 'opponent',
        zone = 'field',
        promptText = 'Choose up to 1 opponent Vehicle to destroy.',
        filter = { type = 'Vehicle' }
        },
        {
        action = 'select_destroy_field_card',
        target = 'opponent',
        zone = 'field',
        promptText = 'Choose up to 1 opponent Weapon to destroy.',
        filter = { type = 'Weapon' }
        }
        }
        }
        },
        setCode = 'ALPH1-EN083',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN083_TERRANCE_REDFIELD_RILEY.png'
    },

    ['ALPH1_EN084_TERRANCE_REDFIELD_RILEY'] = {
        id = 'ALPH1_EN084_TERRANCE_REDFIELD_RILEY',
        name = 'Terrance Redfield Riley',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'High Noon Hookah',
        level = 'Level 1',
        speed = '2',
        attack = '30',
        defense = '40',
        effectTitle = 'Rejuvinate',
        effectText = 'Once per turn you can make all of your fighters lose -1 SPD. Then heal all your fighters by +20 HP.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'stat_modifier', 'heal', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'stat_modifier', 'heal' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Have all your fighters lose -1 SPD, then heal them by 20 HP?',
        actions = {
        { action = 'modify_stats', target = 'all_self_fighters', stats = { speed = -1 } },
        { action = 'heal_all_fighters', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'ALPH1-EN084',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN084_TERRANCE_REDFIELD_RILEY.png'
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
        cardTags = { 'Vehicle Upgrade' },
        legality = '',
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
        setCode = 'ALPH1-EN085',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN085_VEHICLE_ARMOUR.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN086',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN086_TRIAD_COMPOUND.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN087',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN087_TAYLOR_BANDIT.png'
    },

    ['ALPH1_EN088_MUFASA_VOLKOV'] = {
        id = 'ALPH1_EN088_MUFASA_VOLKOV',
        name = 'Mufasa Volkov',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '3',
        attack = '20',
        defense = '80',
        effectTitle = 'Switching Tactics',
        effectText = 'Once per turn you can switch the ATK and HP of this card. You cannot attack the turn you activate this effect.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'stat_modifier', 'cannot_attack', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'stat_modifier', 'cannot_attack' },
        optional = true,
        oncePerTurn = true,
        promptText = 'Switch this card\'s ATK and HP for the rest of the duel?',
        actions = {
        { action = 'switch_self_attack_hp' },
        { action = 'add_status', status = 'cannot_attack', name = 'Cannot Attack', timing = 'end_turn', turns = 1 }
        }
        }
        },
        setCode = 'ALPH1-EN088',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN088_MUFASA_VOLKOV.png'
    },

    ['ALPH1_EN089_MUFASA_VOLKOV'] = {
        id = 'ALPH1_EN089_MUFASA_VOLKOV',
        name = 'Mufasa Volkov',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'LSPD Chief',
        level = 'Level 2',
        speed = '6',
        attack = '70',
        defense = '100',
        effectTitle = 'Stand Guard',
        effectText = 'Once per turn if a \'location\' or \'fighter\' card you control is targeted for destruction, negate the destruction.',
        cardTags = {},
        legality = '',
        effectTags = { 'would_be_destroyed', 'protection', 'once_per_turn' },
        effects = {
        {
        trigger = 'would_be_destroyed',
        tags = { 'protection' },
        oncePerTurn = true,
        condition = {
        destroyReason = 'card_effect',
        targetController = 'self',
        targetFilter = { typesAny = { 'Location', 'Fighter' } }
        },
        actions = {
        { action = 'prevent_destruction' }
        }
        }
        },
        setCode = 'ALPH1-EN089',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN089_MUFASA_VOLKOV.png'
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
        effectText = 'Roll a 100 sided dice. If you roll 90 or above, gain +100 LP.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'dice_roll', 'gain_lp' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'dice_roll', 'gain_lp' },
        actions = {
        { action = 'roll_gain_lp', sides = 100, threshold = 90, gain = 100 }
        }
        }
        },
        setCode = 'ALPH1-EN090',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN090_LOTTO!.png'
    },

    ['ALPH1_EN091_ERIC_COLEMAN'] = {
        id = 'ALPH1_EN091_ERIC_COLEMAN',
        name = 'Eric Coleman',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'Larry\'s Car Lot',
        level = 'Level 1',
        speed = '3',
        attack = '30',
        defense = '40',
        effectTitle = '*Slaps Roof of Car*',
        effectText = 'You can discard 1 \'Larrys Car Lot\' from your hand. This card gains that effect for 3 turns. "If you draw a \'Vehicle\' card. You can draw 1 more card."',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN091',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN091_ERIC_COLEMAN.png'
    },

    ['ALPH1_EN092_COLEMANS_CAR_LOT'] = {
        id = 'ALPH1_EN092_COLEMANS_CAR_LOT',
        name = 'Colemans Car Lot',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Caryard',
        effectText = 'If you draw a \'Vehicle\' card. You can draw 1 more card.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN092',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN092_COLEMANS_CAR_LOT.png'
    },

    ['ALPH1_EN093_KENZIE_HALL'] = {
        id = 'ALPH1_EN093_KENZIE_HALL',
        name = 'Kenzie Hall',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '2',
        attack = '20',
        defense = '40',
        effectTitle = 'Best Friends',
        effectText = 'On summon apply +20 HP to a chosen fighter on the field.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_summon', 'stat_modifier', 'target' },
        effects = {
        {
        trigger = 'on_summon',
        tags = { 'stat_modifier', 'target' },
        actions = {
        {
        action = 'select_modify_stats',
        target = 'self',
        promptText = 'Choose 1 fighter to gain +20 HP.',
        filter = { type = 'Fighter' },
        stats = { hp = 20 }
        }
        }
        }
        },
        setCode = 'ALPH1-EN093',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN093_KENZIE_HALL.png'
    },

    ['ALPH1_EN094_KENZIE_HALL'] = {
        id = 'ALPH1_EN094_KENZIE_HALL',
        name = 'Kenzie Hall',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'UWU Cafe Owner',
        level = 'level 2',
        speed = '4',
        attack = '30',
        defense = '40',
        effectTitle = 'The Mother of UWU',
        effectText = 'If an \'Alan Hall\' fighter you control is destroyed by battle, inflict damage to your opponent equal to the attacking fighters attack.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN094',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN094_KENZIE_HALL.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN095',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN095_CHADWICK_SLAMMER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN096',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN096_XAVIER_WU.png'
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
        effectText = 'Once per turn you can place 1 \'Sticky Bomb\' counter on each of your opponents fighters. You can remove all \'sticky bomb\' counters from all cards, dealing -30HP for each counter. You cannot detonate sticky bombs the turn you place them.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'counter', 'damage', 'once_per_turn' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        oncePerTurn = true,
        oncePerTurnKey = 'place_sticky_bombs',
        promptText = 'Place 1 Sticky Bomb counter on each opponent fighter?',
        tags = { 'counter' },
        actions = {
        { action = 'add_counter_to_opponent_fighters', counter = 'Sticky Bomb', amount = 1 }
        }
        },
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        oncePerTurn = true,
        oncePerTurnKey = 'detonate_sticky_bombs',
        promptText = 'Detonate all Sticky Bomb counters?',
        tags = { 'counter', 'damage' },
        actions = {
        { action = 'detonate_sticky_bomb_counters', counter = 'Sticky Bomb', damagePerCounter = 30 }
        }
        }
        },
        setCode = 'ALPH1-EN097',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN097_LOGAN_BANDIT_DAWSON.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN098',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN098_KITT_REED_WU.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN099',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN099_SPARTAN_ARSENAL.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN100',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN100_GUN_BENCH.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN101',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN101_MARINE_BEACH_RECYCLING.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN102',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN102_AMMO_SOUTH.png'
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
        cardTags = { 'Contraband' },
        legality = '',
        maxCopiesPerFighter = 2,
        effectTags = { 'continuous', 'weapon', 'equip_restriction' },
        effects = {
        {
        continuous = true,
        tags = { 'weapon', 'equip_restriction' },
        actions = {}
        }
        },
        setCode = 'ALPH1-EN103',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN103_SMG.png'
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
        cardTags = { 'Contraband' },
        legality = '',
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
        setCode = 'ALPH1-EN104',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN104_COMBAT_PDW.png'
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
        effectTitle = 'Exclusive',
        effectText = 'You can only have 1 of this card on the field at a time.',
        cardTags = {},
        legality = '',
        uniqueOnControllerField = true,
        effectTags = { 'continuous', 'equip_restriction', 'vehicle', 'unique' },
        effects = {
        {
        continuous = true,
        tags = { 'equip_restriction', 'vehicle', 'unique' },
        actions = {}
        }
        },
        setCode = 'ALPH1-EN105',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN105_PFISTER_COMET_CTX.png'
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
        cardTags = { 'Police' },
        legality = '',
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
        setCode = 'ALPH1-EN106',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN106_SPIKE_STRIP.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN107',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN107_FUEL_SHORTAGE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN108',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN108_HOUSE_ROBBERY.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN109',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN109_PALETO_HEIST.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN110',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN110_BANK_CARD.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN111',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN111_POLICE_CHASE.png'
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
        cardTags = { 'Contraband' },
        legality = '',
        effectTags = { 'continuous', 'piercing', 'weapon' },
        effects = {
        {
        continuous = true,
        tags = { 'piercing', 'weapon' },
        actions = {}
        }
        },
        setCode = 'ALPH1-EN112',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN112_DRACO.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN113',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN113_SOSMC_CLUBHOUSE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN114',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN114_ELI_MALLORY.png'
    },

    ['ALPH1_EN115_KIN_RODINE'] = {
        id = 'ALPH1_EN115_KIN_RODINE',
        name = 'Kin Rodine',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '4',
        attack = '30',
        defense = '60',
        effectTitle = '',
        effectText = 'If your LP is lower than your opponents, this cards ATK becomes equal to half of the difference (rounded up) until the end of your opponents next turn.',
        cardTags = {},
        legality = '',
        effectTags = { 'activated', 'stat_modifier', 'lp_difference' },
        effects = {
        {
        trigger = 'activated',
        activationZones = { 'fighterZone' },
        tags = { 'stat_modifier', 'lp_difference' },
        optional = true,
        condition = { ownLpLowerThanOpponent = true },
        promptText = 'Set this card\'s ATK to half the LP difference until the end of your opponent\'s next turn?',
        actions = {
        { action = 'set_attack_to_half_lp_difference', duration = 'turn' }
        }
        }
        },
        setCode = 'ALPH1-EN115',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN115_KIN_RODINE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN116',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN116_CLYDE_RILEY_JR.png'
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
        cardTags = { 'Contraband', 'drug' },
        legality = '',
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
        setCode = 'ALPH1-EN117',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN117_OXYCODONE.png'
    },

    ['ALPH1_EN118_HAKOUCHOU_DRAG'] = {
        id = 'ALPH1_EN118_HAKOUCHOU_DRAG',
        name = 'Hakouchou Drag',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = 'SPD +6',
        attack = '',
        defense = '',
        effectTitle = 'Deathtrap',
        effectText = 'On each of your main phase, roll a D6, if you roll a 1 or 6, destroy this card and the equipped fighter takes -20 HP damage.',
        cardTags = {},
        legality = '',
        effectTags = { 'main_phase_start', 'dice_roll', 'destroy', 'stat_modifier' },
        effects = {
        {
        trigger = 'main_phase_start',
        tags = { 'dice_roll', 'destroy', 'stat_modifier' },
        actions = {
        { action = 'roll_destroy_self_damage_equipped', sides = 6, hitValues = { 1, 6 }, damage = 20 }
        }
        }
        },
        setCode = 'ALPH1-EN118',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN118_HAKOUCHOU_DRAG.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN119',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN119_SKATEBOARD.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN120',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN120_OUTFIT_BAG.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN121',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN121_XP_POTION.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN122',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN122_AIR_FRESHENER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN123',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN123_IFAKS.png'
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
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Body\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN124',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN124_SNS_CLIP.png'
    },

    ['ALPH1_EN125_CHEVAL_FUGITIVE'] = {
        id = 'ALPH1_EN125_CHEVAL_FUGITIVE',
        name = 'Cheval Fugitive',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +4',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Each turn during the end phase, reduce the speed of this card by -1 until it becomes 1.',
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN125',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN125_CHEVAL_FUGITIVE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN126',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN126_BRAVADO_BISON.png'
    },

    ['ALPH1_EN127_POLICE_BUFFALO_STX_HELLFIRE'] = {
        id = 'ALPH1_EN127_POLICE_BUFFALO_STX_HELLFIRE',
        name = 'Police Buffalo STX Hellfire',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = 'SPD +6',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If equipped to an LEO card, it gains +2 SPD and +30 HP.',
        cardTags = { 'Police' },
        legality = '',
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
        setCode = 'ALPH1-EN127',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN127_POLICE_BUFFALO_STX_HELLFIRE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN128',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN128_DOOBIE.png'
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
        cardTags = { 'Vehicle Upgrade' },
        legality = '',
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
        setCode = 'ALPH1-EN129',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN129_STAGE_3_BRAKES.png'
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
        cardTags = { 'Vehicle Upgrade' },
        legality = '',
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
        setCode = 'ALPH1-EN130',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN130_STAGE_4_ENGINE.png'
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
        cardTags = { 'Vehicle Upgrade' },
        legality = '',
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
        setCode = 'ALPH1-EN131',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN131_STAGE_4_SUSPENSION.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN132',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN132_SAINT_ROSES_CHURCH.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN133',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN133_WADE_WOLSON.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN134',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN134_DAILY_SPIN.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN135',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN135_BAILEY_BLEWITT.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN136',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN136_EXTENDED_CLIP.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN137',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN137_SNS_TRIGGER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN138',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN138_SNS_LOOP.png'
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
        cardTags = {},
        legality = '',
        setCode = 'ALPH1-EN139',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN139_SNS_PISTOL.png'
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
        cardTags = {},
        legality = 'Limited',
        setCode = 'ALPH1-EN140',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN140_RIGHT_ARM_OF_THE_LIGHTBRINGER.png'
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
        cardTags = {},
        legality = 'Limited',
        setCode = 'ALPH1-EN141',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN141_LEFT_ARM_OF_THE_LIGHTBRINGER.png'
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
        cardTags = {},
        legality = 'Limited',
        setCode = 'ALPH1-EN142',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN142_LEFT_LEG_OF_THE_LIGHTBRINGER.png'
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
        cardTags = {},
        legality = 'Limited',
        setCode = 'ALPH1-EN143',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN143_RIGHT_LEG_OF_THE_LIGHTBRINGER.png'
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
        cardTags = {},
        legality = 'Limited',
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
        setCode = 'ALPH1-EN144',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN144_LUCIAN_LIGHTBRINGER.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN145',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN145_PILLBOX_HOSPITAL.png'
    },

    ['ALPH1_EN146_KIRI_RILEY'] = {
        id = 'ALPH1_EN146_KIRI_RILEY',
        name = 'Kiri Riley',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '3',
        attack = '30',
        defense = '50',
        effectTitle = 'EFFECT',
        effectText = 'On summon you can also special summon 1 \'Terrance Redfield Riley\' from your deck or cemetary.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_summon', 'special_summon' },
        effects = {
        {
        trigger = 'on_summon',
        optional = true,
        promptText = 'Do you want to special summon 1 Terrance Redfield Riley from your deck or cemetery?',
        tags = { 'special_summon' },
        actions = {
        { action = 'special_summon_from_deck_or_graveyard', filter = { type = 'Fighter', nameContains = 'Terrance Redfield Riley' } }
        }
        }
        },
        setCode = 'ALPH1-EN146',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN146_KIRI_RILEY.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN147',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN147_BANK_LOAN.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN148',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN148_ALAN_HALL.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN149',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN149_BLOOD_DONATION.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN150',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN150_AMBULANCE.png'
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
        cardTags = {},
        legality = '',
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
        setCode = 'ALPH1-EN151',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN151_POLYMORPH_POTION.png'
    },

    ['INK1_EN001_PATTY_THE_OWL'] = {
        id = 'INK1_EN001_PATTY_THE_OWL',
        name = 'Patty the Owl',
        rarity = 'ULTRA',
        type = 'Item',
        job = '',
        level = '',
        speed = '4',
        attack = '10',
        defense = '50',
        effectTitle = 'Knowledge',
        effectText = 'Discard this card, you can choose 1 card in your opponents hand at random, your opponent must reveal it.',
        cardTags = { 'Ash and Ink' },
        legality = '',
        effectTags = { 'on_play', 'discard', 'reveal', 'hand_disruption' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'discard', 'reveal', 'hand_disruption' },
        actions = {
        { action = 'reveal_random_opponent_hand_card' }
        }
        }
        },
        setCode = 'INK1-EN001',
        edition = 'Limited Edition',
        inventoryImage = 'INK1-EN001_PATTY_THE_OWL.png'
    },

    ['INK1_EN002_FINNAGEN_SKYTECH'] = {
        id = 'INK1_EN002_FINNAGEN_SKYTECH',
        name = 'Finnagen Skytech',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Archivist',
        level = 'Level 1',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = '',
        effectText = '',
        cardTags = {},
        legality = '',
        setCode = 'INK1-EN002',
        edition = 'Limited Edition',
        inventoryImage = 'INK1-EN002_FINNAGEN_SKYTECH.png'
    },

    ['INK1_EN003_EXPEDITION_MAP'] = {
        id = 'INK1_EN003_EXPEDITION_MAP',
        name = 'Expedition Map',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'X Marks the Spot',
        effectText = 'Look at the top 3 cards of your deck, put them back on the top in your chosen order, then draw 1 card.',
        cardTags = { 'Ash and Ink' },
        legality = '',
        effectTags = { 'on_play', 'deck_order', 'draw' },
        effects = {
            {
                trigger = 'on_play',
                tags = { 'deck_order', 'draw' },
                actions = {
                    { action = 'select_reorder_top_deck_then_draw', count = 3, thenDraw = 1 }
                }
            }
        },
        setCode = 'INK1-EN003',
        edition = 'Limited Edition',
        inventoryImage = 'INK1-EN003_EXPEDITION_MAP.png'
    },

    ['INK1_EN004_PHOTOCOPIER'] = {
        id = 'INK1_EN004_PHOTOCOPIER',
        name = 'Photocopier',
        rarity = 'SUPER',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Photocopy!',
        effectText = 'Target 1 Level 1 fighter with less than 30 ATK that you control, special summon another copy from the deck.',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'special_summon', 'same_name', 'target' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'special_summon', 'same_name', 'target' },
        actions = {
        {
        action = 'select_special_summon_same_name_from_deck',
        promptText = 'Choose 1 Level 1 fighter with less than 30 ATK to copy from your deck.',
        filter = { type = 'Fighter', level = 1, attackMax = 29 }
        }
        }
        }
        },
        setCode = 'INK1-EN004',
        edition = 'Limited Edition',
        inventoryImage = 'INK1-EN004_PHOTOCOPIER.png'
    },

    ['INK1_EN005'] = {
        id = 'INK1_EN005',
        name = '',
        rarity = 'SUPER',
        type = '',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = '',
        effectText = '',
        cardTags = {},
        legality = '',
        setCode = 'INK1-EN005',
        edition = 'Limited Edition',
        inventoryImage = 'INK1-EN005.png'
    },

    ['PROM1_EN001_HARDCORE_COMICS'] = {
        id = 'PROM1_EN001_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN001',
        edition = 'Limited 1/10',
        inventoryImage = 'PROM1-EN001_HARDCORE_COMICS.png'
    },

    ['PROM1_EN002_HARDCORE_COMICS'] = {
        id = 'PROM1_EN002_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN002',
        edition = 'Limited 2/10',
        inventoryImage = 'PROM1-EN002_HARDCORE_COMICS.png'
    },

    ['PROM1_EN003_HARDCORE_COMICS'] = {
        id = 'PROM1_EN003_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN003',
        edition = 'Limited 3/10',
        inventoryImage = 'PROM1-EN003_HARDCORE_COMICS.png'
    },

    ['PROM1_EN004_HARDCORE_COMICS'] = {
        id = 'PROM1_EN004_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN004',
        edition = 'Limited 4/10',
        inventoryImage = 'PROM1-EN004_HARDCORE_COMICS.png'
    },

    ['PROM1_EN005_HARDCORE_COMICS'] = {
        id = 'PROM1_EN005_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN005',
        edition = 'Limited 5/10',
        inventoryImage = 'PROM1-EN005_HARDCORE_COMICS.png'
    },

    ['PROM1_EN006_HARDCORE_COMICS'] = {
        id = 'PROM1_EN006_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN006',
        edition = 'Limited 6/10',
        inventoryImage = 'PROM1-EN006_HARDCORE_COMICS.png'
    },

    ['PROM1_EN007_HARDCORE_COMICS'] = {
        id = 'PROM1_EN007_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN007',
        edition = 'Limited 7/10',
        inventoryImage = 'PROM1-EN007_HARDCORE_COMICS.png'
    },

    ['PROM1_EN008_HARDCORE_COMICS'] = {
        id = 'PROM1_EN008_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN008',
        edition = 'Limited 8/10',
        inventoryImage = 'PROM1-EN008_HARDCORE_COMICS.png'
    },

    ['PROM1_EN009_HARDCORE_COMICS'] = {
        id = 'PROM1_EN009_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN009',
        edition = 'Limited 9/10',
        inventoryImage = 'PROM1-EN009_HARDCORE_COMICS.png'
    },

    ['PROM1_EN010_HARDCORE_COMICS'] = {
        id = 'PROM1_EN010_HARDCORE_COMICS',
        name = 'Hardcore Comics',
        rarity = 'Unique',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Ooooooh! Shiney!!',
        effectText = 'Gain +20 LP for each \'Ultra Rare\' and above card you play to the field. (ultra rare, secret rare, ghost rare, mythic rare).',
        cardTags = {},
        legality = '',
        effectTags = { 'on_play', 'gain_lp', 'rarity' },
        effects = {
        {
        trigger = 'on_play',
        tags = { 'gain_lp', 'rarity' },
        condition = { playedRarityAtLeast = 'Ultra Rare' },
        actions = {
        { action = 'gain_lp', target = 'self', amount = 20 }
        }
        }
        },
        setCode = 'PROM1-EN010',
        edition = 'Limited 10/10',
        inventoryImage = 'PROM1-EN010_HARDCORE_COMICS.png'
    }
}
