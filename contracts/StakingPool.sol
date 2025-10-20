// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity 0.8.22;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

error ContractInsufficientRewardAmount();
error ContractInsufficientBalance();
error NotFoundStakedItem();
error SellerInsufficientRewardAmount();
error PoolNotStarted();
error PoolEndedOrNotStarted();
error PoolEnded();
error LockedPeriod();
error YourInsufficientBalance();
error InvalidRecipientAddress();
error HarvestedOrPoolEnded();

contract StakingPool is Context, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct StakedItem {
        uint amount;
        uint stakedAt;
        uint totalRewardPaid;
    }

    address private _masterWallet;
    uint256 private constant _SCALING = 1e18;
    uint256 private constant _ONE_YEAR = 365;
    uint256 private constant _ONE_YEAR_SECONDS = 365 days;

    IERC20 public token;
    uint256 public apy;
    uint256 public stakingPeriod = 7 days;
    uint256 public poolStartTime;
    uint256 public poolEndTime;
    uint256 public totalStakedAmount;
    uint256 public limitStakedAmount = 10 ether;
    uint256 public limitStakedAmountPerUser = 1 ether;

    mapping(address staker => StakedItem) public stakes;
    mapping(address => bool) public isHarvestEnd;

    constructor(
        address _initialOwner,
        address _master,
        IERC20 _token,
        uint256 _apy
    ) Ownable(_initialOwner) {
        _masterWallet = _master;
        apy = _apy * _SCALING;
        token = _token;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setLimitStakedAmount(uint256 _limitAmount) external onlyOwner {
        limitStakedAmount = _limitAmount;
    }

    function setLimitStakedAmountPerUser(
        uint256 _limitAmount
    ) external onlyOwner {
        limitStakedAmountPerUser = _limitAmount;
    }

    function setApy(uint256 apy_) external onlyOwner {
        apy = apy_;
    }

    function setMasterWallet(address _newWallet) external onlyOwner {
        _masterWallet = _newWallet;
    }

    function setStakingPeriod(uint256 _newPeriod) external onlyOwner {
        require(
            _newPeriod >= 1 days && _newPeriod <= 365 days,
            "Staking period must be between 1 day and 365 days"
        );
        require(
            _newPeriod != stakingPeriod,
            "New staking period must be different from the current one"
        );
        stakingPeriod = _newPeriod;
    }

    function getMasterWallet() external view returns (address) {
        return _masterWallet;
    }

    function getStakingPeriod() external view returns (uint256) {
        return stakingPeriod;
    }

    function setupPool(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        poolEndTime = _endTime == 0 ? _startTime + _ONE_YEAR_SECONDS : _endTime;
        poolStartTime = _startTime == 0 ? _currentTime() : _startTime;
    }

    function isNotStartedPool() public view returns (bool) {
        return poolStartTime <= 0;
    }

    function isEndPool() public view returns (bool) {
        return poolEndTime != 0 && poolEndTime < _currentTime();
    }

    function isPoolNotActivated() internal view returns (bool) {
        return poolStartTime <= 0 && poolEndTime <= 0;
    }

    function _calcDays(
        uint _endtime,
        uint _startTime
    ) internal pure returns (uint) {
        return ((_endtime - _startTime) * _SCALING) / 24 / 60 / 60;
    }

    function _currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function _currentBlock() internal view returns (uint256) {
        return block.number;
    }

    function _calculateReward(
        uint256 _stakedTime,
        uint256 _quantity,
        uint256 _endTime
    ) internal view returns (uint256) {
        uint256 stakedDay = _calcDays(_endTime, _stakedTime);
        uint256 reward = ((apy / 100) * (stakedDay / _ONE_YEAR) * _quantity) /
            _SCALING /
            _SCALING;
        return reward;
    }

    function stakeToken(uint256 _amount) external whenNotPaused {
        if (_amount <= 0) {
            revert ContractInsufficientBalance();
        }

        if (isPoolNotActivated()) {
            revert PoolEndedOrNotStarted();
        }

        StakedItem storage staking = stakes[_msgSender()];
        require(
            staking.amount + _amount <= limitStakedAmountPerUser,
            "stakeToken: you have exceeded the limit"
        );
        require(
            totalStakedAmount + _amount <= limitStakedAmount,
            "stakeToken: exceeded pool limit"
        );

        if (_amount > 0) {
            token.safeTransferFrom(_msgSender(), address(this), _amount);
            totalStakedAmount += _amount;
        }

        if (staking.amount > 0) {
            uint256 rewardAmount = _calculateReward(
                staking.stakedAt,
                staking.amount,
                _currentTime() > poolEndTime ? poolEndTime : _currentTime()
            );
            if (rewardAmount > 0) {
                token.safeTransfer(_msgSender(), rewardAmount);
            }
            staking.amount += _amount;
            staking.stakedAt = _currentTime();
            staking.totalRewardPaid += rewardAmount;
        } else {
            stakes[_msgSender()] = StakedItem(_amount, _currentTime(), 0);
        }
    }

    function getMyStaked(
        address _stakerWallet
    ) external view returns (uint256) {
        return stakes[_stakerWallet].amount;
    }

    function isLockedPeriod(uint256 _startAt) public view returns (bool) {
        return _startAt + stakingPeriod >= _currentTime();
    }

    function getUserLockPeriod(
        address _stakerWallet
    ) public view returns (uint256) {
        return
            stakes[_stakerWallet].stakedAt > 0
                ? stakes[_stakerWallet].stakedAt + stakingPeriod
                : 0;
    }

    function unstake(uint256 _amount) external nonReentrant whenNotPaused {
        StakedItem storage staking = stakes[_msgSender()];
        require(staking.amount > 0, "unstake: Not found your staked item");
        require(_amount <= staking.amount, "unstake: amount is too high");
        require(_amount > 0, "unstake: amount is too low");
        if (isLockedPeriod(staking.stakedAt)) {
            revert LockedPeriod();
        }
        uint256 rewardAmount = _calculateReward(
            staking.stakedAt,
            _amount,
            _currentTime() > poolEndTime ? poolEndTime : _currentTime()
        );
        uint256 totalStaked = _amount + rewardAmount;
        token.safeTransfer(_msgSender(), totalStaked);
        staking.amount -= _amount;
        staking.totalRewardPaid += rewardAmount;
        totalStakedAmount -= _amount;
    }

    function estimateReward(address _staker) external view returns (uint) {
        StakedItem memory staking = stakes[_staker];
        if (isHarvestEnd[_staker]) {
            return 0;
        }
        uint rewardAmount = _calculateReward(
            staking.stakedAt,
            staking.amount,
            _currentTime() > poolEndTime ? poolEndTime : _currentTime()
        );
        return rewardAmount;
    }

    function harvest() external whenNotPaused {
        StakedItem storage staking = stakes[_msgSender()];
        if (isHarvestEnd[_msgSender()]) {
            revert HarvestedOrPoolEnded();
        }
        uint rewardAmount = _calculateReward(
            staking.stakedAt,
            staking.amount,
            _currentTime() > poolEndTime ? poolEndTime : _currentTime()
        );
        if (rewardAmount > 0) {
            token.safeTransfer(_msgSender(), rewardAmount);
            staking.totalRewardPaid += rewardAmount;
            staking.stakedAt = _currentTime();
        }
    }

    function withdraw() external {
        StakedItem storage staking = stakes[_msgSender()];
        if (staking.amount > 0) {
            token.safeTransfer(_msgSender(), staking.amount);
            staking.amount = 0;
            totalStakedAmount -= staking.amount;
        }
    }

    function emergencyWithdrawal(address _recipient) external onlyOwner {
        if (_recipient == address(0)) {
            revert InvalidRecipientAddress();
        }
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }
}
