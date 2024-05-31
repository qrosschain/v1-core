// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
................................................................
'########:'########:::'######:::'#######::::'#####::::'#######::
 ##.....:: ##.... ##:'##... ##:'##.... ##::'##.. ##::'##.... ##:
 ##::::::: ##:::: ##: ##:::..::..::::: ##:'##:::: ##: ##:::: ##:
 ######::: ########:: ##::::::::'#######:: ##:::: ##: ##:::: ##:
 ##...:::: ##.. ##::: ##:::::::'##:::::::: ##:::: ##: ##:'## ##:
 ##::::::: ##::. ##:: ##::: ##: ##::::::::. ##:: ##:: ##:.. ##::
 ########: ##:::. ##:. ######:: #########::. #####:::: ##### ##:
........::..:::::..:::......:::.........::::.....:::::.....:..::
 */

import {IERC20Q, ERC20, Ownable} from "@qross/v1-core/contracts/ERC20/interfaces/IERC20Q.sol";

contract ERC20Q is IERC20Q {
    bool private isInit;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {}

    function init(
        address owner_,
        address router_,
        address link_,
        uint256 maxSupply_,
        uint256 tokenPrice_
    ) external nonReentrant onlyOwner {
        require(!isInit, "Is already initialized!");
        isInit = true;
        _initMax(maxSupply_);
        _initPrice(tokenPrice_);
        _initQross(router_, link_);
        transferOwnership(owner_);
    }

    /// Mint (ERC721Price + ERC721Max extensions)
    function mint(
        address account,
        uint256 amount
    ) public payable nonReentrant exactPayment(amount) withinSupply(amount) {
        _mint(account, amount);
    }

    /// Mint (ERC721Qross + ERC721Price + ERC721Max extensions)
    function mint(
        address account,
        uint256 amount,
        uint64 chainSelector
    ) public payable exactPayment(amount) withinSupply(amount) {
        _crossMint(account, amount, chainSelector);
    }

    receive() external payable {
        require(tokenPrice() > 0, "Cannot Send ETH With Zero Token Price");
        mint(msg.sender, (msg.value * 10 ** decimals()) / tokenPrice());
    }

    function withdrawEther(address beneficiary) external onlyOwner {
        _withdrawEther(beneficiary);
    }

    function withdrawLink(address beneficiary) external onlyOwner {
        _withdrawLink(beneficiary);
    }
}
