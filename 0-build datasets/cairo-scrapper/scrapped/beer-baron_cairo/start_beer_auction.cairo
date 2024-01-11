#[system]
mod start_beer_auction {
    use array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use beer_barron::components::auction::{TavernAuction, TavernAuctionTrait};
    use beer_barron::components::game::{Game};

    use beer_barron::vrgda::vrgda::{ReverseLinearVRGDA};

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;

    const _0_31: u128 = 1071849066284996100; // 0.031
    const PER_TIME_UNIT: u128 = 1;

    fn execute(ctx: Context, game_id: u64, item_id: u128) {
        let mut game = get!(ctx.world, (game_id), (Game));
        // assert(game.status, 'game is not running');

        let auction = TavernAuction {
            game_id,
            item_id,
            target_price: 10,
            decay_constant_mag: _0_31,
            decay_constant_sign: true,
            per_time_unit: PER_TIME_UNIT,
            start_time: get_block_timestamp(),
            sold: 0,
        };

        set!(ctx.world, (auction));
    }
}
