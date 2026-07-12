Cards = {
    ['ALPH1_EN001_LAYLA_HART'] = {
        id = 'ALPH1_EN001_LAYLA_HART',
        name = 'Layla Hart',
        rarity = 'SECRET',
        type = 'Fighter',
        job = 'SOSMC Treasurer',
        level = 'LEVEL 2',
        speed = '3',
        attack = '40',
        defense = '100',
        effectTitle = 'MOVING FUNDS',
        effectText = 'You can pay up to 300LP, then choose one of these effects: 1) This card gains half that value in ATK. 2) This card gains half that value in HP. 3) Your opponent loses half that value in LP.',
        effectTags = { 'activated', 'choice_required', 'lose_lp', 'stat_modifier', 'damage_lp' },
        effects = {
            {
                trigger = 'activated',
                tags = { 'lose_lp', 'choice_required', 'stat_modifier', 'damage_lp', 'once_per_game' },
                oncePerGame = true,
                promptText = 'Pay up to 300 LP, then choose one effect.',
                form = {
                    number = { key = 'paidLp', label = 'LP to pay', min = 0, max = 300, default = 300, maxLifePoints = true },
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
                            { action = 'lose_lp', amount = { fromResponse = 'paidLp', min = 0, max = 300 } },
                            { action = 'modify_stats', stats = { attack = { fromResponse = 'paidLp', multiplier = 0.5, round = 'floor' } } }
                        }
                    },
                    {
                        id = 'gain_hp',
                        actions = {
                            { action = 'lose_lp', amount = { fromResponse = 'paidLp', min = 0, max = 300 } },
                            { action = 'modify_stats', stats = { hp = { fromResponse = 'paidLp', multiplier = 0.5, round = 'floor' } } }
                        }
                    },
                    {
                        id = 'damage_lp',
                        actions = {
                            { action = 'lose_lp', amount = { fromResponse = 'paidLp', min = 0, max = 300 } },
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
        effectText = 'On summon, you can lose 300 LP and draw 2 cards.',
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
        defense = '60',
        effectTitle = 'EFFECT',
        effectText = 'When this card is summoned, add 1 \'SAFR\' fighter from your deck. \'SAFR\' cards you control cannot be destroyed by card effects. This card is unaffected by burn effects.',
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
        job = 'Mirror Park Auto Owner',
        level = 'LEVEL 2',
        speed = '4',
        attack = '30',
        defense = '50',
        effectTitle = 'EFFECT',
        effectText = "Add 1 'Riley's Performance' card from your deck.",
        effectTags = { 'on_summon', 'search_deck' },
        effects = {
            {
                trigger = 'on_summon',
                tags = { 'search_deck' },
                actions = {
                    {
                        action = 'search_deck_to_hand',
                        choose = true,
                        promptText = "Choose 1 Riley's Performance card to add to your hand.",
                        filter = { nameContains = "Riley's Performance" }
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
        effectText = 'OPT: You can return this card to your hand and SP summon 1 \'Cougar\' from your deck. If you control \'Cougar\' you can tribute that card and SP summon this card from the hand or cemetery.',
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
        effectText = 'Equip 1 Vehicle card from your deck to a fighter on the field.',
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
        effectText = 'Add any Location card from your deck.',
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
        effectText = 'If you control 2 or more vehicle cards, revive 1 fighter from your cemetery. If you control less than 2, you can add 1 \'bandage\' card from your deck to your hand.',
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
        setCode = 'ALPH1-EN012',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN012_COUGAR.png'
    },

    ['ALPH1_EN013_LAYLA_HART'] = {
        id = 'ALPH1_EN013_LAYLA_HART',
        name = 'Layla Hart',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Hardcore Comics owner',
        level = 'LEVEL 1',
        speed = '4',
        attack = '30',
        defense = '50',
        effectTitle = 'YOUR PACK IS IN THE TRAY!',
        effectText = 'You can banish this card from your cemetery to draw 3 cards, then discard 1.',
        setCode = 'ALPH1-EN013',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN013_LAYLA_HART.png'
    },

    ['ALPH1_EN014_ZACK_GATOR'] = {
        id = 'ALPH1_EN014_ZACK_GATOR',
        name = 'Zack Gator',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'USFW',
        level = 'LEVEL 1',
        speed = '3',
        attack = '30',
        defense = '40',
        effectTitle = 'HE PROTECC',
        effectText = 'All animal cards you control gain +30 HP.',
        setCode = 'ALPH1-EN014',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN014_ZACK_GATOR.png'
    },

    ['ALPH1_EN015_HAYES_TOWING'] = {
        id = 'ALPH1_EN015_HAYES_TOWING',
        name = 'Hayes Towing',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = 'LEVEL 1',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Once per turn, take control of one of your opponents vehicle cards. You opponent can sacrafice 1 card they control to get their vehicle card back in their control. If you cannot control any more vehicles, destroy this card.',
        setCode = 'ALPH1-EN015',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN015_HAYES_TOWING.png'
    },

    ['ALPH1_EN016_KENCHIE'] = {
        id = 'ALPH1_EN016_KENCHIE',
        name = 'Kenchie',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'Wizard',
        level = 'LEVEL 1',
        speed = '3',
        attack = '50',
        defense = '60',
        effectTitle = 'ABRA KADABUNNY?',
        effectText = 'Target 1 \'Fighter\' card, send it to the cemetary and SP summon 1 \'animal\' card in its place.',
        setCode = 'ALPH1-EN016',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN016_KENCHIE.png'
    },

    ['ALPH1_EN017_ICEMAN_HERNANDEZ'] = {
        id = 'ALPH1_EN017_ICEMAN_HERNANDEZ',
        name = 'Iceman Hernandez',
        rarity = 'SUPER',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '3',
        attack = '30',
        defense = '40',
        effectTitle = 'YOU\'RE HIRED!',
        effectText = 'Add 1 level 2 or higher card from your deck.',
        setCode = 'ALPH1-EN017',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN017_ICEMAN_HERNANDEZ.png'
    },

    ['ALPH1_EN018_NIKOLAS_HAAJA'] = {
        id = 'ALPH1_EN018_NIKOLAS_HAAJA',
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
        setCode = 'ALPH1-EN018',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN018_NIKOLAS_HAAJA.png'
    },

    ['ALPH1_EN019_MAX_TURNER_MIRANOVA'] = {
        id = 'ALPH1_EN019_MAX_TURNER_MIRANOVA',
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
        setCode = 'ALPH1-EN019',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN019_MAX_TURNER_MIRANOVA.png'
    },

    ['ALPH1_EN020_WYATT_RAYNE'] = {
        id = 'ALPH1_EN020_WYATT_RAYNE',
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
        setCode = 'ALPH1-EN020',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN020_WYATT_RAYNE.png'
    },

    ['ALPH1_EN021_JAY_MOZZY'] = {
        id = 'ALPH1_EN021_JAY_MOZZY',
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
        setCode = 'ALPH1-EN021',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN021_JAY_MOZZY.png'
    },

    ['ALPH1_EN022_XENA_MIRANOVA'] = {
        id = 'ALPH1_EN022_XENA_MIRANOVA',
        name = 'Xena Miranova',
        rarity = 'SECRET',
        type = 'Fighter',
        job = 'Chief EMS',
        level = 'LEVEL 2',
        speed = '4',
        attack = '20',
        defense = '60',
        effectTitle = '5MG OF MORPHINE STAT!',
        effectText = 'Each time an item card is used, place 1 \'Healing\' token on this card. You can remove 3 \'Healing\' tokens to restore 1 fighters HP to its base value.',
        setCode = 'ALPH1-EN022',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN022_XENA_MIRANOVA.png'
    },

    ['ALPH1_EN023_JAY_MOZZY'] = {
        id = 'ALPH1_EN023_JAY_MOZZY',
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
        setCode = 'ALPH1-EN023',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN023_JAY_MOZZY.png'
    },

    ['ALPH1_EN024_BANDAGE'] = {
        id = 'ALPH1_EN024_BANDAGE',
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
        effectTags = { 'on_play', 'heal', 'coin_flip' },
        effects = {
            {
                trigger = 'on_play',
                tags = { 'heal' },
                actions = {
                    { action = 'heal_all_fighters', target = 'self', amount = 30 }
                }
            }
        },
        setCode = 'ALPH1-EN024',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN024_BANDAGE.png'
    },

    ['ALPH1_EN025_BROCK_LEE'] = {
        id = 'ALPH1_EN025_BROCK_LEE',
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
        setCode = 'ALPH1-EN025',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN025_BROCK_LEE.png'
    },

    ['ALPH1_EN026_WULFRIK_CHAOSBANE'] = {
        id = 'ALPH1_EN026_WULFRIK_CHAOSBANE',
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
        setCode = 'ALPH1-EN026',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN026_WULFRIK_CHAOSBANE.png'
    },

    ['ALPH1_EN027_CROW'] = {
        id = 'ALPH1_EN027_CROW',
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
        setCode = 'ALPH1-EN027',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN027_CROW.png'
    },

    ['ALPH1_EN028_BOB_HODGES'] = {
        id = 'ALPH1_EN028_BOB_HODGES',
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
        setCode = 'ALPH1-EN028',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN028_BOB_HODGES.png'
    },

    ['ALPH1_EN029_BOB_HODGES'] = {
        id = 'ALPH1_EN029_BOB_HODGES',
        name = 'Bob Hodges',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'BCSO',
        level = 'LEVEL 2',
        speed = '2',
        attack = '30',
        defense = '60',
        effectTitle = 'BUSH IMMUNITY',
        effectText = 'If you control a \'Bobs Bush\' card, this card cannot be targeted by opponents card effects.',
        setCode = 'ALPH1-EN029',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN029_BOB_HODGES.png'
    },

    ['ALPH1_EN030_YUKA_KASEN'] = {
        id = 'ALPH1_EN030_YUKA_KASEN',
        name = 'Yuka Kasen',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Diamond Casino Manager',
        level = 'LEVEL 1',
        speed = '5',
        attack = '40',
        defense = '50',
        effectTitle = 'DON\'T TEST ME',
        effectText = 'Roll a 6 sided dice, if 3 or higher, destroy 1 of your opponents cards. If you roll a 1, destroy one of your own cards.',
        setCode = 'ALPH1-EN030',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN030_YUKA_KASEN.png'
    },

    ['ALPH1_EN031_SEN_GANBE'] = {
        id = 'ALPH1_EN031_SEN_GANBE',
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
        setCode = 'ALPH1-EN031',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN031_SEN_GANBE.png'
    },

    ['ALPH1_EN032_HIROSHI_YAMATO'] = {
        id = 'ALPH1_EN032_HIROSHI_YAMATO',
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
        setCode = 'ALPH1-EN032',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN032_HIROSHI_YAMATO.png'
    },

    ['ALPH1_EN033_HAO_YAMATO'] = {
        id = 'ALPH1_EN033_HAO_YAMATO',
        name = 'Hao Yamato',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Diamond Casino Director',
        level = 'LEVEL 2',
        speed = '4',
        attack = '30',
        defense = '70',
        effectTitle = 'ORGANISE',
        effectText = 'Add 1 \'Casino\' card to your hand.',
        setCode = 'ALPH1-EN033',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN033_HAO_YAMATO.png'
    },

    ['ALPH1_EN034_PADDY_SOULJA'] = {
        id = 'ALPH1_EN034_PADDY_SOULJA',
        name = 'Paddy Soulja',
        rarity = 'RARE',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '2',
        attack = '40',
        defense = '30',
        effectTitle = 'HAZE DER U NO',
        effectText = 'This card gains +20 HP for every \'Weed\' card in your cemetery.',
        setCode = 'ALPH1-EN034',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN034_PADDY_SOULJA.png'
    },

    ['ALPH1_EN035_BRADLEY_BK_KRAY'] = {
        id = 'ALPH1_EN035_BRADLEY_BK_KRAY',
        name = 'Bradley \'BK\' Kray',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'LEVEL 1',
        speed = '4',
        attack = '30',
        defense = '20',
        effectTitle = 'M.I.C.K.E.Y',
        effectText = 'Your opponent must do a mickey mouse impression, otherwise you gain +30 LP.',
        setCode = 'ALPH1-EN035',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN035_BRADLEY_\'BK\'_KRAY.png'
    },

    ['ALPH1_EN036_LUKE_TAYLOR'] = {
        id = 'ALPH1_EN036_LUKE_TAYLOR',
        name = 'Luke Taylor',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Taylor\'s Ranch Owner',
        level = 'LEVEL 1',
        speed = '4',
        attack = '50',
        defense = '40',
        effectTitle = 'HARVEST',
        effectText = 'Send any plant or animal card to the cemetary, after 2 turns add any item card from your deck.',
        setCode = 'ALPH1-EN036',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN036_LUKE_TAYLOR.png'
    },

    ['ALPH1_EN037_KENCHIE_DAWSON'] = {
        id = 'ALPH1_EN037_KENCHIE_DAWSON',
        name = 'Kenchie Dawson',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Weazel News',
        level = 'LEVEL 2',
        speed = '5',
        attack = '30',
        defense = '30',
        effectTitle = 'THIS JUST IN!',
        effectText = 'Target 1 of your opponents fighters. This card gains the effect of the card you targeted for this turn.',
        setCode = 'ALPH1-EN037',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN037_KENCHIE_DAWSON.png'
    },

    ['ALPH1_EN038_MATTEO_PIAZZA'] = {
        id = 'ALPH1_EN038_MATTEO_PIAZZA',
        name = 'Matteo Piazza',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'LSC Mechanic',
        level = 'LEVEL 2',
        speed = '4',
        attack = '40',
        defense = '40',
        effectTitle = 'Los Snail Customs',
        effectText = 'Add any \'Vehicle Upgrade\' card to your hand. This card then loses -2 SPD.',
        setCode = 'ALPH1-EN038',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN038_MATTEO_PIAZZA.png'
    },

    ['ALPH1_EN039_MATT_JACKSON'] = {
        id = 'ALPH1_EN039_MATT_JACKSON',
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
        setCode = 'ALPH1-EN039',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN039_MATT_JACKSON.png'
    },

    ['ALPH1_EN040_AMNESTY'] = {
        id = 'ALPH1_EN040_AMNESTY',
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
        setCode = 'ALPH1-EN040',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN040_AMNESTY.png'
    },

    ['ALPH1_EN041_LEPRECHAUN_MISCHIEF_2026'] = {
        id = 'ALPH1_EN041_LEPRECHAUN_MISCHIEF_2026',
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
        setCode = 'ALPH1-EN041',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN041_LEPRECHAUN_MISCHIEF_2026.png'
    },

    ['ALPH1_EN042_HEADPOP'] = {
        id = 'ALPH1_EN042_HEADPOP',
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
        setCode = 'ALPH1-EN042',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN042_HEADPOP.png'
    },

    ['ALPH1_EN043_MASS_HEADPOP'] = {
        id = 'ALPH1_EN043_MASS_HEADPOP',
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
        setCode = 'ALPH1-EN043',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN043_MASS_HEADPOP.png'
    },

    ['ALPH1_EN044_VACATION_TO_BAHAMAS'] = {
        id = 'ALPH1_EN044_VACATION_TO_BAHAMAS',
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
        setCode = 'ALPH1-EN044',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN044_VACATION_TO_BAHAMAS.png'
    },

    ['ALPH1_EN045_PINK_GRAPPLE_GUN'] = {
        id = 'ALPH1_EN045_PINK_GRAPPLE_GUN',
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
        setCode = 'ALPH1-EN045',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN045_PINK_GRAPPLE_GUN.png'
    },

    ['ALPH1_EN046_AED'] = {
        id = 'ALPH1_EN046_AED',
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
        setCode = 'ALPH1-EN046',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN046_AED.png'
    },

    ['ALPH1_EN047_BLUE_METH'] = {
        id = 'ALPH1_EN047_BLUE_METH',
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
        setCode = 'ALPH1-EN047',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN047_BLUE_METH.png'
    },

    ['ALPH1_EN048_METH'] = {
        id = 'ALPH1_EN048_METH',
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
        setCode = 'ALPH1-EN048',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN048_METH.png'
    },

    ['ALPH1_EN049_FENANYL'] = {
        id = 'ALPH1_EN049_FENANYL',
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
        setCode = 'ALPH1-EN049',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN049_FENANYL.png'
    },

    ['ALPH1_EN050_HEROINE'] = {
        id = 'ALPH1_EN050_HEROINE',
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
        setCode = 'ALPH1-EN050',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN050_HEROINE.png'
    },

    ['ALPH1_EN051_HANDCUFFS'] = {
        id = 'ALPH1_EN051_HANDCUFFS',
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
        setCode = 'ALPH1-EN051',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN051_HANDCUFFS.png'
    },

    ['ALPH1_EN052_TASER'] = {
        id = 'ALPH1_EN052_TASER',
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
        setCode = 'ALPH1-EN052',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN052_TASER.png'
    },

    ['ALPH1_EN053_LOCKPICK'] = {
        id = 'ALPH1_EN053_LOCKPICK',
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
        setCode = 'ALPH1-EN053',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN053_LOCKPICK.png'
    },

    ['ALPH1_EN054_MAX_SLAYTER'] = {
        id = 'ALPH1_EN054_MAX_SLAYTER',
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
        setCode = 'ALPH1-EN054',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN054_MAX_SLAYTER.png'
    },

    ['ALPH1_EN055_CASPER_CORTEZ'] = {
        id = 'ALPH1_EN055_CASPER_CORTEZ',
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
        setCode = 'ALPH1-EN055',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN055_CASPER_CORTEZ.png'
    },

    ['ALPH1_EN056_TURBO'] = {
        id = 'ALPH1_EN056_TURBO',
        name = 'Turbo',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = 'x2',
        attack = '',
        defense = '',
        effectTitle = 'STUTUTU',
        effectText = 'This card lasts for 3 turns before being destroyed.',
        setCode = 'ALPH1-EN056',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN056_TURBO.png'
    },

    ['ALPH1_EN057_TRANSMISSION_STAGE_4'] = {
        id = 'ALPH1_EN057_TRANSMISSION_STAGE_4',
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
        setCode = 'ALPH1-EN057',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN057_TRANSMISSION_STAGE_4.png'
    },

    ['ALPH1_EN058_DUMPSTER'] = {
        id = 'ALPH1_EN058_DUMPSTER',
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
        setCode = 'ALPH1-EN058',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN058_DUMPSTER.png'
    },

    ['ALPH1_EN059_BACKPACK'] = {
        id = 'ALPH1_EN059_BACKPACK',
        name = 'Backpack',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Increase your backrow slots by +1.',
        setCode = 'ALPH1-EN059',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN059_BACKPACK.png'
    },

    ['ALPH1_EN060_TWITCHY_WABBIT'] = {
        id = 'ALPH1_EN060_TWITCHY_WABBIT',
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
        setCode = 'ALPH1-EN060',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN060_TWITCHY_WABBIT.png'
    },

    ['ALPH1_EN061_INSIGHTFUL'] = {
        id = 'ALPH1_EN061_INSIGHTFUL',
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
        setCode = 'ALPH1-EN061',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN061_INSIGHTFUL.png'
    },

    ['ALPH1_EN062_HOSTAGE_DEMANDS'] = {
        id = 'ALPH1_EN062_HOSTAGE_DEMANDS',
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
        setCode = 'ALPH1-EN062',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN062_HOSTAGE_DEMANDS.png'
    },

    ['ALPH1_EN063_CASINO_LUCKY_WHEEL'] = {
        id = 'ALPH1_EN063_CASINO_LUCKY_WHEEL',
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
        setCode = 'ALPH1-EN063',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN063_CASINO_LUCKY_WHEEL.png'
    },

    ['ALPH1_EN064_FIREHOUSE'] = {
        id = 'ALPH1_EN064_FIREHOUSE',
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
        setCode = 'ALPH1-EN064',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN064_FIREHOUSE.png'
    },

    ['ALPH1_EN065_RILEY_S_PERFORMANCE'] = {
        id = 'ALPH1_EN065_RILEY_S_PERFORMANCE',
        name = 'Riley\'s Performance',
        rarity = 'COMMON',
        type = 'Location',
        job = 'Mirror Park Location',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Performance Upgrade',
        effectText = 'Add 1 \'Vehicle Upgrade\' card to your hand.',
        setCode = 'ALPH1-EN065',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN065_RILEY\'S_PERFORMANCE.png'
    },

    ['ALPH1_EN066_TROOPER_STATION'] = {
        id = 'ALPH1_EN066_TROOPER_STATION',
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
        setCode = 'ALPH1-EN066',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN066_TROOPER_STATION.png'
    },

    ['ALPH1_EN067_BOB_S_BUSH'] = {
        id = 'ALPH1_EN067_BOB_S_BUSH',
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
        setCode = 'ALPH1-EN067',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN067_BOB\'S_BUSH.png'
    },

    ['ALPH1_EN068_BRAVADO_BUFFALO_STX'] = {
        id = 'ALPH1_EN068_BRAVADO_BUFFALO_STX',
        name = 'Bravado Buffalo STX',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+4',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = '',
        setCode = 'ALPH1-EN068',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN068_BRAVADO_BUFFALO_STX.png'
    },

    ['ALPH1_EN069_ALEUTIAN'] = {
        id = 'ALPH1_EN069_ALEUTIAN',
        name = 'Aleutian',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+3',
        attack = '',
        defense = '',
        effectTitle = 'Rapid Response',
        effectText = 'If this card is equipped to a \'SAMS\' fighter, increase SPD by another +2.',
        setCode = 'ALPH1-EN069',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN069_ALEUTIAN.png'
    },

    ['ALPH1_EN070_GREEN_PANTO'] = {
        id = 'ALPH1_EN070_GREEN_PANTO',
        name = 'Green Panto',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+1',
        attack = '',
        defense = '',
        effectTitle = 'They\'re Everywhere!',
        effectText = 'When this card is sent to the cemetery, you can add 1 \'Green Panto\' card from your deck.',
        setCode = 'ALPH1-EN070',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN070_GREEN_PANTO.png'
    },

    ['ALPH1_EN071_RUSTY_REBEL'] = {
        id = 'ALPH1_EN071_RUSTY_REBEL',
        name = 'Rusty Rebel',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '-1',
        attack = '',
        defense = '',
        effectTitle = 'Trusty Rusty',
        effectText = 'This card can be attached to any fighter card on the field.',
        setCode = 'ALPH1-EN071',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN071_RUSTY_REBEL.png'
    },

    ['ALPH1_EN072_CHEBUREK_RUNE'] = {
        id = 'ALPH1_EN072_CHEBUREK_RUNE',
        name = 'Cheburek Rune',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '-2',
        attack = '',
        defense = '',
        effectTitle = 'Carboard Kit?',
        effectText = 'After this card has been equipped your fighter for 2 turns, you can target 1 of your opponents fighters, it is now equipped by this card.',
        setCode = 'ALPH1-EN072',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN072_CHEBUREK_RUNE.png'
    },

    ['ALPH1_EN073_CERAMIC_PISTOL'] = {
        id = 'ALPH1_EN073_CERAMIC_PISTOL',
        name = 'Ceramic Pistol',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+30',
        defense = '',
        effectTitle = 'Concealment',
        effectText = 'This card is concealed to any card which destroys \'Contraband\' cards.',
        setCode = 'ALPH1-EN073',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN073_CERAMIC_PISTOL.png'
    },

    ['ALPH1_EN074_HUNTING_RIFLE'] = {
        id = 'ALPH1_EN074_HUNTING_RIFLE',
        name = 'Hunting Rifle',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+20',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'This card is only effective against \'Animal\' cards.',
        setCode = 'ALPH1-EN074',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN074_HUNTING_RIFLE.png'
    },

    ['ALPH1_EN075_FLAMETHROWER'] = {
        id = 'ALPH1_EN075_FLAMETHROWER',
        name = 'Flamethrower',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+10',
        defense = '',
        effectTitle = 'We Didn\'t Start the Fire!',
        effectText = 'If the equipped fighter attacks your opponents fighter, apply burn. Burn: reduce the fighters HP by 10 each turn. If the equipped card attacks directly, apply burn to your opponents LP.',
        setCode = 'ALPH1-EN075',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN075_FLAMETHROWER.png'
    },

    ['ALPH1_EN076_TECH_9'] = {
        id = 'ALPH1_EN076_TECH_9',
        name = 'Tech 9',
        rarity = 'COMMON',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '+2',
        attack = '+30',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'A leathal compact weapon with blazing fire rate!',
        setCode = 'ALPH1-EN076',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN076_TECH_9.png'
    },

    ['ALPH1_EN077_BRADLEY_BK_KRAY'] = {
        id = 'ALPH1_EN077_BRADLEY_BK_KRAY',
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
        setCode = 'ALPH1-EN077',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN077_BRADLEY_\'BK\'_KRAY.png'
    },

    ['ALPH1_EN078_KIN_RODINE'] = {
        id = 'ALPH1_EN078_KIN_RODINE',
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
        setCode = 'ALPH1-EN078',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN078_KIN_RODINE.png'
    },

    ['ALPH1_EN079_JAMIE_THOMAS'] = {
        id = 'ALPH1_EN079_JAMIE_THOMAS',
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
        setCode = 'ALPH1-EN079',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN079_JAMIE_THOMAS.png'
    },

    ['ALPH1_EN080_CLYDE_RILEY_SR'] = {
        id = 'ALPH1_EN080_CLYDE_RILEY_SR',
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
        setCode = 'ALPH1-EN080',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN080_CLYDE_RILEY_SR.png'
    },

    ['ALPH1_EN081_WILLIAM_TAZENTINE'] = {
        id = 'ALPH1_EN081_WILLIAM_TAZENTINE',
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
        setCode = 'ALPH1-EN081',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN081_WILLIAM_TAZENTINE.png'
    },

    ['ALPH1_EN082_TERRANCE_REDFIELD_RILEY'] = {
        id = 'ALPH1_EN082_TERRANCE_REDFIELD_RILEY',
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
        setCode = 'ALPH1-EN082',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN082_TERRANCE_REDFIELD_RILEY.png'
    },

    ['ALPH1_EN083_TERRANCE_REDFIELD_RILEY'] = {
        id = 'ALPH1_EN083_TERRANCE_REDFIELD_RILEY',
        name = 'Terrance Redfield Riley',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'High Noon Hookah',
        level = 'Level 1',
        speed = '2',
        attack = '20',
        defense = '40',
        effectTitle = 'Rejuvinate',
        effectText = 'Once per turn you can make all of your fighters lose -1 SPD. Then heal all your fighters by +20 HP.',
        setCode = 'ALPH1-EN083',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN083_TERRANCE_REDFIELD_RILEY.png'
    },

    ['ALPH1_EN084_VEHICLE_ARMOUR'] = {
        id = 'ALPH1_EN084_VEHICLE_ARMOUR',
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
        setCode = 'ALPH1-EN084',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN084_VEHICLE_ARMOUR.png'
    },

    ['ALPH1_EN085_TRIAD_COMPOUND'] = {
        id = 'ALPH1_EN085_TRIAD_COMPOUND',
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
        setCode = 'ALPH1-EN085',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN085_TRIAD_COMPOUND.png'
    },

    ['ALPH1_EN086_JOHN_MORGAN'] = {
        id = 'ALPH1_EN086_JOHN_MORGAN',
        name = 'John Morgan',
        rarity = 'SUPER',
        type = 'Fighter',
        job = 'Dynasty 8',
        level = 'Level 1',
        speed = '4',
        attack = '50',
        defense = '60',
        effectTitle = 'Any D8 Around?',
        effectText = 'Pay 30 LP. Search your deck for 1 \'location\' card. You can then destroy 1 of your opponents \'location\' cards.',
        setCode = 'ALPH1-EN086',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN086_JOHN_MORGAN.png'
    },

    ['ALPH1_EN087_MUFASA_VOLKOV'] = {
        id = 'ALPH1_EN087_MUFASA_VOLKOV',
        name = 'Mufasa Volkov',
        rarity = 'COMMON',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '3',
        attack = '60',
        defense = '30',
        effectTitle = 'Switching Tactics',
        effectText = 'Once per turn you can switch the ATK and DEF of this card. You cannot attack the turn you activate this effect.',
        setCode = 'ALPH1-EN087',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN087_MUFASA_VOLKOV.png'
    },

    ['ALPH1_EN088_MUFASA_VOLKOV'] = {
        id = 'ALPH1_EN088_MUFASA_VOLKOV',
        name = 'Mufasa Volkov',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'LSPD Chief',
        level = 'Level 2',
        speed = '6',
        attack = '70',
        defense = '100',
        effectTitle = 'Stand Guard',
        effectText = 'Once per turn if a \'location\' or \'fighter\' card you control is targeted for destruction, negate the desctruction.',
        setCode = 'ALPH1-EN088',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN088_MUFASA_VOLKOV.png'
    },

    ['ALPH1_EN089_LOTTO'] = {
        id = 'ALPH1_EN089_LOTTO',
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
        setCode = 'ALPH1-EN089',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN089_LOTTO!.png'
    },

    ['ALPH1_EN090_ERIC_COLEMAN'] = {
        id = 'ALPH1_EN090_ERIC_COLEMAN',
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
        setCode = 'ALPH1-EN090',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN090_ERIC_COLEMAN.png'
    },

    ['ALPH1_EN091_LARRYS_CAR_LOT'] = {
        id = 'ALPH1_EN091_LARRYS_CAR_LOT',
        name = 'Larrys Car Lot',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Caryard',
        effectText = 'If you draw a \'Vehicle\' card. You can draw 1 more card.',
        effectTags = { 'on_draw', 'draw' },
        effects = {
            {
                trigger = 'on_draw',
                tags = { 'draw' },
                condition = { drawnType = 'Vehicle' },
                actions = {
                    { action = 'draw', target = 'self', amount = 1 }
                }
            }
        },
        setCode = 'ALPH1-EN091',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN091_LARRYS_CAR_LOT.png'
    },

    ['ALPH1_EN092_KENZIE_HALL'] = {
        id = 'ALPH1_EN092_KENZIE_HALL',
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
        setCode = 'ALPH1-EN092',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN092_KENZIE_HALL.png'
    },

    ['ALPH1_EN093_KENZIE_HALL'] = {
        id = 'ALPH1_EN093_KENZIE_HALL',
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
        setCode = 'ALPH1-EN093',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN093_KENZIE_HALL.png'
    },

    ['ALPH1_EN094_CHADWICK_SLAMMER'] = {
        id = 'ALPH1_EN094_CHADWICK_SLAMMER',
        name = 'Chadwick Slammer',
        rarity = 'COMMON',
        type = 'Fighter',
        job = 'FIB',
        level = 'Level 1',
        speed = '3',
        attack = '20',
        defense = '40',
        effectTitle = 'Slammer Special',
        effectText = 'Pay half your LP. Destroy all fighters your opponent controls. Then bannish all \'FIB\' cards in your hand and field.',
        setCode = 'ALPH1-EN094',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN094_CHADWICK_SLAMMER.png'
    },

    ['ALPH1_EN095_XAVIER_WU'] = {
        id = 'ALPH1_EN095_XAVIER_WU',
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
        setCode = 'ALPH1-EN095',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN095_XAVIER_WU.png'
    },

    ['ALPH1_EN096_LOGAN_WU'] = {
        id = 'ALPH1_EN096_LOGAN_WU',
        name = 'Logan Wu',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = 'Triad',
        level = 'Level 2',
        speed = '5',
        attack = '50',
        defense = '110',
        effectTitle = 'Kaboom',
        effectText = 'Once per turn you can place 1 \'Sticky Bomb\' counter on each of your opponents fighters. You can remove all \'sticky bomb\' counters from all cards, dealing -30HP for each counter. You cannot detonate sticky bombs the turn you place them.',
        setCode = 'ALPH1-EN096',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN096_LOGAN_WU.png'
    },

    ['ALPH1_EN097_KITT_REED_WU'] = {
        id = 'ALPH1_EN097_KITT_REED_WU',
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
        setCode = 'ALPH1-EN097',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN097_KITT_REED_WU.png'
    },

    ['ALPH1_EN098_SPARTAN_ARSENAL'] = {
        id = 'ALPH1_EN098_SPARTAN_ARSENAL',
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
        setCode = 'ALPH1-EN098',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN098_SPARTAN_ARSENAL.png'
    },

    ['ALPH1_EN099_GUN_BENCH'] = {
        id = 'ALPH1_EN099_GUN_BENCH',
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
        setCode = 'ALPH1-EN099',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN099_GUN_BENCH.png'
    },

    ['ALPH1_EN100_MARINE_BEACH_RECYCLING'] = {
        id = 'ALPH1_EN100_MARINE_BEACH_RECYCLING',
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
        setCode = 'ALPH1-EN100',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN100_MARINE_BEACH_RECYCLING.png'
    },

    ['ALPH1_EN101_MORNINGWOOD_AMMU'] = {
        id = 'ALPH1_EN101_MORNINGWOOD_AMMU',
        name = 'Morningwood Ammu',
        rarity = 'COMMON',
        type = 'Location',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Once per turn you can return any \'weapon\' card to your hand, then add 1 \'weapon\' card from your cemetary to your hand.',
        setCode = 'ALPH1-EN101',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN101_MORNINGWOOD_AMMU.png'
    },

    ['ALPH1_EN102_SMG'] = {
        id = 'ALPH1_EN102_SMG',
        name = 'SMG',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+20',
        defense = '',
        effectTitle = 'Dual Wield',
        effectText = 'You can equip up to 2 copies of \'SMG\' to any fighter.',
        setCode = 'ALPH1-EN102',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN102_SMG.png'
    },

    ['ALPH1_EN103_COMBAT_PDW'] = {
        id = 'ALPH1_EN103_COMBAT_PDW',
        name = 'Combat PDW',
        rarity = 'SUPER',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+30',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'The equipped fighter can attack 2 opponents fighters per turn.',
        setCode = 'ALPH1-EN103',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN103_COMBAT_PDW.png'
    },

    ['ALPH1_EN104_PFISTER_COMET_CTX'] = {
        id = 'ALPH1_EN104_PFISTER_COMET_CTX',
        name = 'Pfister Comet CTX',
        rarity = 'SUPER',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+10',
        attack = '',
        defense = '',
        effectTitle = 'Exclusive',
        effectText = 'You can only have 1 of this card on the field at a time.',
        setCode = 'ALPH1-EN104',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN104_PFISTER_COMET_CTX.png'
    },

    ['ALPH1_EN105_SPIKE_STRIP'] = {
        id = 'ALPH1_EN105_SPIKE_STRIP',
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
        setCode = 'ALPH1-EN105',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN105_SPIKE_STRIP.png'
    },

    ['ALPH1_EN106_FUEL_SHORTAGE'] = {
        id = 'ALPH1_EN106_FUEL_SHORTAGE',
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
        setCode = 'ALPH1-EN106',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN106_FUEL_SHORTAGE.png'
    },

    ['ALPH1_EN107_HOUSE_ROBBERY'] = {
        id = 'ALPH1_EN107_HOUSE_ROBBERY',
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
        setCode = 'ALPH1-EN107',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN107_HOUSE_ROBBERY.png'
    },

    ['ALPH1_EN108_PALETO_HEIST'] = {
        id = 'ALPH1_EN108_PALETO_HEIST',
        name = 'Paleto Heist',
        rarity = 'COMMON',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'This card cannot be played unless by the effect of \'Bank Card\'. Gain +30 LP and draw until you have 4 cards in your hand.',
        setCode = 'ALPH1-EN108',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN108_PALETO_HEIST.png'
    },

    ['ALPH1_EN109_BANK_CARD'] = {
        id = 'ALPH1_EN109_BANK_CARD',
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
        setCode = 'ALPH1-EN109',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN109_BANK_CARD.png'
    },

    ['ALPH1_EN110_POLICE_CHASE'] = {
        id = 'ALPH1_EN110_POLICE_CHASE',
        name = 'Police Chase',
        rarity = 'COMMON',
        type = 'Event',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'PIT MANOVEUR',
        effectText = 'If you control an \'LEO\' vehicle card, target the lowest SPD vehicle card on the field, then banish it and its equipped fighter.',
        setCode = 'ALPH1-EN110',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN110_POLICE_CHASE.png'
    },

    ['ALPH1_EN111_AK47'] = {
        id = 'ALPH1_EN111_AK47',
        name = 'AK47',
        rarity = 'SUPER',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+40',
        defense = '',
        effectTitle = '7.62',
        effectText = 'The equipped card inflicts piercing damage.',
        setCode = 'ALPH1-EN111',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN111_AK47.png'
    },

    ['ALPH1_EN112_SOSMC_CLUBHOUSE'] = {
        id = 'ALPH1_EN112_SOSMC_CLUBHOUSE',
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
        setCode = 'ALPH1-EN112',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN112_SOSMC_CLUBHOUSE.png'
    },

    ['ALPH1_EN113_ELI_MALLORY'] = {
        id = 'ALPH1_EN113_ELI_MALLORY',
        name = 'Eli Mallory',
        rarity = 'RARE',
        type = 'Fighter',
        job = 'EMS',
        level = 'Level 2',
        speed = '3',
        attack = '30',
        defense = '70',
        effectTitle = 'HEROES NEVER DIE!',
        effectText = 'Your other fighters cannot be destroyed by battle.',
        setCode = 'ALPH1-EN113',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN113_ELI_MALLORY.png'
    },

    ['ALPH1_EN114_KIN_RODINE'] = {
        id = 'ALPH1_EN114_KIN_RODINE',
        name = 'Kin Rodine',
        rarity = 'ULTRA',
        type = 'Fighter',
        job = '',
        level = 'Level 1',
        speed = '4',
        attack = '30',
        defense = '60',
        effectTitle = 'Upside Down Man',
        effectText = 'If your LP is lower than your opponents, this cards ATK becomes equal to half of the difference (rounded up).',
        setCode = 'ALPH1-EN114',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN114_KIN_RODINE.png'
    },

    ['ALPH1_EN115_CLYDE_RILEY_JR'] = {
        id = 'ALPH1_EN115_CLYDE_RILEY_JR',
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
        setCode = 'ALPH1-EN115',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN115_CLYDE_RILEY_JR.png'
    },

    ['ALPH1_EN116_OXYCODONE'] = {
        id = 'ALPH1_EN116_OXYCODONE',
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
        setCode = 'ALPH1-EN116',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN116_OXYCODONE.png'
    },

    ['ALPH1_EN117_HAKOUCHOU_DRAG'] = {
        id = 'ALPH1_EN117_HAKOUCHOU_DRAG',
        name = 'Hakouchou Drag',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '+6',
        attack = '',
        defense = '',
        effectTitle = 'Deathtrap',
        effectText = 'On each of your main phase, roll a D6, if you roll a 1 or 6, destroy this card and the equipped fighter takes -20 HP damage.',
        setCode = 'ALPH1-EN117',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN117_HAKOUCHOU_DRAG.png'
    },

    ['ALPH1_EN118_SKATEBOARD'] = {
        id = 'ALPH1_EN118_SKATEBOARD',
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
        setCode = 'ALPH1-EN118',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN118_SKATEBOARD.png'
    },

    ['ALPH1_EN119_OUTFIT_BAG'] = {
        id = 'ALPH1_EN119_OUTFIT_BAG',
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
        setCode = 'ALPH1-EN119',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN119_OUTFIT_BAG.png'
    },

    ['ALPH1_EN120_XP_POTION'] = {
        id = 'ALPH1_EN120_XP_POTION',
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
        setCode = 'ALPH1-EN120',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN120_XP_POTION.png'
    },

    ['ALPH1_EN121_AIR_FRESHENER'] = {
        id = 'ALPH1_EN121_AIR_FRESHENER',
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
        setCode = 'ALPH1-EN121',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN121_AIR_FRESHENER.png'
    },

    ['ALPH1_EN122_IFAKS'] = {
        id = 'ALPH1_EN122_IFAKS',
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
        setCode = 'ALPH1-EN122',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN122_IFAKS.png'
    },

    ['ALPH1_EN123_SNS_CLIP'] = {
        id = 'ALPH1_EN123_SNS_CLIP',
        name = 'SNS clip',
        rarity = 'RARE',
        type = 'Weapon',
        job = '',
        level = '',
        speed = '',
        attack = '+0',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Body\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
        setCode = 'ALPH1-EN123',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN123_SNS_CLIP.png'
    },

    ['ALPH1_EN124_CHEVAL_FUGITIVE'] = {
        id = 'ALPH1_EN124_CHEVAL_FUGITIVE',
        name = 'Cheval Fugitive',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+4',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Each turn during the end phase, reduce the speed of this card by -1 until it becomes 1.',
        setCode = 'ALPH1-EN124',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN124_CHEVAL_FUGITIVE.png'
    },

    ['ALPH1_EN125_BRAVADO_BISON'] = {
        id = 'ALPH1_EN125_BRAVADO_BISON',
        name = 'Bravado Bison',
        rarity = 'COMMON',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+1',
        attack = '',
        defense = '',
        effectTitle = 'Little Big Bison',
        effectText = 'This card also applies +1 SPD to all other fighters you control.',
        setCode = 'ALPH1-EN125',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN125_BRAVADO_BISON.png'
    },

    ['ALPH1_EN126_POLICE_BUFFALO_STX_HELLFIRE'] = {
        id = 'ALPH1_EN126_POLICE_BUFFALO_STX_HELLFIRE',
        name = 'Police Buffalo STX Hellfire',
        rarity = 'RARE',
        type = 'Vehicle',
        job = '',
        level = '',
        speed = '+6',
        attack = '',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'Can only be equipped to an \'LEO\' card.',
        setCode = 'ALPH1-EN126',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN126_POLICE_BUFFALO_STX_HELLFIRE.png'
    },

    ['ALPH1_EN127_DOOBIE'] = {
        id = 'ALPH1_EN127_DOOBIE',
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
        setCode = 'ALPH1-EN127',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN127_DOOBIE.png'
    },

    ['ALPH1_EN128_STAGE_3_BRAKES'] = {
        id = 'ALPH1_EN128_STAGE_3_BRAKES',
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
        setCode = 'ALPH1-EN128',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN128_STAGE_3_BRAKES.png'
    },

    ['ALPH1_EN129_STAGE_4_ENGINE'] = {
        id = 'ALPH1_EN129_STAGE_4_ENGINE',
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
        setCode = 'ALPH1-EN129',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN129_STAGE_4_ENGINE.png'
    },

    ['ALPH1_EN130_STAGE_4_SUSPENSION'] = {
        id = 'ALPH1_EN130_STAGE_4_SUSPENSION',
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
        setCode = 'ALPH1-EN130',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN130_STAGE_4_SUSPENSION.png'
    },

    ['ALPH1_EN131_SAINT_ROSES_CHURCH'] = {
        id = 'ALPH1_EN131_SAINT_ROSES_CHURCH',
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
        setCode = 'ALPH1-EN131',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN131_SAINT_ROSES_CHURCH.png'
    },

    ['ALPH1_EN132_WADE_WOLSON'] = {
        id = 'ALPH1_EN132_WADE_WOLSON',
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
        setCode = 'ALPH1-EN132',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN132_WADE_WOLSON.png'
    },

    ['ALPH1_EN133_DAILY_SPIN'] = {
        id = 'ALPH1_EN133_DAILY_SPIN',
        name = 'Daily Spin',
        rarity = 'RARE',
        type = 'Item',
        job = '',
        level = '',
        speed = '',
        attack = '',
        defense = '',
        effectTitle = 'Fingers Crossed!',
        effectText = 'Discard 1 level 2 fighter to draw 2 cards.',
        setCode = 'ALPH1-EN133',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN133_DAILY_SPIN.png'
    },

    ['ALPH1_EN134_LUNA_RAYNE'] = {
        id = 'ALPH1_EN134_LUNA_RAYNE',
        name = 'Luna Rayne',
        rarity = 'SECRET',
        type = 'Fighter',
        job = 'SOSMC Int. President',
        level = 'Level 3',
        speed = '4',
        attack = '?',
        defense = '80',
        effectTitle = 'EFFECT',
        effectText = 'If your opponent controls a fighter, and you control no cards, you can special summon this card. When this card is summoned, roll a 6 sided die. Its attack is equal to the result x10.',
        setCode = 'ALPH1-EN134',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN134_LUNA_RAYNE.png'
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
        attack = '+0',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Loop\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
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
        attack = '+0',
        defense = '',
        effectTitle = 'EFFECT',
        effectText = 'If \'SNS Clip\', \'SNS Trigger\' and \'SNS Loop\' are all equiped on your field, send them to the cemetery and add one \'SNS Pistol\' from your deck.',
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
        attack = '+50',
        defense = '',
        effectTitle = '',
        effectText = '',
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
        type = '',
        job = '',
        level = '',
        speed = '+3',
        attack = '',
        defense = '',
        effectTitle = 'Whambulance',
        effectText = 'Any damage the equipped card would take is halved.',
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
        setCode = 'ALPH1-EN151',
        edition = '1st Edition',
        inventoryImage = 'ALPH1-EN151_POLYMORPH_POTION.png'
    }
}
