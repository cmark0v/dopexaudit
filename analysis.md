Dopex QA report
================
Dr. cmark0v

Methods and materials
---------------------

Clone repo; Get errors; fix typos in filenames and scripts; furnish docker containers with build stack and security tools. Run all tests existing tests, flatten all in-scope code, Read code starting with DpxEthToken.sol.  Read docs a little. Focus on RdpxV2Bond.sol and RdpxV2Core.sol and anywhere I see math, authentication, questionable standards or ambiguous quality I give extra effort. Scan with mythril. Work on PoCs using the existing test codebase. Try to pay special attention to the interactions between the contracts and foreign ones, as well as potential misused of libraries. 

**background**


I have worked on two bond platforms speccing out and writing calculators for emissions, accounting, as well as risk assessment and analysis. I have formal background(PhD) in analysis of numerical methods.


- Anemic set of tests. Emaciated. 
- bad commenting standards, inaccuracies and incoherent  natspec. 
- no governance system( a wallet with multisig is not a governance system)
- excessive unilateral administrative powers
- signs of a struggle(with math)
- lack of protection from abuse by administrators
- opaque 



Overview
--------


**Auth**


1. **The role based authentication is overkill if you don't need multiple reconfigurable role holders then do not have the features for them.** It is just another place for a potential disaster. It is also a waste of gas. It looks suspicious to people reading the code to see who can burn their tokens and things.

2. **Unilateral unchecked power**  - There is an excess of unrequired power indefinitely available to a single administrative wallet. This is very opaque to users, many wallets can be added and remain somewhat opaque by blockchain standards,

3. **Emergency withdrawl function** - Allows arbitrary and inconsequential withdrawl of all funds by admin at discretion. Does nothing but issue an event. 

4. **Pausability** - same as aforementioned emergency administrative withdrawl, eveything can be paused and unpaused at total dsicretion of a singular wallet. Blocking withdrawls for non-admins  


**Math**


1. **Using single point precision** - There is no advantage to this and it is teetering on the edge of manifesting as critical problems see (I, II)

2. **redundant algebraic forms**  - not properly formulated for the task, (III) see

3. **inconsistent use of  parameters** - digits of accuracy defined in a parameter that is neglected to be used in favor of using hard coded values. it should be used everywhere 1e8 denominator or other appearence deterministically dependent on that choice of parammeter, so that if it is changed, it wont break the whole system.  

4. **excessive use of hard coded constants with no comments** - when you hard code a constant in it has nio variable name so there is not even a hint as to where it could have come from or why it is there so it is good to put a comment 

5. **lack of comments on key equations** - computationally efficient(cheap) and viable(accurate) form of an expression is generally not the nicest on the human eyes, so the form it is derived from should be present in the natspec or other comments. Which should be traceable back to whatever the spec speed on the tech is. 

6. **odd use of percentages in computation** - use of percents converted to a snthetic float fraction over 100 in computation has no computational benefit, no basis on any convention. calculation does not use percents. It uses decimal or fraction representations of floating point numbers. multiplying the synthetic decimal form of a parameter by 100 and storing it like that at runtime is odd and bound to result in operator error or confusion. Percents are a display form of a scaling factor. 




**Tests**


1. **Emaciated set of tests** - maybe it somehoiw has high code line coverage but it does not have execution state space covered

2. **non parameterized tests** comparing things to known outcomes, no parametric tests. Math is being 'tested' against a few trivial values against a few mysterious hard coded outcomes with no visible connection to anything that shows us

3. **no fuzztests** - can cover a lot more ground


**Governance**


1. **unexplained abscence thereof** - no governance specs or code

2. **unilateral control of wallet** -

3. **no penallty for use of emergency functions((such as locking or destruction of contract**

4. **lack of producres defined**

5. **excessive manual procedures** - more things should be done in constructors or with launch scripts that are dept as part of the codewase. 

6. **role based auth is overkill and leaves too many features for potential abuse** - it uses mappings so its not trivial to enumerate all roles and admins. It is way more than what is needed



Details, mitigation
-------------------

**Math**


Most of the themes discussed for the maht above are well addressed by some math guidelines and a few rephrasings of equations.


**practices for sythetic float**


1. Use ``WAD = '1 ether' = 1e18`` as the defact default choice

2. deviate from ``WAD`` to ``RAY=1e27`` or from ``WAD`` to ``1e8`` if it solves a problem

3. multiply and add then subtract and divide. you want to finish with a division by the base or some positive function of it

4. analyze your schemes and verify the bounds and order of ops

5. spec out the human readable(physically relevant) form the the equation in docs and in comment

6. after rearranging according to 3 and 4 to keep every operation in bounds, combine all like terms and reduce the number of operations if possible

7. store parameters in the same precision as the calculations unless otherwise labeled in setters and variable names. 


----------------------------------------------------------------


 Here i will include the work that belongs to gas optimizations i had. We are arranging  closer 


```solidity 
    //ReLPContract.sol:277
    mintokenAAmount =
    (((amountB / 2) * tokenAInfo.tokenAPrice) / 1e8) -
    (((amountB / 2) * tokenAInfo.tokenAPrice * slippageTolerance) / 1e16);
```

to $$0.5\text{ammountB}\cdot\text{tokenAPrice}\cdot(1- \text{slippageTolerance})$$ which is shorter, less ops, and has better computational properties in tis case 


$$
((\frac{a_B}{2}  r_A) / 10^8) - ((\frac{a_B}{2})  r_A  \epsilon_{slip}) / 10^{16}) 
$$

sub $$a_B=\frac{\text{ammountB}}{10^{k}}$$ for $k$ decimals in given asset $$ r_A 10^{d} = \text{tokenAPrice}$$ and $$\epsilon_{slip} 10^{d} = \text{slippageTolerance} $$       rearrange and put it back as a float, the form that looks nice 


$$
\frac{1}{2} a_B  r_A(1-\epsilon_{slip})
$$

change back to ints by multiplying the ratios $$\epsilon_{slip} = \frac{\text{slippageTolerance}}{10^{d}},  and $$r_A = \frac{\text{tokenAPrice}}{10^{d}}$$  sub $$1 = \frac{10^d}{10^d}$$

$$
\frac{ a_B \text{tokenAPrice}}{2 \cdot 10^{d}}\left(\frac{10^d}{10^d}- \frac{\text{slippageTolerance}}{10^d} \right) = \frac{a_B \text{tokenAPrice} }{2 \cdot 10^{2d} }(10^d-\frac{\text{slippageTolerance}}{})
$$

Now back in terms of $$d=8$$, we do all the multiply first then divide), and double check seeing that slippage tolerance is always less than 1e8, so we get 


