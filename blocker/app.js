const express = require('express');
const app = express();

const port = process.env.PORT || 80;

const bodyParser = require('body-parser');
app.use(bodyParser.json());

const eos = require('eosjs')({
  httpEndpoint: process.env.EOS_NODE_URL,
  // verbose: program.verbose,
  sign: false
});

const { fork } = require('child_process');

app.post('/', async (req, res) => {
  try {
    let processedTransaction = await eos.pushTransaction(req.body);

    fork('wait.js', [processedTransaction.transaction_id], { env: { EOS_NODE_URL: process.env.EOS_NODE_URL } }).on('exit', (code, signal) => {
      if (code == 0) {
        res.sendStatus(200);
      } else {
        res.status(502).send(`Fork exited with code: <pre>${code}</pre> due to signal: <pre>${signal}</pre>`);
      }
    }).on('error', (err) => {
      res.status(502).send(`Fork exited with error: <pre>${error}</pre>`);
    });

  } catch (err) {
    console.error(err);
    res.status(500).send(`Exited with error: <pre>${err}</pre>`);
  }
});

app.listen(port, () => console.log(`Blocker listening on port ${port}!`))