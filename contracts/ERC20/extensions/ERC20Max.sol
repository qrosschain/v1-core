// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Max is ERC20 {
    error OutOfMaxSupply();

    uint256 private _maxSupply;

    modifier withinSupply(uint256 amount) {
        if (totalSupply() + amount >= _maxSupply) {
            revert OutOfMaxSupply();
        }
        _;
    }

    function _initMax(uint256 maxSupply_) internal {
        _maxSupply = maxSupply_;
    }
}