```solidity

    (amountB*tokenAInfo.tokenAPrice*(1e8-slippageTolerance))/2e16

```

4 operations now, rather than 8. minimum value $$\text{tokenA} \approx 2.01 \cdot 10^8$$


----------------------------------------------------------------


**bad numerics**

Here is an expression also with excess operations and bad numerical properties. The denominator evaluates analytically to ``1e9`` which makes the expression ``(reLPFactor*sqrt(tokenAReserve))/1e7``. 

```solidity   //// ReLPContract.sol 228
    uint256 baseReLpRatio = (reLPFactor *
    Math.sqrt(tokenAInfo.tokenAReserve) *
    1e2) / (Math.sqrt(1e18)); // 1e6 precision
```

So this comment is inaccurate(not sure what its supposed to mean either, it is inaccurate in several ways). $\text{reLPFactor} \in \{1,2,3...10^{8}\}$ This is linear dependence, thus the min is at the bountry ``(1*sqrt(1e18)*1e2)/1e9` = 1e2`` which is 2 digits of precision. 



If the token is Tether then we are in that case we are at ``1e5/1e9 -> 0`` if ``reLPFactor`` is in the range ``1e8`` then we are getting 4 to 5 digits of precision





####Auth/Gov




1. **medium** - role based auth system The wallet launching the contracts ``RdpxDecayingBonds.sol``, ``RdpxV2Bond.sol``, ``RdpxV2Core.sol``, ``RdpxV2Core.sol``, ``ReLPContract.sol``, ``UniV2LiquidityAMO.sol``, ``UniV3LiquidityAMO.sol`` is grated ``DEFAULT_ADMIN_ROLE``, which can be used to unilaterally drain all funds, pause contracts, grant other permissions to mint and burn, etc. This is by no means necessary from a technical perspective and exposes the team to unnecessary risk and potential liabilities. If it is a multisig that is still an opaque mechanism that involves trusting a group of people who know eachother and have like interests. 



```solidity
    constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    //  ReLPContract.sol: 

    constructor() {
      _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

```

These things should be controlled through a governance contract with transparent, well documented, verified procedure for any serious administrative events. Multiple parties with transparent incentives to operate with the protocol's best interest in mind. When it is launched, the governance contract address is supplied in the transaction and never has to be done through separate manual processes. 



2. ``MINTER_ROLE`` is granted to ``msg.sender`` on launch of these token contracts. This is even less necessary than having the admin role defined in this manner. The contract that controls minting should be supplied at launch as a argument to constructor, and reconfigurable through a transparent governance mechanism controlled by a contract. It should reject configuration of more than one minter if the protocol doesn't require it. It should verify that the minter is not a wallet and is known to the governance contract. 


3. **emergency withdrawl function lacks safeguards and formality** The emergency withdrawl should be only callable if the contract is permanently locked and can not be re-activated. Or alternatively, involve some other irreversible action. that action should be controlled only by governance and not subject to unilateral(one wallet) action. 

```solidity
    function emergencyWithdraw(
    address[] calldata tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _whenPaused();
    IERC20WithBurn token;

    for (uint256 i = 0; i < tokens.length; i++) {
    token = IERC20WithBurn(tokens[i]);
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    emit EmergencyWithdraw(msg.sender, tokens);
    }
```

At the very least, it should not be possible to call this for the tokens t he contract is holding for its functions



4. **Unilateral governance** - the governance functions, all very powerful and capable of serious harm to users and collapse of the protocol, are formally controlled by a single wallet that launches them. This is not acceptable. No one cares if it is a multi-sig wallet. This is supposed to be trust-agnostic, transparent  platform as much as possible. Dumping out funds should authorize depositors to withdraw or require their approval in a vote







