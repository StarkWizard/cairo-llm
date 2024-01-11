use beer_barron::components::game::{
    Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig
};
use starknet::{ContractAddress, ClassHash};
use beer_barron::components::beer::{
    Brew, BrewBatchTrack, BeerID, get_beer_id_from_enum, get_recipe, BrewStatus
};

#[starknet::interface]
trait IBrewing<TContractState> {
    fn brew_beer(self: @TContractState, game_id: u64, beer_id: BeerID);
    fn bottle_beer(self: @TContractState, game_id: u64, batch_id: u64);
}

#[dojo::contract]
mod brewing {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use beer_barron::components::game::{
        Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig, Joined
    };
    use beer_barron::components::beer::{
        Brew, BrewTrait, BrewBatchTrack, BeerID, get_beer_id_from_enum, get_recipe, BrewStatus
    };
    use beer_barron::components::player::{Player, FarmArea};
    use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};

    use beer_barron::constants::CONFIG::{SYSTEM_IDS::{GAME_CONFIG}};
    use beer_barron::constants::{CONFIG::{STARTING_BALANCES::{GOLD}, ITEM_IDS::{GOLD_ID}}};
    use beer_barron::constants::{CONFIG::{ITEM_IDS::{HOP_SEEDS, BEERS}}};

    use beer_barron::constants::CONFIG::{BREWING::{BREW_YEILD_LITRES}};

    use beer_barron::systems::auctions::{auctions, IAuctionDispatcher, IAuctionDispatcherTrait};

    use beer_barron::constants::{
        CONFIG::{
            ITEM_IDS::{SEED_TO_FLOWER_OFFSET}, FARMING::{PLOT_COUNT, CROP_GROWTH_TIME, CROP_YIELD}
        }
    };
    use beer_barron::constants::{
        CONFIG::{ITEM_IDS::{HOP_FLOWERS::{CITRA, CHINOOK, GALAXY, FUGGLE, SAAZ, CASCADE}}}
    };

    use super::IBrewing;

    #[external(v0)]
    impl BrewingImpl of IBrewing<ContractState> {
        fn brew_beer(self: @ContractState, game_id: u64, beer_id: BeerID) {
            let world = self.world_dispatcher.read();
            // assert that the game is active
            let game = get!(world, (game_id), (Game));
            game.active();

            // get beer recipe
            let beer_recipe = get_recipe(beer_id, game.seed);

            let player_id = get_caller_address().into();

            // check that the player has enough hops
            check_balance(world, game_id, beer_recipe.citra, CITRA.try_into().unwrap());
            check_balance(world, game_id, beer_recipe.chinook, CHINOOK.try_into().unwrap());
            check_balance(world, game_id, beer_recipe.galaxy, GALAXY.try_into().unwrap());
            check_balance(world, game_id, beer_recipe.fuggle, FUGGLE.try_into().unwrap());
            check_balance(world, game_id, beer_recipe.saaz, SAAZ.try_into().unwrap());
            check_balance(world, game_id, beer_recipe.cascade, CASCADE.try_into().unwrap());

            // create unique batch number for the game
            let mut batch = get!(world, (game_id), (BrewBatchTrack));
            batch.count += 1;

            // create batch with current timestamp
            let brew = Brew {
                game_id,
                player_id: player_id,
                batch_id: batch.count,
                batch_key: batch.count,
                owner: player_id,
                beer_id: get_beer_id_from_enum(beer_id),
                time_built: get_block_timestamp(),
                status: BrewStatus::brewing,
            };

            set!(world, (brew, batch));
        }

        fn bottle_beer(self: @ContractState, game_id: u64, batch_id: u64) {
            let world = self.world_dispatcher.read();

            let player_id = get_caller_address();

            // assert that the game is active
            let game = get!(world, (game_id), (Game));
            game.active();

            // assert batch is built and brewed
            let mut batch = get!(world, (game_id, player_id, batch_id), (Brew));
            batch.assert_built();
            batch.assert_brewed();

            // bottle batch
            batch.status = BrewStatus::bottled;

            // increase inventory
            let mut inventory = get!(world, (game_id, player_id, batch.beer_id), (ItemBalance));
            inventory.add(BREW_YEILD_LITRES.try_into().unwrap());

            set!(world, (inventory, batch));
        }
    }

    // TODO: move to a common place
    fn check_balance(world: IWorldDispatcher, game_id: u64, recipe_quantity: u64, hop_id: u64) {
        let mut hop_balance = get!(world, (game_id, get_caller_address(), hop_id), (ItemBalance));
        hop_balance.assert_balance(recipe_quantity.into());
        hop_balance.sub(recipe_quantity.into());
        set!(world, (hop_balance));
    }
}
