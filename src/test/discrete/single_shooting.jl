
struct SingleShootingComparision end

function validate(model, data)
    throw("Discrete comparison currently requires JSMO!")
end

function compare_discrete_to_continous(
    sol::SciMLBase.AbstractTimeseriesSolution,
    data::DataFrame)
    @assert "timestamp" ∈ names(data) "The data must contain a column named `timestamp`"
    sort!(data, [:timestamp])
    @assert data[!, :timestamp] == sol.t "The data's discretization points and the solution time discretization must match"
    
    results = Dict{Symbol, Any}()
    reference_container = symbolic_container(sol)
    measured_reference = measured_values(reference_container)
    @assert length(measured_reference) > 0 "At least one variable must be marked as measured"
    measured = measured_reference
    
    measured_names = string.(measured)
    if !(all(name->name ∈ names(data), measured_names))
        error("Measured data points must exist in both model solution & test data; measured parameters in solution: $(measured_names) vs. in data $(names(data))")
    end

    data_matrix = collect.(eachrow(data[!, string.(measured)]))  # lame and slow
    solution_data = sol[measured]
    compute_error_metrics(results, solution_data, data_matrix)
    results[:final] = recursive_mean(abs.(solution_data[end] - collect(data[end, string.(measured)])))
    cols = []
    append!(cols, make_cols(namespace_symbol.((:simulated,), measured), solution_data))
    append!(cols, make_cols(namespace_symbol.((:data,), measured), data_matrix))
    results[:data] = DataFrame(cols)
    return results

end
export validate, compare_discrete_to_continous