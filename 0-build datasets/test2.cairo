// commentaire
fn toto() {
    cool;
}

#[dojo::contract]
mod trading {


    use beer_barron::components::trading::{
        Trade, TradeStatus, TradeTrack, TradeTrait
    };


    #[external(v0)]
    impl TradingImpl of ITrading<ContractState> {
        // fonction bidon
        fn create_trade(
            self: @ContractState, game_id: u64, item_id: u64, quantity: u64, price: u64
        ) {
            let world = self.world_dispatcher.read();
            if(toto)
            {
                toto
            }
        }

        fn accept_trade(self: @ContractState, game_id: u64, trade_id: u64) {
            let world = self.world_dispatcher.read();

        }
        fn cancel_trade(self: @ContractState, game_id: u64, trade_id: u64) {
            let world = self.world_dispatcher.read();

        }
    }
}

