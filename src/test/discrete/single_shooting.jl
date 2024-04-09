
struct SingleShootingComparision end

function validate(model, data)
    throw("Discrete comparison currently requires JSMO!")
end

function compare_discrete(sys, data_a::DataFrame, data_b::DataFrame, evaluations::Vector{DiscreteEvaluation}=[FinalState(L∞(name=:L∞)), Mean(L2(:L2)), Accumulate(L∞(name=:L∞))])
    @assert "timestamp" ∈ names(data_a) "The dataset A must contain a column named `timestamp`"
    @assert "timestamp" ∈ names(data_b) "The dataset B must contain a column named `timestamp`"
    
    test_results = Dict{Symbol, Any}()
    for evaluation in evaluations
        test_results = mergewith(merge, test_results, Dict([evaluate(evaluation, sys, data_a, data_b); ]))
    end
    return test_results
end
export validate, compare_discrete_to_continous, compare_discrete