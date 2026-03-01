// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @title SimpleSwap
 * @notice Fixed-rate swap between two ERC20 tokens.
 *         The owner deposits liquidity and sets the exchange rate.
 *         Anyone can swap in both directions.
 *
 * Example: tokenA = USDC, tokenB = wrapped MON
 *          rate = 10  →  1 tokenA = 10 tokenB
 *                        10 tokenB = 1 tokenA
 */
contract SimpleSwap {

    address public owner;
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Rate: how many tokenB per 1 tokenA (in base units, i.e. wei)
    // Ex: if tokenA and tokenB both have 18 decimals,
    //     rate = 10 * 1e18 means 1 tokenA = 10 tokenB
    uint256 public rate; // tokenB per tokenA, scaled by 1e18

    event Swapped(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);
    event LiquidityAdded(address token, uint256 amount);
    event LiquidityWithdrawn(address token, uint256 amount);
    event RateUpdated(uint256 newRate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /**
     * @param _tokenA   Address of token A
     * @param _tokenB   Address of token B
     * @param _rate     How many tokenB per 1 tokenA, multiplied by 1e18
     *                  Ex: 1 tokenA = 10 tokenB  →  _rate = 10 * 1e18
     *                  Ex: 1 tokenA = 0.5 tokenB →  _rate = 5e17
     */
    constructor(address _tokenA, address _tokenB, uint256 _rate) {
        require(_tokenA != address(0) && _tokenB != address(0), "Zero address");
        require(_tokenA != _tokenB, "Same token");
        require(_rate > 0, "Rate must be > 0");

        owner = msg.sender;
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rate = _rate;
    }

    // ─────────────────────────────────────────────
    //  SWAP
    // ─────────────────────────────────────────────

    /**
     * @notice Swap tokenA → tokenB
     * @param amountIn Amount of tokenA to send (in wei)
     */
    function swapAforB(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be > 0");

        uint256 amountOut = (amountIn * rate) / 1e18;
        require(amountOut > 0, "Amount out too small");
        require(tokenB.balanceOf(address(this)) >= amountOut, "Not enough tokenB liquidity");

        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOut);

        emit Swapped(msg.sender, address(tokenA), amountIn, address(tokenB), amountOut);
    }

    /**
     * @notice Swap tokenB → tokenA
     * @param amountIn Amount of tokenB to send (in wei)
     */
    function swapBforA(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be > 0");

        // Inverse rate: 1 tokenB = (1e18 / rate) tokenA
        uint256 amountOut = (amountIn * 1e18) / rate;
        require(amountOut > 0, "Amount out too small");
        require(tokenA.balanceOf(address(this)) >= amountOut, "Not enough tokenA liquidity");

        tokenB.transferFrom(msg.sender, address(this), amountIn);
        tokenA.transfer(msg.sender, amountOut);

        emit Swapped(msg.sender, address(tokenB), amountIn, address(tokenA), amountOut);
    }

    // ─────────────────────────────────────────────
    //  READ UTILITIES
    // ─────────────────────────────────────────────

    /// @notice How many tokenB you receive for `amountIn` tokenA
    function quoteAforB(uint256 amountIn) external view returns (uint256) {
        return (amountIn * rate) / 1e18;
    }

    /// @notice How many tokenA you receive for `amountIn` tokenB
    function quoteBforA(uint256 amountIn) external view returns (uint256) {
        return (amountIn * 1e18) / rate;
    }

    /// @notice Current contract reserves
    function reserves() external view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = tokenA.balanceOf(address(this));
        reserveB = tokenB.balanceOf(address(this));
    }

    // ─────────────────────────────────────────────
    //  OWNER: LIQUIDITY & CONFIG
    // ─────────────────────────────────────────────

    /// @notice Deposit tokenA into the contract (approve first!)
    function addLiquidityA(uint256 amount) external onlyOwner {
        tokenA.transferFrom(msg.sender, address(this), amount);
        emit LiquidityAdded(address(tokenA), amount);
    }

    /// @notice Deposit tokenB into the contract (approve first!)
    function addLiquidityB(uint256 amount) external onlyOwner {
        tokenB.transferFrom(msg.sender, address(this), amount);
        emit LiquidityAdded(address(tokenB), amount);
    }

    /// @notice Withdraw tokenA to owner
    function withdrawA(uint256 amount) external onlyOwner {
        tokenA.transfer(owner, amount);
        emit LiquidityWithdrawn(address(tokenA), amount);
    }

    /// @notice Withdraw tokenB to owner
    function withdrawB(uint256 amount) external onlyOwner {
        tokenB.transfer(owner, amount);
        emit LiquidityWithdrawn(address(tokenB), amount);
    }

    /// @notice Update the exchange rate (1 tokenA = newRate/1e18 tokenB)
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be > 0");
        rate = newRate;
        emit RateUpdated(newRate);
    }

    /// @notice Transfer contract ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}
