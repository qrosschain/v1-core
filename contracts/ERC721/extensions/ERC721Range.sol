// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ERC721Range {
    error OutOfRangeTokenIDs();

    uint256 private _totalSupply;
    uint256 private _startId;
    uint256 private _endId;

    modifier withinRange(uint256 quantity) {
        if (_startId + _totalSupply + quantity >= _endId) {
            revert OutOfRangeTokenIDs();
        }
        _;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function startId() external view returns (uint256) {
        return _startId;
    }

    function endId() external view returns (uint256) {
        return _endId;
    }

    function _nextTokenId() internal returns (uint256) {
        return _startId + (_totalSupply++);
    }

    function _initRange(uint256 maxSupply_) internal {
        _startId = block.chainid * maxSupply_;
        _endId = maxSupply_ <= 0
            ? type(uint256).max
            : block.chainid * maxSupply_ + maxSupply_;
    }
}
