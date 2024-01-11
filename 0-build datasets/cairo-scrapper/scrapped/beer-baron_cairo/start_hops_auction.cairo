#[system]
mod start_hops_auction {
    use array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use beer_barron::components::auction::{Auction, AuctionTrait};
    use beer_barron::components::game::{Game};

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA};

    // TODO: Move to game state so each game can have its own auction parameters
    const target_price: u128 = 10;
    const _0_31: u128 = 571849066284996100; // 0.031
    const MAX_SELLABLE: u128 = 100000;
    const _0_0023: u128 = 32427511369531970; // 0.0016

    fn execute(ctx: Context, game_id: u64, item_id: u128) {
        // todo: check if auction already exists
        // todo: check game exists
        let mut game = get!(ctx.world, (game_id), (Game));
        // assert(game.status, 'game is not running');

        let auction = Auction {
            game_id,
            item_id,
            target_price: target_price,
            decay_constant_mag: _0_31,
            decay_constant_sign: true,
            max_sellable: MAX_SELLABLE,
            time_scale_mag: _0_0023,
            time_scale_sign: false,
            start_time: get_block_timestamp(), //update to timestamp
            sold: 0,
        };

        set!(ctx.world, (auction));
    }
}
