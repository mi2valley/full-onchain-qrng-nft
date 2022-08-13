const hre = require('hardhat');

async function main() {
  const QRNG = await hre.deployments.get('QRNG');
  const qrng = new hre.ethers.Contract(QRNG.address, QRNG.abi, (await hre.ethers.getSigners())[0]);

  // Make a request...
  const receipt = await qrng.requestRandomCharacter();
  console.log('Created a request transaction, waiting for it to be confirmed...');

  await receipt.wait();

  // and read the logs once it gets confirmed to get the request ID
  const requestId = await new Promise((resolve) =>
    hre.ethers.provider.once(receipt.hash, (tx) => {
      // We want the log from QrngExample, not AirnodeRrp
      const log = tx.logs.find((log) => log.address === qrng.address);
      const parsedLog = qrng.interface.parseLog(log);
      resolve(parsedLog.args.requestId);
    })
  );
  console.log(`Transaction is confirmed, request ID is ${requestId}`);
  console.log('Waiting for the fulfillment transaction...');
  const log = await new Promise((resolve) =>
    hre.ethers.provider.once(qrng.filters.ReceivedUint256(requestId, null), resolve)
  );
  const parsedLog = qrng.interface.parseLog(log);
  const randomNumber = parsedLog.args.response;
  console.log(`Fulfillment is confirmed, random number is ${randomNumber.toString()}`);

  console.log("Minted NFT");

  // Wait for the fulfillment transaction to be confirmed and read the logs to get the random number

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });