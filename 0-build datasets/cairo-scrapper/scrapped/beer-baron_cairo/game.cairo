#[system]
mod create_game {
    use array::ArrayTrait;
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use dojo::world::Context;
    use option::OptionTrait;
    use starknet::{get_block_timestamp};

    use beer_barron::components::game::{
        Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig
    };
    use beer_barron::constants::CONFIG::{SYSTEM_IDS::{GAME_CONFIG}};


    fn execute(ctx: Context, config: GameConfig) -> u64 {
        // game id increment
        let mut game_tracker = get!(ctx.world, (GAME_CONFIG), (GameTracker));
        let count: u64 = (game_tracker.count + 1).into();

        // set config
        let mut game = Game {
            game_id: count,
            start_time: 0,
            status: GameStatus::Lobby,
            number_players: 0,
            max_players: config.max_players,
            game_length: config.game_length,
            password: config.password,
            entry_fee: config.entry_fee,
        };

        // set game
        set!(ctx.world, (game));

        // set game tracker
        set!(
            ctx.world,
            (GameTracker { entity_id: GAME_CONFIG.try_into().unwrap(), count: count.into() })
        );

        // set ownership
        set!(ctx.world, (Ownership { entity_id: count, owner: ctx.origin.into() }));

        count
    }
}

#[system]
mod join_game {
    use array::ArrayTrait;
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use dojo::world::Context;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    use beer_barron::components::game::{Game, GameTracker, GameTrait, Joined};
    use beer_barron::components::player::{Player};
    use beer_barron::components::balances::{ItemBalance};

    use beer_barron::constants::{CONFIG::{STARTING_BALANCES::{GOLD}, ITEM_IDS::{GOLD_ID}}};

    // adds player to the game
    // TODO: Add Lords Deposit
    fn execute(ctx: Context, game_id: u64, name: felt252, password: felt252) -> ContractAddress {
        // Assert game in lobby + password correct
        let mut game = get!(ctx.world, (game_id), (Game));
        game.lobby();
        game.check_password(password);

        // increase number of players
        game.number_players += 1;
        set!(ctx.world, (game));

        // add player to game with compound key
        let player_id = ctx.origin;
        set!(ctx.world, (Player { game_id, player_id, name }));

        set!(
            ctx.world,
            (ItemBalance {
                game_id: game_id,
                player_id: player_id,
                item_id: GOLD_ID.try_into().unwrap(),
                balance: GOLD.try_into().unwrap()
            })
        );

        // set joined
        set!(ctx.world, (Joined { game_id, address: ctx.origin.into(), joined: true }));

        ctx.origin
    }
}

//
// TODO:
//
#[system]
mod start_game {
    use array::ArrayTrait;
    use box::BoxTrait;
    use traits::{Into, TryInto};
    use dojo::world::Context;
    use option::OptionTrait;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    use beer_barron::components::game::{Game, GameTracker, GameTrait, GameStatus, Ownership};
    use beer_barron::components::player::{Player};

    use beer_barron::constants::{CONFIG::{ITEM_IDS::{HOP_SEEDS, BEERS}}};

    // adds player to the game
    // TODO: Add Lords Deposit
    fn execute(ctx: Context, game_id: u64) {
        // Check if game exists and in lobby stage
        let mut game = get!(ctx.world, (game_id), (Game));
        game.lobby();

        game.number_players += 1; // increase number of players
        game.start_time = get_block_timestamp(); // set start time
        game.status = GameStatus::Started; // set game status

        let mut game_owner = get!(ctx.world, (game_id), (Ownership));
        assert(game_owner.owner == ctx.origin.into(), 'owner can only start');

        set!(ctx.world, (game));

        // Start hop auctions
        ctx.world.execute('start_hops_auction', array![game_id.into(), HOP_SEEDS::CHINOOK.into()]);
        ctx.world.execute('start_hops_auction', array![game_id.into(), HOP_SEEDS::CITRA.into()]);
        ctx.world.execute('start_hops_auction', array![game_id.into(), HOP_SEEDS::GALAXY.into()]);

        // start beer auctions
        ctx
            .world
            .execute(
                'start_beer_auction', array![game_id.into(), BEERS::DRAGON_HIDE_BLAZE_IPA.into()]
            );
        ctx.world.execute('start_beer_auction', array![game_id.into(), BEERS::MITHRIL_HAZE.into()]);
        ctx
            .world
            .execute(
                'start_beer_auction', array![game_id.into(), BEERS::OBSIDIAN_IMPERIAL_STOUT.into()]
            );
    }
}
