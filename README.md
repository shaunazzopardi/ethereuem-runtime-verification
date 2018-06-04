# ethereuem-runtime-verification
Dynamic runtime verification of Ethereum smart contracts as separate smart contracts.

[1] introduces a monitor specification language for Solidity smart contracts, and a monitoring technique that instruments smart contracts which checks inlined in the monitored smart contract. This only works for smart contracts that have not yet been implemented. Here we take a different approach, where we create a separate monitor smart contract to which existing smart contracts can register to, and send events to. This assumes a smart contract comes with generic instrumentation that allows it to call any monitor smart contract.

Current limitations: 

1. Instrumentation in original smart contract must be done manually (i.e. <i>call</i>s or <i>delegatecall</i>s to the respective event trigger method in the monitor smart contract).
2. Event trigger methods in the monitor smart contract have untyped parameters that need to be manually typed.


[1] https://github.com/gordonpace/contractLarva
