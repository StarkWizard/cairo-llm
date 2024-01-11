use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use beer_barron::components::game::{
    Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig
};
use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait ILobby<TContractState> {
    fn create_game(self: @TContractState, config: GameConfig) -> u64;
    fn join_game(
        self: @TContractState, game_id: u64, name: felt252, password: felt252
    ) -> ContractAddress;
    fn start_game(self: @TContractState, game_id: u64, auction_address: ContractAddress);
}

#[dojo::contract]
mod lobby {
    use traits::{Into, TryInto};
    use option::OptionTrait;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, get_block_hash_syscall
    };
    use beer_barron::components::{
        game::{Game, GameTracker, GameStatus, GameTrait, Ownership, GameConfig, Joined},
        player::Player, balances::ItemBalance,
    };

    use beer_barron::constants::{
        CONFIG::{
            SYSTEM_IDS::{GAME_CONFIG}, STARTING_BALANCES::{GOLD},
            ITEM_IDS::{GOLD_ID, HOP_SEEDS, BEERS},
        },
    };

    use beer_barron::systems::auctions::{auctions, IAuctionDispatcher, IAuctionDispatcherTrait};

    use super::ILobby;

    #[external(v0)]
    impl LobbyImpl of ILobby<ContractState> {
        fn create_game(self: @ContractState, config: GameConfig) -> u64 {
            let world = self.world_dispatcher.read();

            // game id increment
            let mut game_tracker = get!(world, (GAME_CONFIG), (GameTracker));
            let count: u64 = (game_tracker.count + 1).into();

            let seed = 5672635178472;

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
                seed
            };

            // set game
            set!(world, (game));

            // set game tracker
            set!(
                world,
                (GameTracker { entity_id: GAME_CONFIG.try_into().unwrap(), count: count.into() })
            );

            // set ownership
            set!(world, (Ownership { entity_id: count, owner: get_caller_address().into() }));

            count
        }

        fn join_game(
            self: @ContractState, game_id: u64, name: felt252, password: felt252
        ) -> ContractAddress {
            let world = self.world_dispatcher.read();

            // Assert game in lobby + password correct
            let mut game = get!(world, (game_id), (Game));
            game.lobby();
            game.check_password(password);

            // increase number of players
            game.number_players += 1;
            set!(world, (game));

            // add player to game with compound key
            let player_id = get_caller_address().into();
            set!(world, (Player { game_id, player_id, name }));

            set!(
                world,
                (ItemBalance {
                    game_id: game_id,
                    player_id: player_id,
                    item_id: GOLD_ID.try_into().unwrap(),
                    balance: GOLD.try_into().unwrap()
                })
            );

            // set joined
            set!(world, (Joined { game_id, address: get_caller_address().into(), joined: true }));

            get_caller_address()
        }
        fn start_game(self: @ContractState, game_id: u64, auction_address: ContractAddress) {
            let world = self.world_dispatcher.read();
            // Check if game exists and in lobby stage
            let mut game = get!(world, (game_id), (Game));
            game.lobby();

            game.number_players += 1; // increase number of players
            game.start_time = get_block_timestamp(); // set start time
            game.status = GameStatus::Started; // set game status

            let mut game_owner = get!(world, (game_id), (Ownership));
            assert(game_owner.owner == get_caller_address().into(), 'owner can only start');

            set!(world, (game));

            let auctions = IAuctionDispatcher { contract_address: auction_address };

            auctions.start_hops_auction(game_id, HOP_SEEDS::CHINOOK.try_into().unwrap());
            auctions.start_hops_auction(game_id, HOP_SEEDS::CITRA.try_into().unwrap());
            auctions.start_hops_auction(game_id, HOP_SEEDS::GALAXY.try_into().unwrap());
            auctions.start_hops_auction(game_id, HOP_SEEDS::CASCADE.try_into().unwrap());
            auctions.start_hops_auction(game_id, HOP_SEEDS::SAAZ.try_into().unwrap());
            auctions.start_hops_auction(game_id, HOP_SEEDS::FUGGLE.try_into().unwrap());

            auctions.start_beer_auction(game_id, BEERS::DRAGON_HIDE_BLAZE_IPA.try_into().unwrap());
            auctions.start_beer_auction(game_id, BEERS::MITHRIL_HAZE.try_into().unwrap());
            auctions
                .start_beer_auction(game_id, BEERS::OBSIDIAN_IMPERIAL_STOUT.try_into().unwrap());
            auctions.start_beer_auction(game_id, BEERS::RUBY_SOUR.try_into().unwrap());
            auctions.start_beer_auction(game_id, BEERS::DIAMOND_WHEAT_BEER.try_into().unwrap());
            auctions.start_beer_auction(game_id, BEERS::ETHEREAL_LAGER.try_into().unwrap());

            // start indulgence auction
            auctions.start_indulgences_auction(game_id);
        }
    }
}
