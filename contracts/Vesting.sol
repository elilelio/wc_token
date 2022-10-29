// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public token;

    struct VestingInfo {
        uint256 amount;
        uint256 startBlock;
        uint256 lockedDuration; // number of block
        uint256 period; // number of block
        uint256 numberOfPeriod;
        uint256 claimedAmount;
        bool isActive;
    }

    mapping(address => VestingInfo) private _userToVesting;

    constructor(address _token) {
        require(_token != address(0), "Vesting: invalid token");
        token = IERC20(_token);
    }

    function addVesting(
        address _user,
        uint256 _amount,
        uint256 _startBlock,
        uint256 _lockedDuration,
        uint256 _period,
        uint256 _numberOfPeriod
    ) external onlyOwner {
        require(
            _userToVesting[_user].isActive == false,
            "Vesting: User already exist"
        );
        token.safeTransferFrom(msg.sender, address(this), _amount);
        VestingInfo memory info = VestingInfo(
            _amount,
            _startBlock,
            _lockedDuration,
            _period,
            _numberOfPeriod,
            0,
            true
        );
        _userToVesting[_user] = info;
    }

    function claimVesting() external {
        require(
            _userToVesting[msg.sender].isActive == true,
            "Vesting: User not exist"
        );

        uint256 claimableAmount = _getVestingClaimableAmount(msg.sender);

        require(claimableAmount > 0, "Vesting: Nothing to claim");

        _userToVesting[msg.sender].claimedAmount =
            _userToVesting[msg.sender].claimedAmount +
            claimableAmount;

        token.safeTransfer(msg.sender, claimableAmount);
    }

    function _getVestingClaimableAmount(address _user)
        internal
        view
        returns (uint256 claimableAmount)
    {
        VestingInfo memory info = _userToVesting[_user];

        if (block.number <= info.startBlock) return 0;

        uint256 passedBlocks = block.number -
            (info.startBlock + info.lockedDuration);

        uint256 numberOfPassedPeriods = passedBlocks / info.period;

        uint256 unlockedAmount;

        if (numberOfPassedPeriods >= info.numberOfPeriod) {
            unlockedAmount = info.amount;
        } else {
            unlockedAmount =
                (info.amount * numberOfPassedPeriods) /
                info.numberOfPeriod;
        }

        claimableAmount = 0;
        if (unlockedAmount > info.claimedAmount) {
            claimableAmount = unlockedAmount - info.claimedAmount;
        }

        return claimableAmount;
    }

    function getVestingClaimableAmount(address _user)
        external
        view
        returns (uint256)
    {
        require(
            _userToVesting[_user].isActive == true,
            "Vesting: User not exist"
        );

        return _getVestingClaimableAmount(_user);
    }

    function getVestingInfo(address _user)
        external
        view
        returns (VestingInfo memory)
    {
        require(
            _userToVesting[_user].isActive == true,
            "Vesting: User not exist"
        );

        VestingInfo memory info = _userToVesting[_user];
        return info;
    }

    function disableUser(address _user) external onlyOwner {
        require(
            _userToVesting[_user].isActive == true,
            "Vesting: User not exist"
        );

        VestingInfo memory info = _userToVesting[_user];

        token.safeTransfer(msg.sender, info.amount - info.claimedAmount);

        _userToVesting[_user].isActive = false;
    }
}
