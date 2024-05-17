
function test_instantaneous(
    sys::ModelingToolkit.AbstractSystem,
    ic,
    checks::Num;
    t = nothing) # todo: after porting to v9 use InitializationSystem to solve the checks system
    if !SymbolicIndexingInterface.is_observed(checks)
        @assert false "The given check values are not observed values of the given system"
    end
    sv = ModelingToolkit.varmap_to_vars(ic, variable_symbols(sys); defaults=default_values(sys))
    pv = ModelingToolkit.varmap_to_vars(ic, parameter_symbols(sys); defaults=default_values(sys))

    obsfun = SymbolicIndexingInterface.observed(sys, checks)
    if SymbolicIndexingInterface.istimedependent(sys)
        @assert !isnothing(t) "The kwarg t must be given (and be a non-nothing value) if the system is time dependent"
        return obsfun(sv, pv, t)
    elseif !SymbolicIndexingInterface.constant_structure(sys)
        @assert false "The system's structure must be constant to use test_instantaneous; to be fixed" # TODO
    else
        return obsfun(sv, pv)
    end
end

function test_instantaneous(
    sys::ModelingToolkit.AbstractSystem,
    ic,
    checks::Array;
    t = nothing) # todo: after porting to v9 use InitializationSystem to solve the checks system
    prob = ODEProblem(sys, ic, (0.0, 0.0))
    getter = getu(prob, checks)
    return getter(prob)
end

export test_instantaneous