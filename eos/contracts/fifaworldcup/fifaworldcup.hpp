#include <eosiolib/eosio.hpp>
#include <eosiolib/print.hpp>
#include <eosiolib/asset.hpp>
#include <string>
#include <map>

using namespace eosio;

class FIFAWorldCup : public eosio::contract {
    protected:
        //event statuses
        std::string const PENDING   = "PENDING-TO-START";
        std::string const STARTED   = "STARTED";
        std::string const COMPLETED = "COMPLETED";

    public:
        FIFAWorldCup(account_name self) : contract(self){};

        struct Bet {
            char direction;
            asset amount;
            bool active = false;

            uint64_t primary_key() const { return direction; }

            EOSLIB_SERIALIZE(Bet, (direction)(amount)(active))
        };

        struct BetPlayer {
            account_name player;
            std::map<int8_t, Bet> bet;

            uint64_t primary_key() const { return player; }

            EOSLIB_SERIALIZE(BetPlayer, (player)(bet))
        };

        typedef multi_index<N(BetPlayer), BetPlayer> betPlayers;

        //Struct with data spected from the oracle
        //@abi table bets OracleData
        struct OracleData {
            int64_t account;
            int64_t id;
            std::string name;
            std::string description;
            int64_t startDate;
            std::string status;
            std::string homeTeam;
            std::string awayTeam;
            std::string result;
            std::string winning;

            int64_t primary_key() const { return account; }

            EOSLIB_SERIALIZE(OracleData, (account)(id)(name)(description)(startDate)(status)(homeTeam)(awayTeam)(result)(winning))
        };

        typedef multi_index<N(OracleData), OracleData> oracleData;

        //@abi action
        void bet(const account_name player, const asset amount, const char direction);

        //@abi action
        void result();
 
        //@abi action
        void risk();

        //@abi action
        void oracledata(const int64_t id, const std::string name, const std::string description, 
            const int64_t startDate, const std::string status, const std::string homeTeam, const std::string awayTeam, 
            const std::string result, const std::string winning);

    private:
        char getResultDirection();
        void assert_eventCompleted();
        void assert_eventPending();
};


