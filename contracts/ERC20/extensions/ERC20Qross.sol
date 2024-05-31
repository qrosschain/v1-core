// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract ERC20Qross is
    ERC20,
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
    ) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x85572ffb; // ERC165 interface ID for CCIPReceiver.
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

    function _callMint(address account, uint256 value) external {
        if (msg.sender != address(this)) revert MintOnlyByInternalCall();
        _mint(account, value);
    }

    function transfer(
        address to,
        uint256 value,
        uint64 chainSelector
    ) public returns (bool) {
        if (chainSelector == 0) {
            return super.transfer(to, value);
        } else {
            _burn(msg.sender, value);
            _crossMint(to, value, chainSelector);
            return true;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 value,
        uint64 chainSelector
    ) public returns (bool) {
        if (chainSelector == 0) {
            return super.transferFrom(from, to, value);
        } else {
            _burn(from, value);
            _crossMint(to, value, chainSelector);
            return true;
        }
    }

    function _crossMint(
        address account,
        uint256 value,
        uint64 chainSelector
    ) internal nonReentrant {
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(address(this)),
            data: abi.encodeWithSignature(
                "_callMint(address,uint256)",
                account,
                value
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
