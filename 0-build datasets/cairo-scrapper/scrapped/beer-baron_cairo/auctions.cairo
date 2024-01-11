use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::{ContractAddress, ClassHash};
use beer_barron::components::beer::{BeerID, get_beer_id_from_enum};
use cubit::f128::types::fixed::{Fixed, FixedTrait};

#[starknet::interface]
trait IAuction<TContractState> {
    fn start_hops_auction(self: @TContractState, game_id: u64, item_id: u64);
    fn start_beer_auction(self: @TContractState, game_id: u64, item_id: u64);
    fn sell_beer(self: @TContractState, game_id: u64, beer_id: BeerID, amount: u64);
    fn buy_hops(self: @TContractState, game_id: u64, item_id: u64, amount: u64);
    fn get_beer_price(self: @TContractState, game_id: u64, item_id: u64) -> Fixed;
    fn get_hop_price(self: @TContractState, game_id: u64, item_id: u64) -> Fixed;

    // indulgences
    fn start_indulgences_auction(self: @TContractState, game_id: u64);
    fn place_indulgences_bid(self: @TContractState, game_id: u64, price: u64);
    fn claim_indulgence(self: @TContractState, game_id: u64);
    fn increment_indulgences_auction(self: @TContractState, game_id: u64);
}

#[dojo::contract]
mod auctions {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use beer_barron::components::game::{
        Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig, Joined
    };

