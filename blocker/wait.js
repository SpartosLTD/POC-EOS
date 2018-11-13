const eos = require('eosjs')({
  httpEndpoint: process.env.EOS_NODE_URL,
  verbose: true,
  sign: false
});

let transactionId = process.argv[2];

const pause = (duration) => new Promise(res => setTimeout(res, duration));

const retry = async (retries, delay = 250) => {
  try {
    // console.log('trying...');
    let result = await eos.getTransaction(transactionId);

    if (typeof result.block_num === 'undefined') {
      throw new Error('No block_num yet...');
    } else {
      console.log('included in block #' + result.block_num);
    }
  } catch (err) {
    // console.log('catching...');
    console.error(err);
    if (retries > 1) {
      // console.log('retrying...');
      await pause(delay);
      await retry(retries - 1, delay * 2);
    } else {
      // console.log('rejecting...');
      throw new Error('Could not find transaction, even after retrying...');
    }
  }
}

(async function () {
  try {
    await retry(3);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
})();