// markets
mod CONFIG {
    mod STARTING_PRICES {
        const HOP_SEED_STARTING_PRICE: felt252 = 60;
        const BEERS_STARTING_PRICE: felt252 = 10;
    }
    mod STARTING_BALANCES {
        const GOLD: felt252 = 500;
    }
    mod SYSTEM_IDS {
        const GAME_CONFIG: felt252 = 999999999999999;
        const INDULGENCE_COUNT: felt252 = 999999999999998;
    }
    mod FARMING {
        const CROP_GROWTH_TIME: felt252 = 200;
        const CROP_YIELD: felt252 = 100;
        const PLOT_COUNT: felt252 = 6;
    }
    mod BREWING {
        const BREW_TIME: felt252 = 100;
        const BREW_YEILD_LITRES: felt252 = 30;
    }
    mod INDULGENCES {
        const AUCTION_LENGTH: u64 = 300;
    }
    //
    // to use in the ItemBalances - we offset the values so we can fit more in the future
    //
    mod ITEM_IDS {
        const GOLD_ID: felt252 = 999999;
        const SEED_TO_FLOWER_OFFSET: felt252 = 100;
        const INDULGENCE_ID: felt252 = 999998;
        mod HOP_SEEDS {
            const CITRA: felt252 = 1;
            const CHINOOK: felt252 = 2;
            const GALAXY: felt252 = 3;
            const CASCADE: felt252 = 4;
            const SAAZ: felt252 = 5;
            const FUGGLE: felt252 = 6;
        }
        mod HOP_FLOWERS {
            const CITRA: felt252 = 101;
            const CHINOOK: felt252 = 102;
            const GALAXY: felt252 = 103;
            const CASCADE: felt252 = 104;
            const SAAZ: felt252 = 105;
            const FUGGLE: felt252 = 106;
        }
        mod BEERS {
            const DRAGON_HIDE_BLAZE_IPA: felt252 = 1001;
            const MITHRIL_HAZE: felt252 = 1002;
            const OBSIDIAN_IMPERIAL_STOUT: felt252 = 1003;
            const RUBY_SOUR: felt252 = 1004;
            const DIAMOND_WHEAT_BEER: felt252 = 1005;
            const ETHEREAL_LAGER: felt252 = 1006;
        }
    }
}
