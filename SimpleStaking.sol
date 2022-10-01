// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStaking {
    /* ========== EVENTS ========== */

    event Stake(address indexed sender, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    mapping(address => uint256) public balances; // staker => amount staked
    mapping(address => uint256) internal depositTimestamps;

    uint256 public deadline; // will be set to (deposit time + 120 sec)
    uint256 public treasury; // total staked amount + liquidity added by the owner of the contract
    uint256 public constant interestRate = 4; // 4% per minute

    bool public _paused;

    address owner;

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    /**
     * @dev In case of emergency sets contract on pause
     */
    modifier onlyWhenNotPaused() {
        require(!_paused, "Contract currently paused");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        owner = msg.sender;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @dev Method for staking ETH
     */
    function stake() public payable onlyWhenNotPaused {
        require(msg.value > 0, "Can't stake 0 ether");
        require(msg.value < treasury, "Try to stake less ETH");
        require(treasury > 0, "Nothing to earn. Add liquidity to treasury");

        balances[msg.sender] += msg.value;
        treasury += msg.value;

        depositTimestamps[msg.sender] = block.timestamp;
        deadline = block.timestamp + 120 seconds;

        emit Stake(msg.sender, msg.value);
    }

    /**
     * @dev Method that allows users withdraw their staking balance
     */
    function withdraw() public onlyWhenNotPaused {
        require(
            balances[msg.sender] > 0,
            "Nothing to withdrawal. Stake some eth"
        );
        require(
            block.timestamp >= deadline,
            "You need to wait some time before you can withdraw"
        );

        uint256 withdrawalAmount = earned(msg.sender) + balances[msg.sender];

        treasury -= withdrawalAmount;
        balances[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: withdrawalAmount}("");
        require(success, "Failed to withdraw");
    }

    /**
     * @dev setPaused makes the contract paused or unpaused
     * @param val `true` to pause contract or `false` to unpause
     */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    /**
     * @dev Additional method that adds liquidity to reward pool by owner of the contract
     */
    function addLiquidity() public payable onlyOwner {
        require(msg.value > 0, "Must be more than 0 ETH");
        treasury += msg.value;
    }

    /**
     * @dev Additional method that remove liquidity to reward pool by owner of the contract
     */
    function removeLiquidity() public payable onlyOwner {
        require(treasury > 0, "Nothing to withdrawal");
        treasury = 0;
        
        (bool success, ) = msg.sender.call{value: treasury}("");
        require(success, "Failed to withdraw");
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Returns the time left before the deadline for the frontend
     */
    function timeLeft() public view returns (uint256) {
        return block.timestamp < deadline ? deadline - block.timestamp : 0;
    }

    /**
     * @dev Shows staked amount
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Shows how much user earned after every minute staked
     */
    function earned(address account) public view returns (uint256) {
        if (balances[account] > 0) {
            return
                calculateInterest(
                    balances[account],
                    (block.timestamp - depositTimestamps[msg.sender])
                );
        }
        return 0;
    }

    /**
     * @dev This function will calculate interest with every minute passed
     */
    function calculateInterest(uint256 staked, uint256 period)
        private
        view
        returns (uint256)
    {
        if (staked == 0 || treasury == 0) {
            return 0;
        }
        return (((staked * interestRate) * (period / 60)) / 100);
    }

    // special function that receives eth
    receive() external payable {}
}
