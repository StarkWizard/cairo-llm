#[cfg(test)]
mod test {
    use traits::{Into, TryInto};
    use core::result::ResultTrait;
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use box::BoxTrait;
    use clone::Clone;
    use debug::PrintTrait;
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    // dojo core imports
    use dojo::world::{IWorldDispatcherTrait, IWorldDispatcher};
    use dojo::test_utils::spawn_test_world;

    // project imports
    use beer_barron::components::auction::{
        Auction, AuctionTrait, auction, TavernAuction, tavern_auction
    };
    use beer_barron::components::balances::{ItemBalance, item_balance};
    use beer_barron::components::game::{
        Game, GameTracker, Ownership, game, game_tracker, ownership, GameConfig
    };
    use beer_barron::components::beer::{Brew, BrewBatchTrack, BeerID, brew, brew_batch_track};
    use beer_barron::components::player::{Player, FarmArea, player, farm_area};
    use beer_barron::components::trading::{Trade, trade};

    // systems
    use beer_barron::systems::lobby::{lobby, ILobbyDispatcher, ILobbyDispatcherTrait};
    use beer_barron::systems::auctions::{auctions, IAuctionDispatcher, IAuctionDispatcherTrait};
    use beer_barron::systems::farming::{farming, IFarmingDispatcher, IFarmingDispatcherTrait};
    use beer_barron::systems::brewing::{brewing, IBrewingDispatcher, IBrewingDispatcherTrait};
    use beer_barron::systems::trading::{trading, ITradingDispatcher, ITradingDispatcherTrait};

    // consts
    use beer_barron::constants::{
        CONFIG::{STARTING_BALANCES::{GOLD}, ITEM_IDS::{HOP_SEEDS, HOP_FLOWERS, BEERS, GOLD_ID}}
    };

    fn setup() -> IWorldDispatcher {
        // components
        let mut models = array![
            item_balance::TEST_CLASS_HASH,
            auction::TEST_CLASS_HASH,
            game::TEST_CLASS_HASH,
            game_tracker::TEST_CLASS_HASH,
            ownership::TEST_CLASS_HASH,
            player::TEST_CLASS_HASH,
            farm_area::TEST_CLASS_HASH,
            brew::TEST_CLASS_HASH,
            brew_batch_track::TEST_CLASS_HASH,
            tavern_auction::TEST_CLASS_HASH,
            trade::TEST_CLASS_HASH
        ];

        spawn_test_world(models)
    }

    fn deploy_system(world: IWorldDispatcher, hash: felt252) -> ContractAddress {
        world.deploy_contract('salt', hash.try_into().unwrap())
    }

    #[derive(Copy, Drop, Serde, SerdeLen)]
    struct SetupValues {
        world: IWorldDispatcher,
        lobby_system: ILobbyDispatcher,
        auction_system: IAuctionDispatcher,
        farming_system: IFarmingDispatcher,
        brewing_system: IBrewingDispatcher,
        trading_system: ITradingDispatcher
    }

    fn setup_world_with_systems() -> SetupValues {
        let mut world = setup();

        SetupValues {
            world,
            lobby_system: ILobbyDispatcher {
                contract_address: deploy_system(world, lobby::TEST_CLASS_HASH)
            },
            auction_system: IAuctionDispatcher {
                contract_address: deploy_system(world, auctions::TEST_CLASS_HASH)
            },
            farming_system: IFarmingDispatcher {
                contract_address: deploy_system(world, farming::TEST_CLASS_HASH)
            },
            brewing_system: IBrewingDispatcher {
                contract_address: deploy_system(world, brewing::TEST_CLASS_HASH)
            },
            trading_system: ITradingDispatcher {
                contract_address: deploy_system(world, trading::TEST_CLASS_HASH)
            }
        }
    }

    #[derive(Copy, Drop, Serde, SerdeLen)]
    struct StartValues {
        world: IWorldDispatcher,
        game_id: u64,
        player_id: ContractAddress,
        lobby_system: ILobbyDispatcher,
        auction_system: IAuctionDispatcher,
        farming_system: IFarmingDispatcher,
        brewing_system: IBrewingDispatcher,
        trading_system: ITradingDispatcher
    }


    const max_players: u32 = 1;
    const game_length: u32 = 900;
    const password: felt252 = 0;
    const entry_fee: u32 = 0;

