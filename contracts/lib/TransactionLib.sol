// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <goncalo.sa@consensys.net>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.0;

import './BytesLib.sol';


library TransactionLib {
    using BytesLib for bytes;

    struct Transaction {
        uint256 fromId; //32 bytes
        uint256 fromAmount; //32 bytes
        uint256 toId; //32 bytes
        uint256 toAmount; //32 bytes
        address from; //20 bytes
        bool success; //1 byte
    } //160 bytes

    struct NonFungible {
        bytes URI; // 32 bytes
        Transaction txn; // 160 bytes
    }

    function transactionFromBytes(uint _offst, bytes calldata data) internal pure returns (Transaction memory txn) {
        txn.fromId = data.toUint256(0+_offst);
        txn.fromAmount = data.toUint256(32+_offst);
        txn.toId = data.toUint256(64+_offst);
        txn.toAmount = data.toUint256(96+_offst);
        txn.from = data.toAddress(128+_offst);
        txn.success = bytesToBool(0, data.slice(148+_offst, 1));
    }

    function nonFungibleFromBytes(uint _offst, bytes calldata data) internal pure returns (NonFungible memory nf) {
        //Only looks for 32 bytes
        nf.URI = data.slice(0+_offst,32);
        nf.txn = transactionFromBytes(32+_offst,data);
    }

    function bytesToBool(uint _offst, bytes memory _input) private pure returns (bool _output) {
        uint8 x;
        assembly {
            x := mload(add(_input, _offst))
        }
        x==0 ? _output = false : _output = true;
    }

    function bytesToString(uint _offst, bytes memory _input, bytes memory _output) internal pure {

        uint size = 32;
        assembly {

            let chunk_count

            size := mload(add(_input,_offst))
            chunk_count := add(div(size,32),1) // chunk_count = size/32 + 1

            if gt(mod(size,32),0) {
                chunk_count := add(chunk_count,1)  // chunk_count++
            }

            for { let index:= 0 }  lt(index , chunk_count){ index := add(index,1) } {
                mstore(add(_output,mul(index,32)),mload(add(_input,_offst)))
                _offst := sub(_offst,32)           // _offst -= 32
            }
        }
    }

    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

}
