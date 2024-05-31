// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract ERC721Qross is
    ERC721,
    IAny2EVMMessageReceiver,
    ReentrancyGuard
{
    error UnauthorizedSender();
    error MessageHandlingFailed();
    error MintOnlyByInternalCall();
    error WithdrawalFailed();
    error ApprovalFailed();

    event MessageSent(bytes32 messageId);

    address private _router;
    address private _link; // If non-zero address, pay fee in LINK token

    function _initQross(address router_, address link_) internal {
        _router = router_;
        _link = link_;
        if (_link != address(0)) {
            bool success = IERC20(_link).approve(_router, type(uint256).max);
            if (!success) revert ApprovalFailed();
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId || // ERC165 interface ID 0x85572ffb for CCIPReceiver
            super.supportsInterface(interfaceId);
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external virtual override {
        if (msg.sender != _router) revert UnauthorizedSender();
        _ccipReceive(message);
    }

    function _ccipReceive(Client.Any2EVMMessage memory message) internal {
        (bool success, ) = address(this).call(message.data);
        if (!success) revert MessageHandlingFailed();
    }

    function getRouter() public view returns (address) {
        return _router;
    }

    function _callMint(address to, uint256 tokenId) external {
        if (msg.sender != address(this)) revert MintOnlyByInternalCall();
        _mint(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint64 chainSelector
    ) public {
        if (chainSelector == 0) {
            super.transferFrom(from, to, tokenId);
        } else {
            _burn(tokenId);
            _crossMint(to, tokenId, chainSelector);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint64 chainSelector
    ) public {
        if (chainSelector == 0) {
            super.safeTransferFrom(from, to, tokenId);
        } else {
            _burn(tokenId);
            _crossMint(to, tokenId, chainSelector);
        }
    }

    function _crossMint(
        address to,
        uint256 tokenId,
        uint64 chainSelector
    ) internal nonReentrant {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encodeWithSignature(
                "_callMint(address,uint256)",
                to,
                tokenId
            ),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: "",
            feeToken: _link
        });

        bytes32 messageId = _link != address(0)
            ? IRouterClient(_router).ccipSend(chainSelector, message)
            : IRouterClient(_router).ccipSend{
                value: IRouterClient(_router).getFee(chainSelector, message)
            }(chainSelector, message);

        emit MessageSent(messageId);
    }

    function _withdrawEther(address beneficiary) internal {
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }

    function _withdrawLink(address beneficiary) internal {
        uint256 amount = IERC20(_link).balanceOf(address(this));
        bool success = IERC20(_link).transfer(beneficiary, amount);
        if (!success) revert WithdrawalFailed();
    }
}