    fn create_start() -> StartValues {
        let world_setup = setup_world_with_systems();

        // create game
        let config = GameConfig {
            max_players: max_players,
            game_length: game_length,
            password: password,
            entry_fee: entry_fee
        };
        let mut game_id = world_setup.lobby_system.create_game(config);
        assert(game_id == 1, 'game id wrong');

        // join game
        let name = 123;
        let mut player_id = world_setup.lobby_system.join_game(game_id, name, config.password);

        // start game
        starknet::testing::set_block_timestamp(1);
        world_setup.lobby_system.start_game(game_id, world_setup.auction_system.contract_address);

        // // hop auctions
        let auction_GALAXY = get!(
            world_setup.world, (game_id, HOP_SEEDS::GALAXY).into(), (Auction)
        );
        let auction_CHINOOK = get!(
            world_setup.world, (game_id, HOP_SEEDS::CHINOOK).into(), (Auction)
        );
        let auction_CITRA = get!(world_setup.world, (game_id, HOP_SEEDS::CITRA).into(), (Auction));
        assert(auction_GALAXY.start_time > 0, 'auction not started');
        assert(auction_CHINOOK.start_time > 0, 'auction not started');
        assert(auction_CITRA.start_time > 0, 'auction not started');

        // // beer auctions
        let dragonhide_ipa_market = get!(
            world_setup.world, (game_id, BEERS::DRAGON_HIDE_BLAZE_IPA).into(), (TavernAuction)
        );
        let mithril_haze_market = get!(
            world_setup.world, (game_id, BEERS::MITHRIL_HAZE).into(), (TavernAuction)
        );
        assert(dragonhide_ipa_market.start_time > 0, 'auction not started');
        assert(mithril_haze_market.start_time > 0, 'auction not started');

        StartValues {
            world: world_setup.world,
            game_id: game_id,
            player_id: player_id,
            lobby_system: world_setup.lobby_system,
            auction_system: world_setup.auction_system,
            farming_system: world_setup.farming_system,
            brewing_system: world_setup.brewing_system,
            trading_system: world_setup.trading_system
        }
    }

    fn player_buy_hops() -> StartValues {
        let game = create_start();

        let buy_quantity = 10;

        // game_id
        let game_id = game.game_id;
        let world = game.world;
        let player_id = game.player_id;

        game.auction_system.buy_hops(game_id, HOP_SEEDS::GALAXY.try_into().unwrap(), buy_quantity);
        game.auction_system.buy_hops(game_id, HOP_SEEDS::CITRA.try_into().unwrap(), buy_quantity);
        game.auction_system.buy_hops(game_id, HOP_SEEDS::CHINOOK.try_into().unwrap(), buy_quantity);

        let player_balance = get!(world, (game_id, player_id, GOLD_ID).into(), (ItemBalance));
        assert(player_balance.balance < GOLD.try_into().unwrap(), 'balance not updated');

        let galaxy_auction = get!(world, (game_id, HOP_SEEDS::GALAXY).into(), (Auction));
        assert(galaxy_auction.sold.into() == buy_quantity, 'auction not updated');

        let citra_auction = get!(world, (game_id, HOP_SEEDS::CITRA).into(), (Auction));
        assert(citra_auction.sold.into() == buy_quantity, 'auction not updated');

        let chinook_auction = get!(world, (game_id, HOP_SEEDS::CHINOOK).into(), (Auction));
        assert(chinook_auction.sold.into() == buy_quantity, 'auction not updated');

        game
    }


    fn player_build_farm() -> StartValues {
        let game = player_buy_hops();

        let mut arr = ArrayTrait::<u64>::new();
        arr.append(HOP_SEEDS::GALAXY.try_into().unwrap());
        arr.append(HOP_SEEDS::CITRA.try_into().unwrap());
        arr.append(HOP_SEEDS::CHINOOK.try_into().unwrap());
        arr.append(0);
        arr.append(0);
        arr.append(0);

        game.farming_system.build_farm(game.game_id, arr);

        game
    }

    fn player_harvest_farm() -> StartValues {
        let game = player_build_farm();

        starknet::testing::set_block_timestamp(2000);

        game.farming_system.harvest_farm(game.game_id);

        // TODO: Check values of farms

        game
    }

    fn player_brew_beer() -> StartValues {
        let game = player_harvest_farm();

        let mut brewing_system = IBrewingDispatcher {
            contract_address: deploy_system(game.world, brewing::TEST_CLASS_HASH)
        };

        brewing_system.brew_beer(game.game_id, BeerID::DragonHideBlazeIPA);

        game
    }

    fn player_bottle_beer() -> StartValues {
        let game = player_brew_beer();

        starknet::testing::set_block_timestamp(4000);

        game.brewing_system.bottle_beer(game.game_id, 1);

        let batch = get!(game.world, (game.game_id, game.player_id, 1).into(), (Brew));

        assert(batch.status == 2, 'batch not updated');

        game
    }

    #[test]
    #[available_gas(600000000)]
    fn test_start() {
        create_start();
    }
    #[test]
    #[available_gas(600000000)]
    fn test_buy_hops() {
        player_buy_hops();
    }
    #[test]
    #[available_gas(600000000)]
    fn test_build_farm() {
        player_build_farm();
    }

    #[test]
    #[available_gas(600000000)]
    fn test_harvest_farm() {
        player_harvest_farm();
    }
    #[test]
    #[available_gas(600000000)]
    fn test_brew_beer() {
        player_brew_beer();
    }
    #[test]
    #[available_gas(600000000)]
    fn test_bottle_beer() {
        player_bottle_beer();
    }
//     #[test]
//     #[available_gas(600000000)]
//     fn test_sell_beer() {
//         let (world, game_id, player_id) = player_bottle_beer();

//         world.execute('sell_beer', array![game_id.into(), 1, 1]);
//     }

//     #[test]
//     #[available_gas(600000000)]
//     fn test_create_hop_flower_trade() {
//         let (world, game_id, player_id) = player_harvest_farm();

//         let item_id = HOP_FLOWERS::GALAXY;
//         let quantity = 1;
//         let price = 1;

//         world
//             .execute(
//                 'create_trade',
//                 array![game_id.into(), item_id.into(), quantity.into(), price.into()]
//             );

//         let trade_id = 1;
//         world.execute('accept_trade', array![game_id.into(), trade_id.into()]);
//     }
}

