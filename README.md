# ethereuem-runtime-verification
Dynamic runtime verification of Ethereum smart contracts.

monitor.sol contains a monitoring engine for properties as finite-state machines, with events as method calls or changes to variables. These can be added dynamically, as opposed to inlining them statically (as in [1]), with the caveat that points-of-interest are instrumented statically by registering their occurrence with the <i>handleEvent</i> function.

This is a work-in-progress.

TODO:

1. Properties as extended finite-state machines.
2. Example of instrumented smart contract
3. Automated method to instrument smart contracts for events of interest.
4. Directing payment of monitoring costs to user accounts interested in the property holding.


[1] https://github.com/gordonpace/contractLarva
