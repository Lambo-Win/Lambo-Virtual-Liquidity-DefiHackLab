/*
                    Ohf                              thm       
                    Ohf                              thm       
                    !LLbhf                              thkLLi    
                    <hhhhf                              thhhh~    
                    ,((qhLf/                          /fLhp((,    
                    \xLhb{{:                    ,{{dhLx/       
                        |hhhh1IIIIIIIIIIIIIIIIIIII[qqqq)         
                    .,,,,thhbbJvvvvxrrrrrrrrrrrrrrrnvvvv[,,,,.    
                    <hhhhhhkvvvvvvv'               lvvvv0hhhh~    
                    <hhhhhhkvvvvt<<                 ''xv0hhhh~    
                (Jv<<<<nhkvvvvtii  1UUUU;   .UUUUf  rv(<<<<uJ|  
                jj\(]    |hkvvvvtii::nhhhh!   'hhhhY  rv-    ?(\jj
                cc~      |hkvvvvj[[>i/UUUUi^^^"UUUUxiinv-      <cc
                    ,:fhkvvvvvvv_~~~~~~~~~~~~~~~[vvvv]^^^^.    
                    OhhhkvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvI    
                fwwwwkhhhkvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvxr[  
                vvZhhhhhhwCCvvvvvvvvvj|(]]]]]]]]]]]]]]]]]]]]]rvj11
                hhhhhhhhhOvvvvvvvvvvv\[{\\\\[lllllllll(\\\(lltvvvv
                hhhhhhhhhOvvvvvvvvvvv\[\hhhhclllllllllqhhhwlltvvvvx
                hhhhhhhhhOvvvvvvvvvvv\[\hhhhclllllllllqhhhwlltvvvv
                hhhhhhhhhOvvvvvvvvvvv\[}||]-~lllllllll_---_lltvCdd
                hhhhhhhhhpO0vvvvvvvvvrt/[[_++++llllllllllli))xvLhh
                hhhhhhhhhhhkUUUUYvvvvvvn))}[[[[>>>>>>>>>~+]UUUUOhh  
                hhhhhhhhhhhhhhhhwvvvvvvvvv)[[[[[[[[[[[[[tvXhhhhhhh
                """""""""/hhhhhhhbbbbbbbbbddddddddddddddbbkhh-""""
                        !11111111111Jhhhhhhhhhhhhhhhhhhhhhhh~    
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LaunchPadUtils} from "./Utils/LaunchPadUtils.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VirtualToken is ERC20, Ownable {
    using SafeERC20 for IERC20;

    uint256 public lastLoanBlock;
    uint256 public loanedAmountThisBlock;

    // immutable and constant
    address public immutable underlyingToken;
    uint256 public constant MAX_LOAN_PER_BLOCK = 300 ether;
    uint8 public immutable underlyingTokenDecimals;


    mapping(address => uint256) public _debt;
    mapping(address => bool) public whiteList;
    mapping(address => bool) public validFactories;

    event LoanTaken(address user, uint256 amount);
    event LoanRepaid(address user, uint256 amount);
    event CashIn(address user, uint256 amount);
    event CashOut(address user, uint256 amount);
    event FactoryUpdated(address newFactory, bool isValid);
    event WhiteListAdded(address user);
    event WhiteListRemoved(address user);

    error DebtOverflow(address user, uint256 debt, uint256 value);

    modifier onlyWhiteListed() {
        require(whiteList[msg.sender], "Only WhiteList");
        _;
    }

    modifier onlyValidFactory() {
        require(validFactories[msg.sender], "Only valid factory can call this function");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _underlyingToken,
        address _admin,
        uint8 _underlyingTokenDecimals
    ) ERC20(name, symbol) Ownable(_admin) {
        require(_underlyingToken != address(0), "Invalid underlying token address");
        underlyingToken = _underlyingToken;
        underlyingTokenDecimals = _underlyingTokenDecimals;
    }

    function isValidFactory(address _factory) external view returns (bool) {
        return validFactories[_factory];
    }

    function updateFactory(address _factory, bool isValid) external onlyOwner {
        validFactories[_factory] = isValid;
        emit FactoryUpdated(_factory, isValid);
    }

    function addToWhiteList(address user) external onlyOwner {
        whiteList[user] = true;
        emit WhiteListAdded(user);
    }

    function removeFromWhiteList(address user) external onlyOwner {
        whiteList[user] = false;
        emit WhiteListRemoved(user);
    }

    function cashIn(uint256 amount) external payable onlyWhiteListed {
        _transferAssetFromUser(amount);
        _mint(msg.sender, amount);
        emit CashIn(msg.sender, amount);
    }

    function cashOut(uint256 amount) external onlyWhiteListed {
        _burn(msg.sender, amount);
        _transferAssetToUser(amount);
        emit CashOut(msg.sender, amount);
    }

    function takeLoan(address to, uint256 amount) external payable onlyValidFactory {
        if (block.number > lastLoanBlock) {
            lastLoanBlock = block.number;
            loanedAmountThisBlock = 0;
        }
        require(loanedAmountThisBlock + amount <= MAX_LOAN_PER_BLOCK, "Loan limit per block exceeded");

        loanedAmountThisBlock += amount;
        _mint(to, amount);
        _increaseDebt(to, amount);

        emit LoanTaken(to, amount);
    }

    /**
     * @notice This function is currently unused.
     */
    function repayLoan(address to, uint256 amount) external onlyValidFactory {
        _decreaseDebt(to, amount);
        _burn(to, amount);
        emit LoanRepaid(to, amount);
    }

    function getLoanDebt(address user) external view returns (uint256) {
        return _debt[user];
    }

    function _increaseDebt(address user, uint256 amount) internal {
        _debt[user] += amount;
    }

    function _decreaseDebt(address user, uint256 amount) internal {
        require(_debt[user] >= amount, "Decrease amount exceeds current debt");
        _debt[user] -= amount;
    }

    function _denormalizeDecimal(uint256 amount) internal view returns (uint256) {
        return (amount * (10 ** underlyingTokenDecimals)) / (10 ** 18);
    }

    /**
     * @dev Transfers the specified amount of the underlying asset from the user to the contract.
     * The amount is first denormalized to match the underlying token's decimals.
     * If the underlying token is the native token (e.g., ETH), the function checks if the sent value is sufficient.
     * Otherwise, it transfers the specified amount of the ERC20 token from the user to the contract.
     * @param amount The amount of the token in the contract's standard decimal format to transfer.
     */
    function _transferAssetFromUser(uint256 amount) internal {
        amount = _denormalizeDecimal(amount);

        if (underlyingToken == LaunchPadUtils.NATIVE_TOKEN) {
            require(msg.value >= amount, "Invalid ETH amount");
        } else {
            IERC20(underlyingToken).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    /**
     * @dev Transfers the specified amount of the underlying asset from the contract to the user.
     * The amount is first denormalized to match the underlying token's decimals.
     * If the underlying token is the native token (e.g., ETH), the function checks if the contract's balance is sufficient and transfers the amount.
     * Otherwise, it transfers the specified amount of the ERC20 token from the contract to the user.
     * @param amount The amount of the token in the contract's standard decimal format to transfer.
     */
    function _transferAssetToUser(uint256 amount) internal {
        amount = _denormalizeDecimal(amount);

        if (underlyingToken == LaunchPadUtils.NATIVE_TOKEN) {
            require(address(this).balance >= amount, "Insufficient ETH balance");
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            IERC20(underlyingToken).safeTransfer(msg.sender, amount);
        }
    }

    // override the _update function to prevent overflow
    function _update(address from, address to, uint256 value) internal override {
        // check: balance - _debt < value
        if (from != address(0) && balanceOf(from) < value + _debt[from]) {
            revert DebtOverflow(from, _debt[from], value);
        }

        super._update(from, to, value);
    }
}
