#[system]
mod build_farm {
    use array::ArrayTrait;
    use array::SpanTrait;
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use dojo::world::Context;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    use beer_barron::components::game::{Game, GameTracker, GameTrait};
    use beer_barron::components::player::{Player};
    use beer_barron::components::player::{FarmArea};
    use beer_barron::components::balances::{ItemBalance};

    use beer_barron::constants::{CONFIG::{FARMING::{PLOT_COUNT}}};

    fn execute(ctx: Context, game_id: u64, area_type: Span<u64>) {
        // assert that the game is active
        let game = get!(ctx.world, (game_id), (Game));
        game.active();

        assert(area_type.len() == PLOT_COUNT.try_into().unwrap(), 'you must submit 6 areas');

        // MAX AREAS = NUMBER_OF_FARM_PLOTS
        let mut area_id: usize = 0;

        // loop through all areas
        loop {
            if area_id >= area_type.len() {
                break;
            }

            let item_type = *area_type[area_id];

            if item_type != 0 {
                // check if player has enough items and subtract
                let mut item_balance = get!(
                    ctx.world, (game_id, ctx.origin, item_type), (ItemBalance)
                );
                assert(item_balance.balance > 0, 'you do not have enough items');
                item_balance.balance -= 1;
                set!(ctx.world, (item_balance));

                set!(
                    ctx.world,
                    FarmArea {
                        game_id,
                        player_id: ctx.origin,
                        area_id: area_id.into(),
                        area_type: item_type,
                        time_built: get_block_timestamp()
                    }
                );
            }

            area_id += 1;
        }
    }
}
