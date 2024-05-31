// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20Price} from "@qross/v1-core/contracts/ERC20/extensions/ERC20Price.sol";
import {ERC20Qross} from "@qross/v1-core/contracts/ERC20/extensions/ERC20Qross.sol";
import {ERC20Max} from "@qross/v1-core/contracts/ERC20/extensions/ERC20Max.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC20Q is ERC20, ERC20Price, ERC20Qross, ERC20Max, Ownable {}
