// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Utilities} from "./utils/Utillities.sol";

import "../src/Exchange.sol";
import "../src/K3llyToken.sol";

contract ExchangeTest is Test {
    uint256 internal constant INITITAL_SUPPLY = 4_000e18;

    Utilities internal utils;
    Exchange internal exchangePool;
    K3llyToken internal wkt;

    address payable[] internal users;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(2);

        address payable alice = users[0];
        vm.label(alice, "Alice");
        address payable bob = users[1];

        vm.label(bob, "Bob");

        // vm.label(address(this), "deployer");

        // Deploying WKT
        wkt = new K3llyToken(INITITAL_SUPPLY);

        // Deploying exchangePool
        exchangePool = new Exchange(address(wkt));
    }

    function testFailWhenDeployingTo0Address() public {
        new Exchange(address(0));
    }

    function testAddLiqudity() public {
        wkt.approve(address(exchangePool), 200e18);
        exchangePool.addLiquditity{value: 100e18}(200e18);

        assertEq(exchangePool.getReserve(), 200e18);
        // assert that the value of the exchange increased by 10 eth

        assertEq(address(exchangePool).balance, 100e18);
    }

    function testGetPrice() public {
        wkt.approve(address(exchangePool), 2000e18);
        exchangePool.addLiquditity{value: 1000e18}(2000e18);

        // balance of eth in reserve pool
        uint256 ethTotal = address(exchangePool).balance;
        uint256 wktTotal = exchangePool.getReserve();

        // Eth per WKT
        assertEq(exchangePool.getPrice(ethTotal, wktTotal), 500); // Will need to divide by 1000 to get official price on frontend.

        // wkt per Eth
        assertEq(exchangePool.getPrice(wktTotal, ethTotal), 2000);
    }

    function testGetEthAmount() public {
        wkt.approve(address(exchangePool), 200e18);
        exchangePool.addLiquditity{value: 100e18}(200e18);

        assertEq(exchangePool.getReserve(), 200e18);
        // assert that the value of the exchange increased by 10 eth

        assertEq(address(exchangePool).balance, 100e18);

        uint256 ethOut = exchangePool.getEthAmount(2e18);
        assertEq(ethOut, 990099009900990099);

        ethOut = exchangePool.getEthAmount(100e18);
        assertEq(ethOut, 33333333333333333333); // 100 tokens gives me ~33 eth. you'd think it would give me about 50 eth

        ethOut = exchangePool.getEthAmount(2000e18);
        assertEq(ethOut, 90909090909090909090); // 2_000 gives me about  90.90eth  The price slippage is actually a protector from the pool being drained
    }

    function testGetTokenAmount() public {
        wkt.approve(address(exchangePool), 200e18);
        exchangePool.addLiquditity{value: 100e18}(200e18);

        assertEq(exchangePool.getReserve(), 200e18);

        assertEq(address(exchangePool).balance, 100e18);

        uint256 tokensOut = exchangePool.getTokenAmount(1e18);

        assertEq(tokensOut, 1980198019801980198); // 1 eth gives me ~1.9 tokens

        tokensOut = exchangePool.getTokenAmount(100e18);

        assertEq(tokensOut, 100000000000000000000); // 100 eth gives me 100 tokens

        tokensOut = exchangePool.getTokenAmount(2000e18);

        assertEq(tokensOut, 190476190476190476190); //2000 eth gives me about 198.00 tokens
    }

    function testEthToTokenSwap() public {
        wkt.approve(address(exchangePool), 200e18);
        exchangePool.addLiquditity{value: 100e18}(200e18);

        uint256 balanceBeforeSwap = wkt.balanceOf(address(this));

        exchangePool.ethToTokenSwap{value: 1e18}(1e18);

        uint256 balanceAfterSwap = wkt.balanceOf(address(this));

        // assuming no fees
        assertEq(balanceAfterSwap - balanceBeforeSwap, 1980198019801980198);
    }

    function testTokenToEthSwap() public {
        wkt.approve(address(exchangePool), 202e18);
        exchangePool.addLiquditity{value: 100e18}(200e18);

        uint256 balanceBeforeSwap = address(this).balance;

        exchangePool.tokenToEthSwap(2e18, 9e17);

        uint256 balanceAfterSwap = address(this).balance;

        console2.log(balanceAfterSwap - balanceBeforeSwap);
        // LE because of gas fee
        assertLe(balanceAfterSwap - balanceBeforeSwap, 990099009900990099);
    }

    receive() external payable {}
}
