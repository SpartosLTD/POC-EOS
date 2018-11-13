const eos = require('eosjs')({
  keyProvider: process.env.KEY,
  httpEndpoint: process.env.URL,
  verbose: process.env.VERBOSE == true,
  sign: true,
  expireInSeconds: 6000
});
const fs = require('fs');

let transactionId = parseInt(process.argv[2]);

let amount = parseFloat((transactionId+1) / 10000).toFixed(4);

console.log("AMOUNT: " + amount);

eos.transaction(
  {
    actions: [
      {
        account: 'spartosbet',
        name: 'bet',
        authorization: [{
          actor: `${process.env.ACCOUNT}`,
          permission: 'active'
        }],
        data: {
          player: `${process.env.ACCOUNT}`,
          amount: `${amount} SYS`,
          direction: ((transactionId % 2 == 0) ? 1 : 0)
        }
      }
    ]
  }, {
    authorization: `${process.env.ACCOUNT}`,
    broadcast: false,
    expireInSeconds: 3600
  }
).then(result => {
  let outputFile = `${process.env.OUTPUT_FOLDER}/${transactionId}.json`;

  const transaction = result.transaction;

  fs.writeFile(outputFile, JSON.stringify(transaction, null, 2), function (err) {
    if (err) {
      console.log(`Error saving file to ${outputFile}:`);
      console.error(err);
      process.exit(1);
    } else {
      console.log(`JSON saved to  ${outputFile}!`);
    }
  });
}).catch(err => {
  console.error(err);
  process.exit(1);
});