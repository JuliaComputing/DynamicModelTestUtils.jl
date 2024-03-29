struct ModelSolutionTimeseries <: Timeseries 
    sol :: ODESolution
    observed :: Union{AbstractArray, Nothing} # either an explicitly specified array or `nothing` if we should just take the states from the system
    name :: Symbol 
end
export ModelSolutionTimeseries

mutable struct ModelEvaluator <: TimeEvaluator 
    backing::ModelSolutionTimeseries
    now::Float64
end
# todo: check that forall v ∈ observed, v ∈ all_symbols(sol)

observed(series::ModelSolutionTimeseries) = 
    isnothing(series.observed) ? SymbolicIndexingInterface.variable_symbols(series.sol) : series.observed
name(series::ModelSolutionTimeseries) = series.name
domain(series::ModelSolutionTimeseries) = (minimum(series.sol.t), maximum(series.sol.t))
function evaluate(series::ModelSolutionTimeseries, t0::Float64) 
    @assert t0 >= series.sol.t[1] "Initial time $(t0) must be >= the initial solution time $(series.sol.t[1])"
    @assert t0 <= series.sol.t[end] "Initial time $(t0) must be <= the final solution time $(series.sol.t[end])"
    return ModelEvaluator(series, t0) 
end

function tick!(t::ModelEvaluator)
    return t.now <= t.backing.sol.t[end] ? Unspecified() : nothing
end

function tock(t::ModelEvaluator, tn::Float64)
    @assert tn >= t.backing.sol.t[1] "Sampled time $(tn) must be >= the initial solution time $(series.sol.t[1])"
    @assert tn <= t.backing.sol.t[end] "Sampled time $(tn) must be <= the final solution time $(series.sol.t[end])"
    return [t.backing.sol(tn); ], tn # this is ugly why does the solution datatype of ODESolutions change?
end

function tock(out::AbstractArray, t::ModelEvaluator, tn::Float64)
    @assert tn >= t.backing.sol.t[1] "Sampled time $(tn) must be >= the initial solution time $(series.sol.t[1])"
    @assert tn <= t.backing.sol.t[end] "Sampled time $(tn) must be <= the final solution time $(series.sol.t[end])"
    # todo: observed tracking
    out .= t.backing.sol(tn)
    return tn
end