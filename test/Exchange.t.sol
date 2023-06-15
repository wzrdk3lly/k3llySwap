// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {Utilities} from "./utils/Utillities.sol";

import "../src/Exchange.sol";
import "../src/K3llyToken.sol";

contract ExchangeTest is Test {
    uint256 internal constant INITITAL_SUPPLY = 1_000e18;

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

    function testFailWhenDeployingWith0Address() public {
        Exchange fakeExchange = new Exchange(address(0));
    }

    function testAddLiqudity() public {
        wkt.approve(address(exchangePool), 200e18);
        exchangePool.addLiquditity{value: 100e18}(200e18);

        assertEq(exchangePool.getReserve(), 200e18);
        // assert that the value of the exchange increased by 10 eth

        assertEq(address(exchangePool).balance, 100e18);
    }
}
