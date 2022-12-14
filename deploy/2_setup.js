const hre = require('hardhat');
const airnodeAdmin = require('@api3/airnode-admin');
const apis = require('../data/apis.json');

module.exports = async () => {
  const apiData = apis['ANU Quantum Random Numbers'];
  const account = (await hre.ethers.getSigners())[0];
  const QRNG = await hre.deployments.get('QRNG');
  const qrng = new hre.ethers.Contract(QRNG.address, QRNG.abi, account);

  // We are deriving the sponsor wallet address from the QrngExample contract address
  // using the @api3/airnode-admin SDK. You can also do this using the CLI
  // https://docs.api3.org/airnode/latest/reference/packages/admin-cli.html
  // Visit our docs to learn more about sponsors and sponsor wallets
  // https://docs.api3.org/airnode/latest/concepts/sponsor.html
  const sponsorWalletAddress = await airnodeAdmin.deriveSponsorWalletAddress(
    apiData.xpub,
    apiData.airnode,
    qrng.address
  );
  console.log(
    `endpointId: ${apiData.endpointIdUint256} wallet: ${sponsorWalletAddress} airnode: ${apiData.airnode}`
  );

  // Set the parameters that will be used to make Airnode requests
  const receipt = await qrng.setRequestParameters(
    apiData.airnode,
    apiData.endpointIdUint256,
    sponsorWalletAddress
  );
  console.log('Setting request parameters...');
  await new Promise((resolve) =>
    hre.ethers.provider.once(receipt.hash, () => {
      resolve();
    })
  );
  console.log('Request parameters set');
};
module.exports.tags = ['setup'];