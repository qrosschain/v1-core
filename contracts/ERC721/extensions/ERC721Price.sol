// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ERC721Price {
    error IncorrectEtherAmount(uint256 sent, uint256 expected);

    uint256 private _tokenPrice;

    modifier exactPayment(uint256 quantity) {
        uint256 expected = quantity * _tokenPrice;
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
