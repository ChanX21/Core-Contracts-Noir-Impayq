import { getSchnorrAccount } from "@aztec/accounts/schnorr";
import { getDeployedTestAccountsWallets } from "@aztec/accounts/testing";
import {
  Fr,
  GrumpkinScalar,
  type PXE,
  PrivateFeePaymentMethod,
  createLogger,
  createPXEClient,
  getFeeJuiceBalance,
  waitForPXE,
} from "@aztec/aztec.js";
import { timesParallel } from "@aztec/foundation/collection";
import { TokenContract } from "@aztec/noir-contracts.js/Token";
import { MerchantsContract } from "./artifacts/Merchants.js";
import { BundlerContract } from "./artifacts/Bundler.js";

import { format } from "util";
import type { AztecAddress, Logger, Wallet } from "@aztec/aztec.js";
import { createConsoleLogger } from "@aztec/foundation/log";

export async function deployToken(
  adminWallet: Wallet,
  initialAdminBalance: bigint,
  logger: Logger
) {
  logger.info(`Deploying Token contract...`);
  const contract = await TokenContract.deploy(
    adminWallet,
    adminWallet.getAddress(),
    "USD",
    "USDC",
    18
  )
    .send()
    .deployed();

  if (initialAdminBalance > 0n) {
    // Minter is minting to herself so contract as minter is the same as contract as recipient
    await mintTokensToPrivate(
      contract,
      adminWallet,
      adminWallet.getAddress(),
      initialAdminBalance
    );
    await mintTokensToPublic(
      contract,
      adminWallet,
      adminWallet.getAddress(),
      initialAdminBalance
    );
  }

  logger.info("L2 contract deployed");

  return contract;
}
export async function mintTokensToPublic(
  token: TokenContract,
  minterWallet: Wallet,
  recipient: AztecAddress,
  amount: bigint
) {
  const tokenAsMinter = await TokenContract.at(token.address, minterWallet);
  const from = minterWallet.getAddress(); // we are setting from to minter here because we need a sender to calculate the tag
  await tokenAsMinter.methods.mint_to_public(recipient, amount).send().wait();
}
export async function mintTokensToPrivate(
  token: TokenContract,
  minterWallet: Wallet,
  recipient: AztecAddress,
  amount: bigint
) {
  const tokenAsMinter = await TokenContract.at(token.address, minterWallet);
  const from = minterWallet.getAddress(); // we are setting from to minter here because we need a sender to calculate the tag
  await tokenAsMinter.methods
    .mint_to_private(from, recipient, amount)
    .send()
    .wait();
}

const { PXE_URL = "http://localhost:8080" } = process.env;

// 35.228.247.23:8080

async function main() {
  ////////////// CREATE THE CLIENT INTERFACE AND CONTACT THE SANDBOX //////////////
  const logger = createLogger("e2e:token");

  // We create PXE client connected to the sandbox URL
  const pxe = createPXEClient(PXE_URL);
  // Wait for sandbox to be ready
  await waitForPXE(pxe, logger);

  const nodeInfo = await pxe.getNodeInfo();

  logger.info(format("Aztec Sandbox Info ", nodeInfo));

  ////////////// LOAD SOME ACCOUNTS FROM THE SANDBOX //////////////
  // The sandbox comes with a set of created accounts. Load them
  const accounts = await getDeployedTestAccountsWallets(pxe);
  const aliceWallet = accounts[0];
  const bobWallet = accounts[1];
  const alice = aliceWallet.getAddress();
  const bob = bobWallet.getAddress();
  logger.info(`Loaded alice's account at ${alice.toString()}`);
  logger.info(`Loaded bob's account at ${bob.toString()}`);

  ////////////// DEPLOY OUR TOKEN CONTRACT //////////////
  const initialSupply = 1_000_000n;

  const tokenContractAlice = await deployToken(
    aliceWallet,
    initialSupply,
    logger
  );

  ////////////// QUERYING THE TOKEN BALANCE FOR EACH ACCOUNT //////////////

  // Bob wants to mint some funds, the contract is already deployed, create an abstraction and link it his wallet
  // Since we already have a token link, we can simply create a new instance of the contract linked to Bob's wallet
  const tokenContractBob = tokenContractAlice.withWallet(bobWallet);

  let aliceBalance = await tokenContractAlice.methods
    .balance_of_private(alice)
    .simulate();
  logger.info(`Alice's balance ${aliceBalance}`);

  let bobBalance = await tokenContractBob.methods
    .balance_of_private(bob)
    .simulate();
  logger.info(`Bob's balance ${bobBalance}`);

  ///  ------- SIGN PERMIT (ALICE ALLOWS BOB TO TRANSFER HER TOKENS) ---------

  // ON ALICE's SIDE:
  const action = tokenContractAlice
    .withWallet(bobWallet)
    .methods.transfer_in_private(alice, bob, 100n, 1n);
  const witness = await aliceWallet.createAuthWit({ caller: bob, action });

  // BOB SCANS WITNESS FROM QR CODE,
  // ON BOB's SIDE:
  await action.send({ authWitnesses: [witness] }).wait();
  await tokenContractBob.methods.transfer_in_private(alice, bob, 100n, 1n);

  // Bob received the tokens:
  bobBalance = await tokenContractBob.methods
    .balance_of_private(bob)
    .simulate();
  logger.info(`Bob's balance ${bobBalance}`);

  // -------  CORE MERCHANT REGISTRY (deploy only once): --------
  const merchantContract = await MerchantsContract.deploy(aliceWallet, alice)
    .send()
    .deployed();

  const merchantAdmin = await MerchantsContract.at(
    merchantContract.address,
    aliceWallet
  );

  // Once token is deployed, merchant add it to the registry:
  await merchantAdmin.methods
    .add_merchant(alice, tokenContractAlice.address)
    .send()
    .wait();

  // We can retrieve a merchant's token address:
  let aliceMerchantToken = await merchantAdmin.methods
    .get_token(alice)
    .simulate();
  logger.info(`Alice's merchant token ${aliceMerchantToken}`);
}

main();
