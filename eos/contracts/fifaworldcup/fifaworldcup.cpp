#include "fifaworldcup.hpp"

using namespace eosio;

void FIFAWorldCup::bet(const account_name player, const asset amount, const char direction){
    require_auth(player);

    print("Betting\n");
    print("Player   : ", player, "\n");
    print("Amount   : ", amount, "\n");

    eosio_assert(direction == 0 || direction == 1, "Direction should be '0' or '1'");

    //Only accept bets if event is pending to start
    assert_eventPending();

    //Transfering the amount to _self account
    action(
        permission_level{player, N(active) },
        N(eosio.token), N(transfer),
        std::make_tuple(player, _self, amount, std::string("for current bet"))
    ).send();

    //Accessing the bets table
    betPlayers players(_self, _self);

    auto iterator = players.find(player);
    if (iterator != players.end()) {
        //Updating existing bet
        players.modify(iterator, _self, [&](auto& p) {
            print("Updating bet for player: ", p.player, "\n");

            if (p.bet.count(direction) == 0) {
                print("Adding opposite bet: ", p.player, "\n");
                Bet bet = {direction, amount, true};
                p.bet.insert( std::pair<char,Bet> (direction, bet));
            }
            else { 
                print("Increasing bet amount: ", p.player, "\n");
                p.bet.at(direction).amount += amount; 
            }            
        });
    } 
    else {
        //Creating a new bet
        players.emplace(_self, [&](auto& p) {
            print("Creating a new bet for player: ", player, "\n");

            Bet bet = {direction, amount, true};

            std::map<char, Bet> betMap;
            betMap.insert( std::pair<char,Bet> (direction, bet));

            p.player = player;
            p.bet = betMap;
        });
    }
}

//@abi action
void FIFAWorldCup::result(){
    require_auth(_self);

    print("Checking the result\n");

    //Only check results if event is completed
    assert_eventCompleted();

    //Accessing the bets table
    betPlayers players(_self, _self);

    //Looping thought the players and their bets
    for (auto& p : players) {

        print("Checking the result for user ", p.player, "\n");

        if (p.bet.count(getResultDirection()) != 0) {
            print("Player has a bet on the winner\n");

            action(
                permission_level{_self, N(active) },
                N(eosio.token), N(transfer),
                std::make_tuple(_self, p.player, (p.bet.at(getResultDirection()).amount*2), std::string("winner of bet"))
            ).send();
        }

        print("==Finishing==\n");
    }

    //Removing all bets
    auto ite = players.begin();
    while (ite != players.end()) {
        ite = players.erase(ite);
    }
}

//@abi action
void FIFAWorldCup::risk(){
    asset homerisk = asset(0, CORE_SYMBOL);
    asset awayrisk = asset(0, CORE_SYMBOL);

    //Accessing the bets table
    betPlayers players(_self, _self);

    //Looping thought the players and their bets
    for (auto& p : players) {
        print("PLAYER= ", p.player, "\n");

        if (p.bet.count(0) != 0) {
            Bet homeBet = p.bet.at(0);
            if (homeBet.active) {
                print("HOME= ", homeBet.amount, "\n");
                homerisk += homeBet.amount;
            }
        }

        if (p.bet.count(1) != 0) {
            Bet awayBet = p.bet.at(1);
            if (awayBet.active) {
                print("AWAY= ", awayBet.amount, "\n");
                awayrisk += awayBet.amount;
            }
        }
    }

    //Tells us how much to place to balance risk to 0. If negative then we need to bet on home, and vice-versa
    print("RISK: ", homerisk - awayrisk, "\n");
}

void FIFAWorldCup::oracledata(const int64_t id, const std::string name, const std::string description, 
    const int64_t startDate, const std::string status, const std::string homeTeam, const std::string awayTeam, 
    const std::string result, const std::string winning) {

    //For testing purposes I am setting up the contract account as the oracle.
    require_auth(_self);

    //Accessing oracle table
    oracleData oc(_self, _self);

    //Finding if oracle data already exists
    auto iterator = oc.find(_self);

    if (iterator != oc.end()) {
        print("Updating oracle data");
        
        oc.modify(iterator, _self, [&](auto& o) {
            o.id = id;
            o.name = name;
            o.description = description;
            o.startDate = startDate;
            o.status = status;
            o.homeTeam = homeTeam;
            o.awayTeam = awayTeam;
            o.result = result;
            o.winning = winning;
        });
    }
    else {
        print("Adding oracle data");

        oc.emplace(_self, [&](auto& o) {
            o.account = _self;
            o.id = id;
            o.name = name;
            o.description = description;
            o.startDate = startDate;
            o.status = status;
            o.homeTeam = homeTeam;
            o.awayTeam = awayTeam;
            o.result = result;
            o.winning = winning;
        });
    }
}

char FIFAWorldCup::getResultDirection() {
    assert_eventCompleted();

    //Accessing oracle table
    oracleData oc(_self, _self);

    auto iterator = oc.find(_self);
    eosio_assert(iterator != oc.end(), "Oracle data is not set");

    //Getting the last oracle information
    auto ocData = oc.get(_self);

    if (ocData.winning.compare("home")) {
        return 0;
    }
    else {
        return 1;
    }
}

void FIFAWorldCup::assert_eventCompleted() {
    //Accessing oracle table
    oracleData oc(_self, _self);

    auto iterator = oc.find(_self);
    eosio_assert(iterator != oc.end(), "Oracle data is not set");

    //Getting the last oracle information
    auto ocData = oc.get(_self);

    print("ORACLE STATUS = ", ocData.status, "\n");

    eosio_assert(ocData.status.compare(COMPLETED) == 0, "Event is not completed");
}

void FIFAWorldCup::assert_eventPending() {
    //Accessing oracle table
    oracleData oc(_self, _self);

    auto iterator = oc.find(_self);
    eosio_assert(iterator != oc.end(), "Oracle data is not set");

    //Getting the last oracle information
    auto ocData = oc.get(_self);

    print("ORACLE STATUS = ", ocData.status, "\n");

    eosio_assert(ocData.status.compare(PENDING) == 0, "Event is not pending");
}

EOSIO_ABI(FIFAWorldCup, (bet)(result)(risk)(oracledata))