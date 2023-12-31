#[system]
mod brew_beer {
    use traits::{Into, TryInto};
    use dojo::world::Context;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use beer_barron::components::game::{Game, GameTracker, GameTrait};
    use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};
    use beer_barron::components::beer::{
        Brew, BrewBatchTrack, BeerID, get_beer_id_from_enum, get_recipe, BrewStatus
    };
    use beer_barron::constants::{CONFIG::{ITEM_IDS::{HOP_FLOWERS::{CITRA, CHINOOK, GALAXY}}}};

    fn execute(ctx: Context, game_id: u64, beer_id: BeerID) {
        // assert that the game is active
        let game = get!(ctx.world, (game_id), (Game));
        game.active();

        // get beer recipe
        let beer_recipe = get_recipe(beer_id);

        // check that the player has enough hops
        check_balance(ctx, game_id, beer_recipe.citra, CITRA.try_into().unwrap());
        check_balance(ctx, game_id, beer_recipe.chinook, CHINOOK.try_into().unwrap());
        check_balance(ctx, game_id, beer_recipe.galaxy, GALAXY.try_into().unwrap());

        // create unique batch number for the game
        let mut batch = get!(ctx.world, (game_id), (BrewBatchTrack));
        batch.count += 1;

        // create batch with current timestamp
        let brew = Brew {
            game_id,
            player_id: ctx.origin,
            batch_id: batch.count,
            batch_key: batch.count,
            owner: ctx.origin,
            beer_id: get_beer_id_from_enum(beer_id),
            time_built: get_block_timestamp(),
            status: BrewStatus::brewing,
        };

        set!(ctx.world, (brew, batch));
    }

    fn check_balance(ctx: Context, game_id: u64, recipe_quantity: u64, hop_id: u64) {
        let mut hop_balance = get!(ctx.world, (game_id, ctx.origin, hop_id), (ItemBalance));
        hop_balance.assert_balance(recipe_quantity.into());
        hop_balance.sub(recipe_quantity.into());
        set!(ctx.world, (hop_balance));
    }
}
