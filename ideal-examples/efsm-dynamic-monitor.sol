pragma solidity 0.4.19;
pragma experimental ABIEncoderV2;

// symbolic monitors must be implemented in separate smart contracts
contract SymbolicMonitor{
    mapping(string => bool) functionReturnValues;
    
    function callCondition(string functionName) returns(bool){
        //possible security risk, can this call internal functions? 
        
        if(this.call(bytes32(keccak256(functionName)))){
            return functionReturnValues[functionName];
        }
        else{
            return false;
        }
    }
    
    function callAction(string functionName) returns(bool){
        //possible security risk, can this call internal functions? 
        
        if(!this.call(bytes32(keccak256(functionName)))){
            return true;
        }
        else{
            return false;
        }
    }
}

contract MonitoringEngine{
    
    //Variable change event
    struct VariableChange{
        string name;
        string typeName;
        bool exists;
    }
    
    //Method just called event
    struct MethodCall{
        string name;
        bool exists;
    }
    
    //Represents state in finite-state machine
    struct State{
        uint no;
        bool exists;
    }
    
    //Event and state tuple
    //Represents event happening while at state
    struct Tuple{
        VariableChange v;
        MethodCall m;
        State state;
        bool exists;
    }
    
    struct GuardedTransition{
        string condition;
        string action;
        State state;
    }

    //Represents finite-state machine
    struct FSM{
        //The state we are currently in
        State currentState;
        
        //the index of a final state is mapped to true
        mapping(uint => bool) finalStates;
        
        //Tuples are associated with a hash
        mapping(bytes32 => Tuple) transitionsHash;

        //an event-state tuple is associated with a list of guarded transitions to the next state.
        mapping(bytes32 => GuardedTransition[]) transitions;
    }
    
    //the current properties monitored for
    mapping(bytes32 => SymbolicMonitor) propertiesConditionsAndActions;
    mapping(bytes32 => FSM) allProperties;
    mapping(bytes32 => bool) activeProperties;
    mapping(address => bytes32[]) userProperties;
    mapping(string => address[]) userInterestedCalls;
    
////////////////////////////////////////////////
// Adding Properties that are to be monitored //
////////////////////////////////////////////////
    
    //TODO hash needs to be created by this contract
    
    //Starting a new property, given a certain hash and the initial state
    function startProperty(bytes32 hash, uint currentState, address symbolicMonitorAddress){
        FSM memory prop;
        allProperties[hash] = prop;
        propertiesConditionsAndActions[hash] = SymbolicMonitor(symbolicMonitorAddress);
        
        State memory state;
        state.no = currentState;
        state.exists = true;
        
        prop.currentState = state;
        
        userProperties[msg.sender].push(hash);
    }
    
    //Adding transition with a method call
    function addPropertyTransition(bytes32 hash, uint fromState, MethodCall ev, uint toState, string conditionFunctionName, string actionFunctionName){
        State memory from;
        from.no = fromState;
        from.exists = true;
        
        State memory to;
        to.no = toState;
        to.exists = true;

    
        Tuple memory tuple;
        tuple.m = ev;
        tuple.state = from;
        tuple.exists = true;
        
        allProperties[hash].transitionsHash[bytes32(keccak256(tuple))] = tuple;
        
        GuardedTransition transition;
        transition.condition = conditionFunctionName;
        transition.action = actionFunctionName;
        
        allProperties[hash].transitions[bytes32(keccak256(tuple))].push(transition);
        
        userInterestedCalls[ev.name].push(msg.sender);
    }
    
    //Adding transition with a variable change
    function addPropertyTransition(bytes32 hash, uint fromState, VariableChange ev, uint toState, string conditionFunctionName, string actionFunctionName){
        State memory from;
        from.no = fromState;
        from.exists = true;
        
        State memory to;
        to.no = toState;
        to.exists = true;
    
        Tuple memory tuple;
        tuple.v = ev;
        tuple.state = from;
        tuple.exists = true;
        
        GuardedTransition transition;
        transition.condition = conditionFunctionName;
        transition.action = actionFunctionName;
        
        allProperties[hash].transitions[bytes32(keccak256(tuple))].push(transition);
        
        allProperties[hash].transitionsHash[bytes32(keccak256(tuple))] = tuple;

        userInterestedCalls[ev.name].push(msg.sender);
    }

    //Adding final states
    function addFinalState(bytes32 hash, uint finalState){
        allProperties[hash].finalStates[finalState] = true;
    }
    
    //Activate monitoring of property
    function activatePropertyMonitoring(bytes32 hash){
        activeProperties[hash] = true;
    }
    
    //Stop monitoring of property
    function stopPropertyMonitoring(bytes32 hash){
        activeProperties[hash] = false;
    }
    
//////////////////////////////////////////////////////
// Handing transitioning in properties given events //
//////////////////////////////////////////////////////
    
    //Trigger FSM with given hash, with method call event
    function trigger(bytes32 hash, MethodCall method) internal returns(bool){
        if(!activeProperties[hash]) return false;
        
        Tuple memory tuple;
        tuple.state = allProperties[hash].currentState;
        tuple.m = method;
        tuple.exists = true;
        
        bytes32 tupleHash = bytes32(keccak256(tuple));
    
        return trigger(hash, tupleHash);
    }
    
    //Trigger FSM with given hash, with variable change event
    function trigger(bytes32 hash, VariableChange variableChange) internal returns(bool){
        if(!activeProperties[hash]) return false;
        
        Tuple memory tuple;
        tuple.state = allProperties[hash].currentState;
        tuple.v = variableChange;
        tuple.exists = true;
        
        bytes32 tupleHash = bytes32(keccak256(tuple));
    
        return trigger(hash, tupleHash);
    }
    
    function trigger(bytes32 hash, bytes32 tupleHash) returns(bool){
        SymbolicMonitor symbolicMonitor = propertiesConditionsAndActions[hash];
        
        GuardedTransition[] toIterateOver = allProperties[hash].transitions[tupleHash];
        
        for(uint i = 0; i < toIterateOver.length; i++){
            GuardedTransition guardedTransition = toIterateOver[i];
            if(symbolicMonitor.callCondition(guardedTransition.condition)){
                i = toIterateOver.length;
                
                symbolicMonitor.callAction(guardedTransition.action);
                
                allProperties[hash].currentState = guardedTransition.state;
            }
        }
        
                    
        if(allProperties[hash].finalStates[allProperties[hash].currentState.no]){
            return false;
        }
        else{
            return true;
        }
    }
    
    //Trigger all FSMs user is interested in with given call
    function trigger(address user, MethodCall call) internal{
        bytes32[] memory FSMtoTrigger = userProperties[user];
        
        for(uint i = 0; i < FSMtoTrigger.length; i++){
            bytes32 hash = FSMtoTrigger[i];
            trigger(hash, call);
        }
    }
    
    //Trigger all FSMs user is interested in with given variable change
    function trigger(address user, VariableChange variableChange) internal{
        bytes32[] memory FSMtoTrigger = userProperties[user];
        
        for(uint i = 0; i < FSMtoTrigger.length; i++){
            bytes32 hash = FSMtoTrigger[i];
            trigger(hash, variableChange);
        }
    }

    //Trigger all FSMs using given call
    function trigger(MethodCall call) internal{
        address[] memory interestedUsers = userInterestedCalls[call.name];
        
        for(uint i = 0; i < interestedUsers.length; i++){
            trigger(interestedUsers[i], call);
        }
    }

    //Trigger all FSMs using given variable change
    function trigger(VariableChange variableChange) internal{
        address[] memory interestedUsers = userInterestedCalls[variableChange.name];
        
        for(uint i = 0; i < interestedUsers.length; i++){
            trigger(interestedUsers[i], variableChange);
        }
    }

    //Method called by instrumentation points in monitored contracts
    function handleEvent(string name, bool methodCall, bool variableChange) internal{
        if(methodCall){
            MethodCall memory call;
            call.name = name;
            call.exists = true;
            
            trigger(call);
        }
        else if(variableChange){
            VariableChange memory change;
            change.name = name;
            change.exists = true;
            
            trigger(change);
        }
    }
}
