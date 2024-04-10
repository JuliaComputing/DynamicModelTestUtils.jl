
struct SingleShootingComparision end

function validate(model, data)
    throw("Discrete comparison currently requires JSMO!")
end

function compare_discrete(sys, data_a::DataFrame, data_b::DataFrame, evaluations::Vector{DiscreteEvaluation}=[FinalState(L∞(name=:L∞)), Mean(L2(:L2)), Accumulate(L∞(name=:L∞))])
    @assert "timestamp" ∈ names(data_a) "The dataset A must contain a column named `timestamp`"
    @assert "timestamp" ∈ names(data_b) "The dataset B must contain a column named `timestamp`"
    
    data_a = semijoin(data_a, data_b, on=:timestamp)
    data_b = semijoin(data_b, data_a, on=:timestamp)
    if nrow(data_a) == 0 || nrow(data_b) == 0
        throw("Comparison datasets are empty; check that the intersection of the discretization times is nonempty")
    end
    if nrow(data_a) <= 2 || nrow(data_b) <= 2
        @warn "Two or fewer (typically start and end) timestamps exist in the compared datasets; check that the time discretization of the comparisons align"
    end
    test_results = Dict{Symbol, Any}()
    for evaluation in evaluations
        test_results = mergewith(merge, test_results, Dict([evaluate(evaluation, sys, data_a, data_b); ]))
    end
    return test_results
end
export validate, compare_discrete_to_continous, compare_discrete