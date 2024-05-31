// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract QrossFactoryScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        console.log("Hello World");
    }
}
