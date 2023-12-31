#[system]
mod harvest_farm {
    use array::ArrayTrait;
    use array::SpanTrait;
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use dojo::world::Context;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    use beer_barron::components::game::{Game, GameTrait};
    use beer_barron::components::player::{Player};
    use beer_barron::components::player::{FarmArea};
    use beer_barron::components::balances::{ItemBalance};

    use beer_barron::constants::{
        CONFIG::{
            ITEM_IDS::{SEED_TO_FLOWER_OFFSET}, FARMING::{PLOT_COUNT, CROP_GROWTH_TIME, CROP_YIELD}
        }
    };

    fn execute(ctx: Context, game_id: u64) {
        // assert that the game is active
        let game = get!(ctx.world, (game_id), (Game));
        game.active();

        // MAX AREAS = PLOT_COUNT
        let mut area_id: usize = 0;

        // loop through all areas
        loop {
            if area_id >= PLOT_COUNT.try_into().unwrap() {
                break;
            }

            let mut farm_area = get!(ctx.world, (game_id, ctx.origin, area_id), (FarmArea));

            if farm_area.area_type != 0 {
                let time_since_build = get_block_timestamp() - farm_area.time_built;

                // harvest and reset
                if (time_since_build > CROP_GROWTH_TIME.try_into().unwrap()) {
                    // get grown hop balance - see consts file
                    // grown item is the hop + 10 for ids
                    let mut item_balance = get!(
                        ctx.world,
                        (
                            game_id,
                            ctx.origin,
                            farm_area.area_type + SEED_TO_FLOWER_OFFSET.try_into().unwrap()
                        ),
                        (ItemBalance)
                    );
                    // reset time and area
                    item_balance.balance += CROP_YIELD.try_into().unwrap();

                    let updated_farm = FarmArea {
                        game_id,
                        player_id: ctx.origin,
                        area_id: area_id.into(),
                        area_type: 0,
                        time_built: 0
                    };
                    set!(ctx.world, (updated_farm, item_balance));
                }
            }

            area_id += 1;
        }
    }
}
