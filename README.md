# SimpleSwap — Custom Swap Contract for Monad Testnet

## Why this exists

No major DEX router (Uniswap, PancakeSwap, etc.) is deployed on Monad Testnet at the time of building Nullifier. To enable private swaps through the Unlink burner wallet flow, a minimal custom swap contract was deployed directly on Monad Testnet.

## What it does

SimpleSwap is a lightweight ERC20 ↔ ERC20 swap contract with a fixed exchange rate. It holds liquidity for two tokens and allows anyone to swap in both directions.

- Send **tokenA** → receive **tokenB**
- Send **tokenB** → receive **tokenA**

The rate is fixed and set at deployment. Liquidity is pre-deposited by the contract owner.

## Deployed on Monad Testnet

| | Address |
|---|---|
| **SimpleSwap Router** | `0xEc3F41D198b5284bEf87e417BFc028B8407d5D83` |
| **Token A — USDT Mock** | `0x86b6341D3C56bC379697D247fC080F5f2c8Eed7b` |
| **Token B — USDC Mock** | `0xc4fB617E4E4CfbdEb07216dFF62B4E46a2D6FdF6` |

## How to swap

### Step 1 — Approve
Call `approve(spender, amount)` on the token you want to send.
- `spender` = `0xEc3F41D198b5284bEf87e417BFc028B8407d5D83`
- `amount` = amount in wei (e.g. 100 USDT with 6 decimals = `100000000`)

### Step 2 — Swap
Call `swap(tokenIn, amountIn)` on the SimpleSwap contract.
- `tokenIn` = address of the token you're sending
- `amountIn` = same amount as approved

The contract automatically detects the swap direction:
- `tokenIn` = USDT → you receive USDC
- `tokenIn` = USDC → you receive USDT

### Preview (read-only)
Call `quote(tokenIn, amountIn)` to get the expected output before swapping.

## Owner functions

| Function | Description |
|---|---|
| `addLiquidity(amountA, amountB)` | Deposit liquidity for both tokens |
| `withdrawAll()` | Withdraw all liquidity back to owner |
| `setRate(newRate)` | Update the exchange rate |

## Exchange rate

Rate is scaled by `1e18`.

| Rate value | Meaning |
|---|---|
| `1000000000000000000` | 1 tokenA = 1 tokenB |
| `10000000000000000000` | 1 tokenA = 10 tokenB |
| `500000000000000000` | 1 tokenA = 0.5 tokenB |

## Notes

- Liquidity is pre-deposited — no need to add liquidity before swapping
- This contract is intentionally minimal, built for hackathon purposes
- No fees, no slippage, no oracle — pure fixed rate swap
