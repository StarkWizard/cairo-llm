#[system]
mod view_hop_price {
    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use beer_barron::components::auction::{Auction, AuctionTrait};

    fn execute(ctx: Context, game_id: u64, item_id: u128) -> Fixed {
        get!(ctx.world, (game_id, item_id), Auction).get_price()
    }
}
