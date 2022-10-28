// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AntiBot {
    function protect(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256);
}

contract GOToken is ERC20Burnable, Ownable {
    AntiBot public ab;
    bool public abEnabled;

    uint256 private constant INITIAL_SUPPLY = 1000 * 10**(6 + 18); // 1B tokens
    address private _devAddress;

    constructor() ERC20("GO Token", "GO") {
        _mint(_msgSender(), INITIAL_SUPPLY);
        _devAddress = _msgSender();
    }

    function setABAddress(address _ab, bool _enabeled) external onlyOwner {
        ab = AntiBot(_ab);
        abEnabled = _enabeled;
    }

    function setABEnabled(bool _enabled) external onlyOwner {
        if (_enabled == true) {
            require(address(ab) != address(0), "Anti bot not found");
        }
        abEnabled = _enabled;
    }

    function setDevAddress(address _dev) external onlyOwner {
        _devAddress = _dev;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (abEnabled) {
            uint256 fee = ab.protect(sender, recipient, amount);

            if (fee > 0) {
                super._transfer(sender, _devAddress, fee);
            }

            super._transfer(sender, recipient, amount - fee);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}
