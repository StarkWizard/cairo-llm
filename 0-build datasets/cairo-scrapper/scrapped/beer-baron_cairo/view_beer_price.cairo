#[system]
mod view_beer_price {
    use cubit::f128::types::fixed::{Fixed, FixedTrait};
    use dojo::world::Context;
    use beer_barron::components::auction::{TavernAuction, TavernAuctionTrait};

    fn execute(ctx: Context, game_id: u64, item_id: u128) -> Fixed {
        get!(ctx.world, (game_id, item_id), TavernAuction).get_price()
    }
}
