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
fn toto(pouet:pout) {
    pouet;
}
#[dojo::contract]
mod auctions {
    use traits::{Into, TryInto};
  
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