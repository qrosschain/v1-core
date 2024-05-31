// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721Price} from "@qross/v1-core/contracts/ERC721/extensions/ERC721Price.sol";
import {ERC721Range} from "@qross/v1-core/contracts/ERC721/extensions/ERC721Range.sol";
import {ERC721Qross} from "@qross/v1-core/contracts/ERC721/extensions/ERC721Qross.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract IERC721Q is
    ERC721,
    ERC721Price,
    ERC721Range,
    ERC721Qross,
    Ownable
{
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Qross) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
