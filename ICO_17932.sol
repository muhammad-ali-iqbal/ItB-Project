// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

interface IERC20 {

    function totalSupply() external view returns (uint);

    function balanceOf(address tokenOwner) external view returns (uint);

    function allowance(address tokenOwner, address spender) external view returns (uint);

    function transfer(address to, uint tokens) external returns (bool);

    function approve(address spender, uint tokens) external returns (bool);

    function transferFrom(address from, address to, uint tokens) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ERC20Token is IERC20{
    
    string public name="ERC20";
    string public symbol="ERC";
    uint public decimals = 4;
    uint public supply;
    address public founder;
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) allowed;
    
    constructor(){
        supply = 5000000;
        founder = msg.sender;
        balances[founder] = supply;
    }

    function totalSupply() public view override returns (uint){
        return supply;
    }
    
    function allowance(address tokenOwner, address spender) public view override returns (uint){
        return allowed[tokenOwner][spender];
    } 
    
    function approve(address spender, uint tokens) public override returns (bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address sender, address recipient, uint tokens) public virtual override returns (bool){
        require(allowed[sender][recipient] > tokens);
        require(balances[sender] >= tokens);
        balances[sender] -= tokens;
        balances[recipient] += tokens;
        allowed[sender][recipient] -= tokens;
        return true;
    }

    function balanceOf(address tokenOwner) public override view returns (uint){
        return balances[tokenOwner];
    }
    
    function transfer(address recipient, uint tokens) public virtual override returns (bool){
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        balances[recipient] += tokens;
        balances[msg.sender] -= tokens;
        emit Transfer(msg.sender,recipient,tokens);
        return true;
    }
}

contract ERC20ICO is ERC20Token{

    address public owner;
    address payable public deposit;
    uint public price = 0.001 ether;
    uint public hardCap = 300 ether;
    uint public amountCollected;
    uint public saleStart;
    uint public saleEnd;
    uint public tradeStart;
    uint public maxInvestment = 5 ether;
    uint public minInvestment = 0.000000000001 ether;
    enum state{ beforeStart, started, afterEnd, ended}
    state public icoState;
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    event Invest(address investor, uint value, uint tokens);
    
    constructor(address payable dep) {
        deposit = dep;
        owner = msg.sender;
        icoState = state.beforeStart;
        saleStart = block.timestamp;
        saleEnd = saleStart + 604800;
        tradeStart = saleEnd + 604800;
    }
    
    function halt() public onlyOwner{
        icoState = state.ended;
    }
    
    function unhalt() public onlyOwner{
        icoState = state.started;
    }
    
    function getCurrentState() public view returns (state) {
        if(icoState == state.ended){
            return state.ended;
        } else if(block.timestamp < saleStart) {
            return state.beforeStart;
        } else if(block.timestamp >= saleStart && block.timestamp <= saleEnd){
            return state.started;
        }
        return state.afterEnd;
    }
    
    function invest() payable public returns (bool) {
        icoState = getCurrentState();
        require(icoState == state.started);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        uint tokens = msg.value / price;
        require(amountCollected + msg.value <= hardCap);
        amountCollected += msg.value;
        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);
        emit Invest(msg.sender,msg.value,tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public override returns (bool) {
        require(block.timestamp > tradeStart);
        super.transfer(to,tokens);
        return true;
    }
    

    function transferFrom(address from, address to, uint tokens) public override returns (bool) {
        require(block.timestamp > tradeStart);
        super.transferFrom(from,to,tokens);
        return true;
    }

}