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
    
    //Represents finite-state machine
    struct FSM{
        //The state we are currently in
        State currentState;
        
        //the index of a final state is mapped to true
        mapping(uint => bool) finalStates;
        
        //Tuples are associated with a hash
        mapping(bytes32 => Tuple) transitionsHash;
        
        //an event-state tuple has is associated with the state to be in after the event in the tuplehappens at the state in the tuple.
        mapping(bytes32 => State) eventsToState;
    }
    
    //the current properties monitored for
    mapping(bytes32 => FSM) currentProperties;
    
    function startProperty(bytes32 hash, uint currentState){
        FSM prop;
        currentProperties[hash] = prop;
        
        State state;
        state.no = currentState;
        state.exists = true;
        
        prop.currentState = state;
    }
    
    function addPropertyTransition(bytes32 hash, uint fromState, MethodCall ev, uint toState){
        State from;
        from.no = fromState;
        from.exists = true;
        
        State to;
        to.no = toState;
        to.exists = true;

    
        Tuple tuple;
        tuple.m = ev;
        tuple.state = from;
        tuple.exists = true;
        
        currentProperties[hash].transitionsHash[bytes32(keccak256(tuple))] = tuple;
        currentProperties[hash].eventsToState[bytes32(keccak256(tuple))] = to;
    }
    
    function addPropertyTransition(bytes32 hash, uint fromState, VariableChange ev, uint toState){
        State from;
        from.no = fromState;
        from.exists = true;
        
        State to;
        to.no = toState;
        to.exists = true;

    
        Tuple tuple;
        tuple.v = ev;
        tuple.state = from;
        tuple.exists = true;
        
        currentProperties[hash].transitionsHash[bytes32(keccak256(tuple))] = tuple;
        currentProperties[hash].eventsToState[bytes32(keccak256(tuple))] = to;
    }

    function addFinalState(bytes32 hash, uint finalState){
        currentProperties[hash].finalStates[finalState] = true;
    }
    
    function trigger(bytes32 hash, MethodCall method) returns(bool){
        Tuple tuple;
        tuple.state = currentProperties[hash].currentState;
        tuple.m = method;
        tuple.exists = true;
        
        bytes32 tupleHash = bytes32(keccak256(tuple));
        State next = currentProperties[hash].eventsToState[tupleHash];
        if(currentProperties[hash].eventsToState[tupleHash].exists){
            currentProperties[hash].currentState = next;
        }
    }
    
    function trigger(bytes32 hash, VariableChange variableChange) returns(bool){
        Tuple tuple;
        tuple.state = currentProperties[hash].currentState;
        tuple.v = variableChange;
        tuple.exists = true;
        
        bytes32 tupleHash = bytes32(keccak256(tuple));
        State next = currentProperties[hash].eventsToState[tupleHash];
        if(currentProperties[hash].eventsToState[tupleHash].exists){
            currentProperties[hash].currentState = next;
        }
                    
        if(currentProperties[hash].finalStates[currentProperties[hash].currentState.no]){
            return false;
        }
        else{
            return true;
        }
    }
}
