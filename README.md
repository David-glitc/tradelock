# Tradelock

**Your NFT. Your terms.** Escrow an NFT for BOT or another NFT. Accept, cancel, or recover an expired offer onchain.

**Officially launched on BOT Chain Mainnet** on 2026-10-22.

- Website and app: https://tradelockbot.vercel.app (app at [`/app/`](https://tradelockbot.vercel.app/app/))
- Network: BOT Chain mainnet, chain ID 677 · [BOT Chain](https://www.botchain.ai/) · [BOTScan](https://scan.botchain.ai/)

![Tradelock landing page](docs/tradelock-landing-1280.png)

## How it works

1. **List an NFT.** Approve one ERC-721 and set a BOT price, or name the exact NFT you want in return.
2. **Counterparty fills.** The buyer pays the exact BOT amount or hands over the exact requested NFT.
3. **Atomic settlement.** Both sides move in one transaction. Cancel any time before it fills.

## Features

- **Exact terms.** Offers fill only with the precise amount or token you asked for.
- **Escrowed NFTs.** Your NFT is held by the contract, not by another person.
- **Expiry recovery.** Anyone can return an expired NFT to its owner.
- **No protocol fee.** Tradelock launches with a 0% fee.

## Contracts

| Contract | BOT Chain mainnet |
|---|---|
| `TradelockEscrow` | [`0xcf82ea5a8f6eacf96a5edb564f31627bdba33713`](https://scan.botchain.ai/address/0xcf82ea5a8f6eacf96a5edb564f31627bdba33713) |

BOT Chain infrastructure used: USDT `0xaBabc7Ddc03e501d190C676BF3d92ef0e6e87a3C`, WBOT `0xD5452816194a3784dBa983426cCe7c122F4abd30`, BDEX router `0x07032d47A1b9f8460cBeE9dC17c1d3E438693929`, BDEX QuoterV2 `0x034A705b36067cff99ABf5C662Be881cBd8d0176`.

Source: [`contracts/src`](contracts/src). Tests: [`contracts/test`](contracts/test). The contracts are unaudited; use small amounts.

## Develop

Requires Node 20+, [Foundry](https://getfoundry.sh) and Python 3.

```bash
git clone --recursive https://github.com/David-glitc/tradelock.git
cd tradelock
npm ci
npm test              # forge test
npm run build         # landing page + app into dist/tradelock
npm run preview       # http://127.0.0.1:8771
```

`npm run build` writes `dist/tradelock/index.html` (landing page), `dist/tradelock/app/` (the dApp) and a Cloudflare Workers bundle under `sites/`.

### Wallets

The app discovers installed wallets with EIP-6963 (BO Wallet, MetaMask, OKX, Rabby and others) and falls back to `window.ethereum`. It switches or adds BOT Chain (chain ID `0x2a5`, RPC `https://rpc.botchain.ai`) before any transaction, and simulates every call before asking for a signature.

### Rehearse on a mainnet fork

```bash
anvil --fork-url https://rpc.botchain.ai --port 8677 --chain-id 677
export BOT_RPC_URL=http://127.0.0.1:8677
node scripts/deploy.mjs && node scripts/fork-check.mjs
```

### Deploy

`scripts/deploy.mjs` reads the deployer key from `BOT_SIGNER_FILE` (default `~/.config/botchain-wave1/deployer.env`, never committed), refuses to broadcast on mainnet without `BOT_MAX_GAS_BOT`, and journals every transaction to `deployments/mainnet.json` so it can resume. `npm run publish` deploys the built site to Vercel as a static production deployment.

## License

MIT. Built on [BOT Chain](https://www.botchain.ai/).
