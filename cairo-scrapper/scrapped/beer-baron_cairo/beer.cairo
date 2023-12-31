use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
use serde::Serde;
use beer_barron::constants::{CONFIG::{BREWING::{BREW_TIME}, ITEM_IDS::{BEERS}}};
use traits::{Into, TryInto};
use option::OptionTrait;

// this could a generalised component in the future with the FarmArea
// TODO: Can drop player_id and just use owner check
#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct Brew {
    #[key]
    game_id: u64,
    #[key]
    player_id: ContractAddress,
    #[key]
    batch_id: u64, // players can brew in parallel so we just use a uuid here
    batch_key: u64, // this needs removing - it is so the client knows which batch to update
    owner: ContractAddress,
    beer_id: u64, // crop type
    time_built: u64, // built time
    status: u64, // 0 = not built, 1 = built, 2 = harvested
}

mod BrewStatus {
    const not_started: u64 = 0;
    const brewing: u64 = 1;
    const bottled: u64 = 2;
}

#[generate_trait]
impl ImplBrew of BrewTrait {
    fn assert_built(self: Brew) {
        assert(self.status == BrewStatus::brewing, 'BREW: not brewing');
    }
    fn assert_brewed(self: Brew) {
        let time_since_build = get_block_timestamp() - self.time_built;
        assert(time_since_build > BREW_TIME.try_into().unwrap(), 'BREW: not ready');
    }
}


// This will track batch numbers in games
#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct BrewBatchTrack {
    #[key]
    game_id: u64,
    owner: ContractAddress,
    count: u64
}

#[derive(Drop, Copy, PartialEq, Serde)]
struct Recipe {
    citra: u64,
    chinook: u64,
    galaxy: u64,
    cascade: u64,
    saaz: u64,
    fuggle: u64,
}


// We use a helper ENUM here so we can match on the beer_id in the inputs

#[derive(Drop, Copy, PartialEq, Serde)]
enum BeerID {
    None: (),
    DragonHideBlazeIPA,
    MithrilHaze,
    ObsidianImperialStout,
    RubySour,
    DiamondWheatBeer,
    EtherealLager,
}


fn get_beer_id_from_enum(beer_id: BeerID) -> u64 {
    match beer_id {
        BeerID::None(_) => 0,
        BeerID::DragonHideBlazeIPA(_) => BEERS::DRAGON_HIDE_BLAZE_IPA.try_into().unwrap(),
        BeerID::MithrilHaze(_) => BEERS::MITHRIL_HAZE.try_into().unwrap(),
        BeerID::ObsidianImperialStout(_) => BEERS::OBSIDIAN_IMPERIAL_STOUT.try_into().unwrap(),
        BeerID::RubySour(_) => BEERS::RUBY_SOUR.try_into().unwrap(),
        BeerID::DiamondWheatBeer(_) => BEERS::DIAMOND_WHEAT_BEER.try_into().unwrap(),
        BeerID::EtherealLager(_) => BEERS::ETHEREAL_LAGER.try_into().unwrap(),
    }
}

fn get_recipe(beer_id: BeerID, seed: u64) -> Recipe {
    match beer_id {
        BeerID::None(_) => Recipe {
            citra: 0, chinook: 0, galaxy: 0, cascade: 0, saaz: 0, fuggle: 0
        },
        BeerID::DragonHideBlazeIPA(_) => generate_random_recipe(seed, 1),
        BeerID::MithrilHaze(_) => generate_random_recipe(seed, 2),
        BeerID::ObsidianImperialStout(_) => generate_random_recipe(seed, 3),
        BeerID::RubySour(_) => generate_random_recipe(seed, 4),
        BeerID::DiamondWheatBeer(_) => generate_random_recipe(seed, 5),
        BeerID::EtherealLager(_) => generate_random_recipe(seed, 6),
    }
}

fn generate_random_recipe(seed: u64, offset: u64) -> Recipe {
    let citra = (seed * offset * 17) % 50;
    let chinook = (seed * offset * 23) % 50;
    let galaxy = (seed * offset * 67) % 50;
    let cascade = (seed * offset * 123) % 50;
    let saaz = (seed * offset * 89) % 50;
    let fuggle = (seed * offset * 45) % 50;

    Recipe { citra, chinook, galaxy, cascade, saaz, fuggle }
}
