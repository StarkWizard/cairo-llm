use starknet::ContractAddress;
use dojo_defi::dutch_auction::vrgda::{LogisticVRGDA};
use cubit::f128::types::fixed::{Fixed, FixedTrait};

// All Items use this, they are internal tokens
#[derive(Model, Copy, Drop, Serde, SerdeLen)]
struct ItemBalance {
    #[key]
    game_id: u64,
    #[key]
    player_id: ContractAddress,
    #[key]
    item_id: u64,
    balance: u64,
}

#[generate_trait]
impl ImplItemBalance of ItemBalanceTrait {
    fn add(ref self: ItemBalance, amount: u64) {
        self.balance += amount
    }
    fn sub(ref self: ItemBalance, amount: u64) {
        self.balance -= amount
    }
    fn assert_balance(ref self: ItemBalance, amount: u64) {
        assert(self.balance >= amount, 'Insufficient balance')
    }
}
