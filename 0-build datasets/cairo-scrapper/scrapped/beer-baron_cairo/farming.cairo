use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use beer_barron::components::game::{
    Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig
};
use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IFarming<TContractState> {
    fn build_farm(self: @TContractState, game_id: u64, area_type: Array<u64>);
    fn harvest_farm(self: @TContractState, game_id: u64);
}

#[dojo::contract]
mod farming {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use beer_barron::components::game::{
        Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig, Joined
    };

    use beer_barron::components::player::{Player, FarmArea};
    use beer_barron::components::balances::{ItemBalance};

    use beer_barron::constants::CONFIG::{SYSTEM_IDS::{GAME_CONFIG}};
    use beer_barron::constants::{CONFIG::{STARTING_BALANCES::{GOLD}, ITEM_IDS::{GOLD_ID}}};
    use beer_barron::constants::{CONFIG::{ITEM_IDS::{HOP_SEEDS, BEERS}}};

    use beer_barron::systems::auctions::{auctions, IAuctionDispatcher, IAuctionDispatcherTrait};

    use beer_barron::constants::{
        CONFIG::{
            ITEM_IDS::{SEED_TO_FLOWER_OFFSET}, FARMING::{PLOT_COUNT, CROP_GROWTH_TIME, CROP_YIELD}
        }
    };

    use super::IFarming;

    #[external(v0)]
    impl FarmingImpl of IFarming<ContractState> {
        fn build_farm(self: @ContractState, game_id: u64, area_type: Array<u64>) {
            let world = self.world_dispatcher.read();

            // assert that the game is active
            let game = get!(world, (game_id), (Game));
            game.active();

            assert(area_type.len() == PLOT_COUNT.try_into().unwrap(), 'you must submit 6 areas');

            let caller = get_caller_address();

            // MAX AREAS = NUMBER_OF_FARM_PLOTS
            let mut area_id: usize = 0;

            // loop through all areas
            loop {
                if area_id >= area_type.len() {
                    break;
                }

                let item_type = *area_type[area_id];

                if item_type != 0 {
                    // check if player has enough items and subtract
                    let mut item_balance = get!(world, (game_id, caller, item_type), (ItemBalance));
                    assert(item_balance.balance > 0, 'you do not have enough items');
                    item_balance.balance -= 1;
                    set!(world, (item_balance));

                    set!(
                        world,
                        FarmArea {
                            game_id,
                            player_id: caller,
                            area_id: area_id.into(),
                            area_type: item_type,
                            time_built: get_block_timestamp()
                        }
                    );
                }

                area_id += 1;
            }
        }
        fn harvest_farm(self: @ContractState, game_id: u64) {
            let world = self.world_dispatcher.read();

            // assert that the game is active
            let game = get!(world, (game_id), (Game));
            game.active();

            // MAX AREAS = PLOT_COUNT
            let mut area_id: usize = 0;

            let caller = get_caller_address();

            // loop through all areas
            loop {
                if area_id >= PLOT_COUNT.try_into().unwrap() {
                    break;
                }

                let mut farm_area = get!(world, (game_id, caller, area_id), (FarmArea));

                if farm_area.area_type != 0 {
                    let time_since_build = get_block_timestamp() - farm_area.time_built;

                    // harvest and reset
                    if (time_since_build > CROP_GROWTH_TIME.try_into().unwrap()) {
                        // get grown hop balance - see consts file
                        // grown item is the hop + 10 for ids
                        let mut item_balance = get!(
                            world,
                            (
                                game_id,
                                caller,
                                farm_area.area_type + SEED_TO_FLOWER_OFFSET.try_into().unwrap()
                            ),
                            (ItemBalance)
                        );
                        // reset time and area
                        item_balance.balance += CROP_YIELD.try_into().unwrap();

                        let updated_farm = FarmArea {
                            game_id,
                            player_id: caller,
                            area_id: area_id.into(),
                            area_type: 0,
                            time_built: 0
                        };
                        set!(world, (updated_farm, item_balance));
                    }
                }

                area_id += 1;
            }
        }
    }
}
