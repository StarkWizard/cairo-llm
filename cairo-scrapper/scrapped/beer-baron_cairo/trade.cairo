#[system]
mod create_trade {
    use beer_barron::components::trading::TradeTrait;
    use core::debug::PrintTrait;
    use array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use dojo::world::Context;

    use beer_barron::components::trading::{Trade, TradeStatus, TradeTrack};
    use beer_barron::components::game::{Game, GameTrait, Ownership};
    use beer_barron::components::auction::{Auction, AuctionTrait};
    use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};

    fn execute(ctx: Context, game_id: u64, item_id: u128, quantity: u128, price: u128) {
        // assert that the game is active
        let game = get!(ctx.world, (game_id), (Game));
        game.active();

        // increment trade track
        let mut trade_track = get!(ctx.world, (game_id), TradeTrack);
        trade_track.count += 1;

        let mut item_balance = get!(ctx.world, (game_id, ctx.origin, item_id), ItemBalance);

        let entity_id: u64 = trade_track.count.into();

        let mut trade = Trade {
            entity_id, game_id, item_id, quantity, price, status: TradeStatus::OPEN
        };

        // creates trade
        trade.create_trade(ref item_balance);

        let ownership = Ownership { entity_id, owner: ctx.origin.into() };

        set!(ctx.world, (trade, item_balance, ownership, trade_track));
    }
}

#[system]
mod accept_trade {
    use beer_barron::components::trading::TradeTrait;
    use core::debug::PrintTrait;
    use array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp};

    use dojo::world::Context;

    use beer_barron::components::trading::{Trade, TradeStatus};
    use beer_barron::components::game::{Game, GameTrait, Ownership};
    use beer_barron::components::balances::{ItemBalance};

    use beer_barron::constants::{CONFIG::{ITEM_IDS::{GOLD_ID}}};

    fn execute(ctx: Context, game_id: u64, trade_id: u128) {
        // assert that the game is active
        let game = get!(ctx.world, (game_id), (Game));
        game.active();

        // trade
        let trade_owner = get!(ctx.world, (trade_id), (Ownership)).owner;
        let mut trade = get!(ctx.world, (trade_id), Trade);

        // get buyer balance
        let mut buyer_item_balance = get!(
            ctx.world, (game_id, ctx.origin, trade.item_id), ItemBalance
        );
        let mut buyer_gold_balance = get!(ctx.world, (game_id, ctx.origin, GOLD_ID), ItemBalance);

        // get seller balance
        let mut seller_gold_balance = get!(ctx.world, (game_id, trade_owner, GOLD_ID), ItemBalance);

        // accept
        trade
            .accept_trade(
                ref buyer_gold_balance, ref seller_gold_balance, ref buyer_item_balance, game_id
            );

        set!(ctx.world, (trade, buyer_gold_balance, seller_gold_balance, buyer_item_balance));
    }
}
