// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
    
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => uint256) private _stake;
    mapping(address => uint256) private _apy; //per 10 thousand (8.75% => 875/10,000)
    mapping(address => uint256) private _time; //Time staking started started
    
    uint256 private _totalSupply = 1000000000000000000000000000000000;

    string private _name;
    string private _symbol;
    
    address private _owner;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        _balances[msg.sender] += _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function owner() public view returns(address) {
        return _owner;
    }
    
    function transferOwnership(address to_) external {
        require(msg.sender == _owner);
        _owner = to_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function stakingStats(address user) external view returns(uint256 stake, uint256 apy, uint256 time, uint256 reward) {
        stake = _stake[msg.sender];
        apy = _apy[msg.sender];
        time = _time[msg.sender];
        reward = stake * apy * (block.timestamp - time) / 31536000 / 10000;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender,  _allowances[msg.sender][spender]);
        
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        _allowances[sender][msg.sender] -= amount;
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        
        emit Approval(msg.sender, spender,  _allowances[msg.sender][spender]);
        
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(_allowances[msg.sender][spender] >= subtractedValue, "ERC20: decreased allowance below zero");
        
        _allowances[msg.sender][spender] -= subtractedValue;
        
        emit Approval(msg.sender, spender,  _allowances[msg.sender][spender]);

        return true;
    }
    
    function stake(uint256 amount) external {
        claimRewards();
        
        _balances[msg.sender] -= amount;
        _stake[msg.sender] += amount;
        
        _apy[msg.sender] = 800 - (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 200);
        
    }
    
    function unstake(uint256 amount) external {
        claimRewards();
        
        _stake[msg.sender] -= amount;
        _balances[msg.sender] += amount;
    }
    
    function mint(address account, uint256 amount) external {
        require(msg.sender == _owner);
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }

    function burn(uint256 amount) external {
        
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        
    }
    
    function claimRewards() internal {
        uint256 reward = _stake[msg.sender] * _apy[msg.sender] * (block.timestamp - _time[msg.sender]) / 31536000 / 10000;
        
        _balances[msg.sender] += reward;
        _time[msg.sender] = block.timestamp;
    }
}
