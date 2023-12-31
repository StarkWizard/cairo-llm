use starknet::ContractAddress;

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct Player {
    #[key]
    game_id: u64,
    #[key]
    player_id: ContractAddress,
    name: felt252
}

#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct FarmArea {
    #[key]
    game_id: u64,
    #[key]
    player_id: ContractAddress,
    #[key]
    area_id: u64, // area_id is the index of the area in the player's array of areas
    area_type: u64, // crop type
    time_built: u64, // built time
}
