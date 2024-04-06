
struct SingleShootingComparision end

function validate(model, data)
    throw("Discrete comparison currently requires JSMO!")
end

function compare_discrete(sys, data_a::DataFrame, data_b::DataFrame)
    @assert "timestamp" ∈ names(data_a) "The dataset A must contain a column named `timestamp`"
    @assert "timestamp" ∈ names(data_b) "The dataset B must contain a column named `timestamp`"

    measured = measured_values(sys)
    measured_cols = measured_names(measured)
    @assert all(c->c ∈ names(data_a), measured_cols) "All measured values must exist in both datasets (missing value in A)"
    @assert all(c->c ∈ names(data_b), measured_cols) "All measured values must exist in both datasets (missing value in B)"
    
    test_results = Dict{Symbol, Any}()
    delta_sol = data_a[:, measured_cols] .- data_b[:, measured_cols]
    test_results[:final] = recursive_mean(abs.(collect(delta_sol[end, :])))
    compute_error_metrics(test_results, collect.(eachrow(data_a[:, measured_cols])), collect.(eachrow(data_b[:, measured_cols])))
    return test_results
end
export validate, compare_discrete_to_continous, compare_discrete