// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Loop {
    function loop() public pure {
        // for loop
        for (uint256 i = 0; i < 10; i++) {
            if (i == 3) {
                // Skip to next iteration with continue
                continue;
            }
            if (i == 5) {
                // Exit loop with break
                break;
            }
        }

        // while loop
        uint256 j;
        while (j < 10) {
            j++;
        }

        uint256 k;
        do {
            k++;
        } 
        while (k < 10);
    }

    function sumN(uint _n) external pure returns (uint) {
        uint s;
        for (uint i; i <= _n; i++) {
            s += i;
        }
        return s;
    }
}
