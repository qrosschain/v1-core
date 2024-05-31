// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Create2Deployer {
    function deploy(
        bytes memory bytecode,
        bytes32 salt
    ) public returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
    }

    function getAddress(
        bytes memory bytecode,
        bytes32 salt
    ) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(bytecode)
                            )
                        )
                    )
                )
            );
    }
}
