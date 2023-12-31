use cubit::f128::types::fixed::{Fixed, FixedTrait};
use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA, LogisticVRGDATrait};
use beer_barron::vrgda::vrgda::{ReverseLinearVRGDA, ReverseLinearVRGDATrait};
use beer_barron::components::balances::{ItemBalance, ItemBalanceTrait};
use traits::{Into, TryInto};
use option::OptionTrait;

use beer_barron::components::trading::{TradeStatus};

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct Auction {
    #[key]
    game_id: u64,
    #[key]
    item_id: u64,
    target_price: u128,
    decay_constant_mag: u128,
    decay_constant_sign: bool,
    max_sellable: u128,
    time_scale_mag: u128,
    time_scale_sign: bool,
    start_time: u64,
    sold: u64,
}

// we generate a trait here so we can construct the LogisticVRGDA from the remote library
#[generate_trait]
impl ImplAuction of AuctionTrait {
    fn to_LogisticVRGDA(self: Auction) -> LogisticVRGDA {
        LogisticVRGDA {
            target_price: FixedTrait::new_unscaled(self.target_price, false),
            decay_constant: FixedTrait::new(self.decay_constant_mag, self.decay_constant_sign),
            max_sellable: FixedTrait::new_unscaled(self.max_sellable, false),
            time_scale: FixedTrait::new(self.time_scale_mag, self.time_scale_sign)
        }
    }
    fn get_price(self: Auction) -> Fixed {
        // time since auction start

        let time_since_start: u128 = get_block_timestamp().into() - self.start_time.into();
        // get current price
        self
            .to_LogisticVRGDA()
            .get_vrgda_price(
                FixedTrait::new_unscaled(time_since_start / 60, false), // time since start
                FixedTrait::new_unscaled(self.sold.into(), false) // amount sold
            )
    }
}


#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct TavernAuction {
    #[key]
    game_id: u64,
    #[key]
    item_id: u64,
    target_price: u128,
    decay_constant_mag: u128,
    decay_constant_sign: bool,
    per_time_unit: u128,
    start_time: u64,
    sold: u64,
}

#[generate_trait]
impl ImplTavernAuction of TavernAuctionTrait {
    fn to_ReverseLinearVRGDA(self: TavernAuction) -> ReverseLinearVRGDA {
        ReverseLinearVRGDA {
            target_price: FixedTrait::new_unscaled(self.target_price, false),
            decay_constant: FixedTrait::new(self.decay_constant_mag, self.decay_constant_sign),
            per_time_unit: FixedTrait::new_unscaled(self.per_time_unit, false)
        }
    }
    fn get_price(self: TavernAuction) -> Fixed {
        // time since auction start
        let time_since_start: u128 = get_block_timestamp().into() - self.start_time.into();

        // get current price
        self
            .to_ReverseLinearVRGDA()
            .get_reverse_vrgda_price(
                FixedTrait::new_unscaled(time_since_start / 60, false), // time since start
                FixedTrait::new_unscaled(self.sold.into(), false) // amount sold
            )
    }
}


#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct IndulgenceAuction {
    #[key]
    game_id: u64,
    #[key]
    auction_id: u64, // count in the game  
    price: u64,
    highest_bid_player_id: ContractAddress,
    expiry: u64,
    auction_id_value: u64,
    status: u8, // claimed or not
}

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct IndulgenceAuctionCount {
    #[key]
    game_id: u64,
    count: u64,
}

#[generate_trait]
impl ImplIndulgenceAuction of IndulgenceAuctionTrait {
    fn set_new_price(
        ref self: IndulgenceAuction,
        ref new_bidder_gold_balance: ItemBalance,
        ref old_bidder_gold_balance: ItemBalance,
        game_id: u64,
        price: u64
    ) {
        assert(self.status == TradeStatus::OPEN, 'auction not open');
        assert(price > self.price, 'You have to bid more');
        assert(new_bidder_gold_balance.balance >= self.price, 'not enough gold');
        assert(self.game_id == game_id, 'game id does not match');
        assert(self.highest_bid_player_id != get_caller_address(), 'cannot accept self');
        assert(self.expiry > get_block_timestamp(), 'not expired');

        // update gold
        new_bidder_gold_balance.sub(price);
        old_bidder_gold_balance.add(price);

        self.highest_bid_player_id = get_caller_address();

        self.price = price;
    }
    fn claim_indulgence_and_increment(ref self: IndulgenceAuction, game_id: u64) {
        assert(self.game_id == game_id, 'game id does not match');
        assert(self.highest_bid_player_id == get_caller_address(), 'not winning bid');
        assert(self.expiry < get_block_timestamp(), 'not expired');

        self.status = TradeStatus::ACCEPTED;
    }
    fn assert_auction_expired(self: IndulgenceAuction) {
        assert(
            self.status == TradeStatus::OPEN || self.status == TradeStatus::ACCEPTED,
            'auction not open'
        );
        assert(self.expiry < get_block_timestamp(), 'not expired');
    }
}
