// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Q, ERC721Q, QrossFactory} from "@qross/v1-core/contracts/QrossFactory.sol";

contract QrossFactoryTest is Test {
    QrossFactory public qrossFactory;

    function setUp() public {
        qrossFactory = new QrossFactory(address(0), address(0));
        // qrossFactory.init(address(0), address(0));
        console.log("QrossFactory:", address(qrossFactory));
    }

    function test_Paid_Mint_ERC20() public {
        ERC20Q erc20 = qrossFactory.createERC20(
            "Test",
            "TST",
            1_000 ether,
            111
        ); // 1 TST = 111 wei
        erc20.mint{value: 100 * 111}(address(1), 100 ether);
        assertEq(erc20.balanceOf(address(1)), 100 ether);
    }

    function test_Paid_Mint_ERC721() public {
        ERC721Q erc721 = qrossFactory.createERC721(
            "Test",
            "TST",
            1_000,
            1 ether,
            "BaseURI"
        );
        erc721.mint{value: 2 ether}(address(1), 2);
        assertEq(erc721.startId(), block.chainid * 1_000);
        assertEq(erc721.endId(), block.chainid * 1_000 + 1_000);
        assertEq(erc721.ownerOf(block.chainid * 1_000), address(1));
        assertEq(erc721.ownerOf(block.chainid * 1_000 + 1), address(1));
        assertEq(erc721.baseURI(), "BaseURI");
    }

    function test_Receive_Mint_ERC20() public {
        ERC20Q erc20 = qrossFactory.createERC20(
            "Test",
            "TST",
            1_000 ether,
            112 ether
        ); // 1 TST = 112 eth
        (bool sent, ) = address(erc20).call{value: 112 ether}("");
        require(sent, "Failed to send Ether");
        assertEq(erc20.balanceOf(address(this)), 1 ether);
    }

    function test_Receive_Mint_ERC721() public {
        ERC721Q erc721 = qrossFactory.createERC721(
            "Test",
            "TST",
            1_000,
            1,
            "BaseURI"
        );
        vm.deal(address(1), 1 ether);
        vm.prank(address(1));
        (bool sent, ) = address(erc721).call{value: 2}("");
        require(sent, "Failed to send Ether");
        assertEq(erc721.startId(), block.chainid * 1_000);
        assertEq(erc721.endId(), block.chainid * 1_000 + 1_000);
        assertEq(erc721.ownerOf(block.chainid * 1_000), address(1));
        assertEq(erc721.ownerOf(block.chainid * 1_000 + 1), address(1));
    }

    function test_Withdraw_ERC20() public {
        vm.prank(address(2));
        ERC20Q erc20 = qrossFactory.createERC20("Test", "TST", 1_000, 33 ether); // 1 TST wei = 33 eth
        erc20.mint{value: 10 * 33}(address(1), 10);
        vm.prank(address(2));
        erc20.withdrawEther(address(2));
        assertEq(address(2).balance, 330);
    }

    function test_Withdraw_ERC721() public {
        vm.prank(address(2));
        ERC721Q erc721 = qrossFactory.createERC721(
            "Test",
            "TST",
            1_000,
            1 ether,
            "BaseURI"
        );
        erc721.mint{value: 2 ether}(address(1), 2);
        vm.prank(address(2));
        erc721.withdrawEther(address(2));
        assertEq(address(2).balance, 2 ether);
    }

    function test_Free_Mint_ERC20() public {
        ERC20Q erc20 = qrossFactory.createERC20("Test", "TST", 1_000, 0);
        erc20.mint(address(1), 100);
        assertEq(erc20.balanceOf(address(1)), 100);
    }

    function test_Free_Mint_ERC721() public {
        ERC721Q erc721 = qrossFactory.createERC721(
            "Test",
            "TST",
            1_000,
            0,
            "BaseURI"
        );
        erc721.mint(address(1), 1);
        erc721.mint(address(1), 1);
        erc721.mint(address(1), 1);
        assertEq(erc721.startId(), block.chainid * 1_000);
        assertEq(erc721.endId(), block.chainid * 1_000 + 1_000);
        assertEq(erc721.ownerOf(block.chainid * 1_000), address(1));
        assertEq(erc721.ownerOf(block.chainid * 1_000 + 1), address(1));
        assertEq(erc721.ownerOf(block.chainid * 1_000 + 2), address(1));
    }
}
