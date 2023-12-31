use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait ITrading<TContractState> {
    fn create_trade(self: @TContractState, game_id: u64, item_id: u64, quantity: u64, price: u64);
    fn accept_trade(self: @TContractState, game_id: u64, trade_id: u64);
    fn cancel_trade(self: @TContractState, game_id: u64, trade_id: u64);
}

#[dojo::contract]
mod trading {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use beer_barron::components::game::{
        Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig, Joined
    };

    use beer_barron::components::trading::{Trade, TradeStatus, TradeTrack, TradeTrait};
    use beer_barron::components::auction::{Auction, AuctionTrait};
    use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};

    use beer_barron::constants::{CONFIG::{ITEM_IDS::{GOLD_ID}}};

    use super::ITrading;

    #[external(v0)]
    impl TradingImpl of ITrading<ContractState> {
        fn create_trade(
            self: @ContractState, game_id: u64, item_id: u64, quantity: u64, price: u64
        ) {
            let world = self.world_dispatcher.read();

            get!(world, (game_id), (Game)).active();

            let caller = get_caller_address();

            let mut trade_track = get!(world, (game_id), TradeTrack);
            trade_track.count += 1;

            let mut item_balance = get!(world, (game_id, caller, item_id), ItemBalance);

            let entity_id: u64 = trade_track.count.into();

            let mut trade = Trade {
                entity_id,
                game_id,
                item_id,
                quantity,
                price,
                status: TradeStatus::OPEN,
                player_id: caller,
                game_id_value: game_id
            };

            // creates trade
            trade.create_trade(ref item_balance);

            set!(world, (trade, item_balance, trade_track));
        }

        fn accept_trade(self: @ContractState, game_id: u64, trade_id: u64) {
            let world = self.world_dispatcher.read();

            get!(world, (game_id), (Game)).active();

            let caller = get_caller_address();

            let mut trade = get!(world, (trade_id, game_id), Trade);

            // get buyer balance
            let mut buyer_item_balance = get!(world, (game_id, caller, trade.item_id), ItemBalance);
            let mut buyer_gold_balance = get!(world, (game_id, caller, GOLD_ID), ItemBalance);

            // get seller balance
            let mut seller_gold_balance = get!(
                world, (game_id, trade.player_id, GOLD_ID), ItemBalance
            );

            // accept
            trade
                .accept_trade(
                    ref buyer_gold_balance, ref seller_gold_balance, ref buyer_item_balance, game_id
                );

            set!(world, (trade, buyer_gold_balance, seller_gold_balance, buyer_item_balance));
        }
        fn cancel_trade(self: @ContractState, game_id: u64, trade_id: u64) {
            let world = self.world_dispatcher.read();

            get!(world, (game_id), (Game)).active();

            let caller = get_caller_address();

            let mut trade = get!(world, (trade_id, game_id), Trade);

            assert(caller == trade.player_id, 'do not own order');

            let mut seller_item_balance = get!(
                world, (game_id, trade.player_id, trade.item_id), ItemBalance
            );

            trade.cancel_trade(ref seller_item_balance);

            set!(world, (trade, seller_item_balance));
        }
    }
}