    use beer_barron::components::player::{Player};
    use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};

    use beer_barron::constants::CONFIG::{INDULGENCES::{AUCTION_LENGTH}};
    use beer_barron::constants::CONFIG::{SYSTEM_IDS::{INDULGENCE_COUNT}};
    use beer_barron::constants::{
        CONFIG::{
            STARTING_BALANCES::{GOLD}, ITEM_IDS::{GOLD_ID, INDULGENCE_ID},
            STARTING_PRICES::{HOP_SEED_STARTING_PRICE, BEERS_STARTING_PRICE}
        }
    };
    use beer_barron::constants::{CONFIG::{ITEM_IDS::{HOP_SEEDS, BEERS}}};

    use beer_barron::components::auction::{
        Auction, AuctionTrait, TavernAuction, TavernAuctionTrait, IndulgenceAuction,
        IndulgenceAuctionTrait, IndulgenceAuctionCount
    };

    use beer_barron::components::trading::{TradeStatus};

    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA};

    use beer_barron::components::beer::{BeerID, get_beer_id_from_enum};

    use super::IAuction;

    const _0_31: u128 = 571849066284996100;
    const MAX_SELLABLE: u128 = 1000;
    const _0_0023: u128 = 12427511369531970;

    const _0_11: u128 = 2071849066284996100;
    const PER_TIME_UNIT: u128 = 1;

    #[external(v0)]
    impl AuctionImpl of IAuction<ContractState> {
        fn start_hops_auction(self: @ContractState, game_id: u64, item_id: u64) {
            let world = self.world_dispatcher.read();
            // todo: check if auction already exists
            // todo: check game exists
            let mut game = get!(world, (game_id), (Game));
            // assert(game.status, 'game is not running');

            let auction = Auction {
                game_id,
                item_id,
                target_price: HOP_SEED_STARTING_PRICE.try_into().unwrap(),
                decay_constant_mag: _0_31,
                decay_constant_sign: true,
                max_sellable: MAX_SELLABLE,
                time_scale_mag: _0_0023,
                time_scale_sign: false,
                start_time: get_block_timestamp(), //update to timestamp
                sold: 0,
            };

            set!(world, (auction));
        }

        fn start_beer_auction(self: @ContractState, game_id: u64, item_id: u64) {
            let world = self.world_dispatcher.read();

            let mut game = get!(world, (game_id), (Game));
            // assert(game.status, 'game is not running');

            let auction = TavernAuction {
                game_id,
                item_id,
                target_price: BEERS_STARTING_PRICE.try_into().unwrap(),
                decay_constant_mag: _0_11,
                decay_constant_sign: true,
                per_time_unit: PER_TIME_UNIT,
                start_time: get_block_timestamp(),
                sold: 0,
            };

            set!(world, (auction));
        }

        fn sell_beer(self: @ContractState, game_id: u64, beer_id: BeerID, amount: u64) {
            let world = self.world_dispatcher.read();
            // assert that the game is active
            let game = get!(world, (game_id), (Game));
            game.active();

            let caller = get_caller_address();

            let mut auction = get!(
                world, (game_id, get_beer_id_from_enum(beer_id)).into(), (TavernAuction)
            );
            let mut gold_balance = get!(world, (game_id, caller, GOLD_ID), ItemBalance);
            let mut item_balance = get!(
                world, (game_id, caller, get_beer_id_from_enum(beer_id)), ItemBalance
            );

            auction.sold += amount;

            // we sell beer into the auction and in return get gold
            gold_balance.add(auction.get_price().try_into().unwrap() * amount);

            // we remove the beer amount from the player
            item_balance.sub(amount);

            set!(world, (auction, gold_balance, item_balance));
        }

        fn buy_hops(self: @ContractState, game_id: u64, item_id: u64, amount: u64) {
            let world = self.world_dispatcher.read();
            let caller = get_caller_address();
            // assert that the game is active
            let game = get!(world, (game_id), (Game));
            game.active();

            let mut auction = get!(world, (game_id, item_id), Auction);
            let mut gold_balance = get!(world, (game_id, caller, GOLD_ID), ItemBalance);
            let mut item_balance = get!(world, (game_id, caller, item_id), ItemBalance);

            // add to amount sold
            auction.sold += amount;

            // TODO: check this
            // subtract from gold
            // TODO: overflow check
            gold_balance.sub(auction.get_price().try_into().unwrap() * amount);

            // add to item balance
            item_balance.add(amount);

            set!(world, (auction, gold_balance, item_balance));
        }
        fn get_beer_price(self: @ContractState, game_id: u64, item_id: u64) -> Fixed {
            get!(self.world_dispatcher.read(), (game_id, item_id), TavernAuction).get_price()
        }

        fn get_hop_price(self: @ContractState, game_id: u64, item_id: u64) -> Fixed {
            get!(self.world_dispatcher.read(), (game_id, item_id), Auction).get_price()
        }

        // starts indulgence auction on new game
        fn start_indulgences_auction(self: @ContractState, game_id: u64) {
            let world = self.world_dispatcher.read();

            let mut game = get!(world, (game_id), (Game));

            let mut indulgence_count = get!(world, (game_id), (IndulgenceAuctionCount));
            indulgence_count.count += 1;

            // get current indulgence
            let indulgence = get!(world, (game_id, indulgence_count.count), (IndulgenceAuction));

            // TODO: Restrict this from being called twice...

            // set expiry
            // TODO: move this into game creation and base it off the length of the game
            let expiry = get_block_timestamp() + AUCTION_LENGTH;

            let indulgence_auction = IndulgenceAuction {
                game_id: game_id,
                auction_id: indulgence_count.count,
                price: 0,
                highest_bid_player_id: 0.try_into().unwrap(), // no bidder yet
                expiry,
                auction_id_value: indulgence_count.count,
                status: TradeStatus::OPEN // active
            };

            set!(world, (indulgence_auction, indulgence_count));
        }
        fn place_indulgences_bid(self: @ContractState, game_id: u64, price: u64) {
            let world = self.world_dispatcher.read();

            let caller = get_caller_address();

            let mut game = get!(world, (game_id), (Game));

            let indulgence_count = get!(world, (game_id), (IndulgenceAuctionCount));

            let mut indulgence_auction = get!(
                world, (game_id, indulgence_count.count), (IndulgenceAuction)
            );

            // get buyer balance
            let mut new_bidder_gold_balance = get!(world, (game_id, caller, GOLD_ID), ItemBalance);

            // get seller balance
            let mut old_bidder_gold_balance = get!(
                world, (game_id, indulgence_auction.highest_bid_player_id, GOLD_ID), ItemBalance
            );

            // set price
            indulgence_auction
                .set_new_price(
                    ref new_bidder_gold_balance, ref old_bidder_gold_balance, game_id, price
                );

            set!(world, (new_bidder_gold_balance, old_bidder_gold_balance, indulgence_auction));
        }
        fn claim_indulgence(self: @ContractState, game_id: u64) {
            let world = self.world_dispatcher.read();

            get!(world, (game_id), (Game)).active();

            let mut indulgence_count = get!(world, (game_id), (IndulgenceAuctionCount));

            let mut indulgence_auction = get!(
                world, (game_id, indulgence_count.count), (IndulgenceAuction)
            );

            indulgence_auction.claim_indulgence_and_increment(game_id);

            // update indulgence balance
            let mut bidder_indulgence_balance = get!(
                world,
                (game_id, indulgence_auction.highest_bid_player_id, INDULGENCE_ID),
                ItemBalance
            );
            bidder_indulgence_balance.add(1);

            set!(world, (bidder_indulgence_balance, indulgence_auction));
        }
        fn increment_indulgences_auction(self: @ContractState, game_id: u64) {
            let world = self.world_dispatcher.read();

            let mut game = get!(world, (game_id), (Game));

            let mut indulgence_count = get!(world, (game_id), (IndulgenceAuctionCount));

            // get current indulgence
            let mut current_indulgence_auction = get!(
                world, (game_id, indulgence_count.count), (IndulgenceAuction)
            );

            current_indulgence_auction.assert_auction_expired();

            indulgence_count.count += 1;

            let expiry = get_block_timestamp() + AUCTION_LENGTH;

            let indulgence_auction = IndulgenceAuction {
                game_id: game_id,
                auction_id: indulgence_count.count,
                price: 0,
                highest_bid_player_id: 0.try_into().unwrap(), // no bidder yet
                expiry,
                auction_id_value: indulgence_count.count,
                status: TradeStatus::OPEN // active
            };

            set!(world, (indulgence_count, indulgence_auction));
        }
    }
}
