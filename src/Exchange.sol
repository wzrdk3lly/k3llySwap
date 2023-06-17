// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public tokenAddress;

    error InvalidTokenAddress(address _invalidAddres);
    error ReservePriceCannotBe0();
    error EthToSmall();
    error TokenToSmall();
    error insufficientOutputAmount();

    constructor(address _tokenAddress) {
        // 0 address checks to ensure we don't deploy a pool with a token address as the 0 address
        if (_tokenAddress == address(0))
            revert InvalidTokenAddress(_tokenAddress);

        tokenAddress = _tokenAddress;
    }

    function addLiquditity(uint _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount); // msg.sender needs to approve address(this) allowance first
    }

    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        if (!(inputReserve > 0 && outputReserve > 0))
            revert ReservePriceCannotBe0();
        // The 1000 increases the precision since eth doesn't have fixed numbers
        return (inputReserve * 1000) / outputReserve;
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        if (!(inputReserve > 0 && outputReserve > 0))
            revert ReservePriceCannotBe0();

        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }

    //^y(wkt to send) =  wkt outoutReserve(y) * eth inputAamount (^x) / eth inputReserve(x) + eth input amount(^x)
    // ^y = y * ^x / x + ^x

    /**
     * @dev returns token amount for the amount of eth sold (ethsent to address(this)) To this address ()
     * @param _ethSold amount of eth sold
     */
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        if (!(_ethSold > 0)) revert EthToSmall();

        uint256 tokenReserve = getReserve();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        if (!(_tokenSold > 0)) revert TokenToSmall();

        uint256 tokenReserve = getReserve();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    /**
     * @dev A user will receive wkt for eth
     * @param _minTokens the minimum amount of tokens that the user is willing to receive..prevents slippage and sandwich attacks
     */
    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        // subtract msg.value because because the eth from the user would have already been sent. We need to adjust for true eth reserve amount
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        if (!(tokensBought >= _minTokens)) revert insufficientOutputAmount();

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    /**
     * @dev Swap a users token sent and send the user proper amount of eth.
     * @param _tokensSold amount of tokns sold to k3lly swap in exchange for eth
     * @param _minEth the minimum amount of eth to be sent to the user
     */
    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();

        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        if (!(ethBought >= _minEth)) revert insufficientOutputAmount();

        IERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(ethBought);
    }
}
