// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract ERC20Price is ERC20 {
    error IncorrectEtherAmount(uint256 sent, uint256 expected);

    uint256 private _tokenPrice;

    modifier exactPayment(uint256 amount) {
        uint256 expected = (amount * _tokenPrice) / 10 ** decimals();
        if (_tokenPrice > 0 && msg.value != expected) {
            revert IncorrectEtherAmount(msg.value, expected);
        }
        _;
    }

    function tokenPrice() public view returns (uint256) {
        return _tokenPrice;
    }

    function _initPrice(uint256 tokenPrice_) internal {
        _tokenPrice = tokenPrice_;
    }
}
