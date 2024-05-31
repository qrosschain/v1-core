// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
........................................................................
'########:'########:::'######::'########::'#######:::::'##::::'#######::
 ##.....:: ##.... ##:'##... ##: ##..  ##:'##.... ##::'####:::'##.... ##:
 ##::::::: ##:::: ##: ##:::..::..:: ##:::..::::: ##::.. ##::: ##:::: ##:
 ######::: ########:: ##:::::::::: ##:::::'#######::::: ##::: ##:::: ##:
 ##...:::: ##.. ##::: ##::::::::: ##:::::'##::::::::::: ##::: ##:'## ##:
 ##::::::: ##::. ##:: ##::: ##::: ##::::: ##::::::::::: ##::: ##:.. ##::
 ########: ##:::. ##:. ######:::: ##::::: #########::'######:: ##### ##:
........::..:::::..:::......:::::..::::::.........:::......:::.....:..::
 */

import {IERC721Q, ERC721, Ownable} from "@qross/v1-core/contracts/ERC721/interfaces/IERC721Q.sol";

contract ERC721Q is IERC721Q {
    string public baseURI;
    bool private isInit;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {}

    function init(
        address owner_,
        address router_,
        address link_,
        uint256 maxSupply_,
        uint256 tokenPrice_,
        string memory baseURI_
    ) external nonReentrant onlyOwner {
        require(!isInit, "Is already initialized!");
        isInit = true;
        baseURI = baseURI_;
        _initRange(maxSupply_);
        _initPrice(tokenPrice_);
        _initQross(router_, link_);
        transferOwnership(owner_);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// Mint (ERC721Price + ERC721Range extensions)
    function mint(
        address account,
        uint256 quantity
    ) public payable nonReentrant exactPayment(quantity) withinRange(quantity) {
        for (uint256 i; i < quantity; i++) {
            _mint(account, _nextTokenId());
        }
    }

    /// Mint (ERC721Qross + ERC721Price + ERC721Range extensions)
    function mint(
        address account,
        uint256 /** quantity */,
        uint64 chainSelector
    ) public payable exactPayment(1) withinRange(1) {
        _crossMint(account, _nextTokenId(), chainSelector);
    }

    receive() external payable {
        require(tokenPrice() > 0, "Cannot Send ETH With Zero Token Price");
        mint(msg.sender, msg.value / tokenPrice());
    }

    function withdrawEther(address beneficiary) external onlyOwner {
        _withdrawEther(beneficiary);
    }

    function withdrawLink(address beneficiary) external onlyOwner {
        _withdrawLink(beneficiary);
    }
}
