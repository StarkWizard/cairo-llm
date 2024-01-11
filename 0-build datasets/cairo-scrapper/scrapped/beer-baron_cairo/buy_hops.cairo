#[system]
mod buy_hops {
    use core::debug::PrintTrait;
    use array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use dojo::world::Context;

    use beer_barron::components::game::{Game, GameTrait};
    use beer_barron::components::auction::{Auction, AuctionTrait};
    use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};

    use beer_barron::constants::{CONFIG::{ITEM_IDS::{GOLD_ID}}};

    fn execute(ctx: Context, game_id: u64, item_id: u128, amount: u128) {
        // assert that the game is active
        let game = get!(ctx.world, (game_id), (Game));
        game.active();

        let mut auction = get!(ctx.world, (game_id, item_id), Auction);
        let mut gold_balance = get!(ctx.world, (game_id, ctx.origin, GOLD_ID), ItemBalance);
        let mut item_balance = get!(ctx.world, (game_id, ctx.origin, item_id), ItemBalance);

        // add to amount sold
        auction.sold += amount;

        // TODO: check this
        // subtract from gold
        // TODO: overflow check
        gold_balance.sub(auction.get_price().try_into().unwrap() * amount);

        // add to item balance
        item_balance.add(amount);

        set!(ctx.world, (auction, gold_balance, item_balance));
    }
}
