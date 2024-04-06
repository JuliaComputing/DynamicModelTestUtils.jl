_symbolic_subset(a, b) = all(av->any(bv->isequal(av, bv), b), a) 

function namespace_symbol(prefix, sym)
    return Symbol(string(prefix) * "/" * string(sym))
end

function make_cols(names, rows)
    cols = []
    for (i, name) in enumerate(names)
        col = zeros(length(rows))
        for (j, row) in enumerate(rows)
            col[j] = row[i]
        end
        push!(cols, name=>col)
    end
    return cols
end

function discretize_solution(solution::SciMLBase.AbstractTimeseriesSolution, time_ref::SciMLBase.AbstractTimeseriesSolution)
    container = symbolic_container(time_ref)
    ref_t_vars = independent_variable_symbols(container)
    if length(ref_t_vars) > 1
        @error "PDE solutions not currently supported; only one iv is allowed"
    end
    return discretize_solution(solution, time_ref[first(ref_t_vars)])
end
function discretize_solution(solution::SciMLBase.AbstractTimeseriesSolution, time_ref::DataFrame)
    @assert "timestamp" ∈ names(time_ref) "The dataset B must contain a column named `timestamp`"
    return discretize_solution(solution, collect(time_ref[!, "timestamp"]))
end
function discretize_solution(solution::SciMLBase.AbstractTimeseriesSolution)
    container = symbolic_container(solution)
    ref_t_vars = independent_variable_symbols(container)
    if length(ref_t_vars) > 1
        @error "PDE solutions not currently supported; only one iv is allowed"
    end
    return discretize_solution(solution, solution[ref_t_var] )
end
function discretize_solution(solution::SciMLBase.AbstractTimeseriesSolution, time_ref::AbstractArray)
    container = symbolic_container(solution)
    measured = measured_values(container)
    ref_t_vars = independent_variable_symbols(container)
    if length(ref_t_vars) > 1
        @error "PDE solutions not currently supported; only one iv is allowed"
    end
    ref_t_var = first(ref_t_vars)
    
    matching_timebase = solution[ref_t_var] == time_ref

    if matching_timebase # if the time_ref match the timebase of the problem then use the value at the nodes regardless of if it's dense or sparse
        cols = make_cols(String["timestamp"; measured_names(measured)], solution[[ref_t_var; measured]])
    elseif solution.dense # continious-time solution, use the interpolant    
        cols = make_cols(String["timestamp"; measured_names(measured)], solution(time_ref, idxs=[ref_t_var; measured]))
    else
        throw("Cannot discretize_solution sparse solution about a different timebase.")
    end
    return DataFrame(cols)
end
export discretize_solution

function compare_dense_solutions(
    reference::SciMLBase.AbstractTimeseriesSolution,
    sol::SciMLBase.AbstractTimeseriesSolution;
    integrator=Tsit5()
)
    results = Dict{Symbol, Any}()
    reference_container = symbolic_container(reference)
    containers = symbolic_container(sol)

    measured_reference = measured_values(reference_container)
    sol_measured = measured_values(containers)
    @assert _symbolic_subset(measured_reference, sol_measured) "Test solutions must expose a superset of the reference's variables for comparison"
    @assert length(measured_reference) > 0 "Compared solutions must share at least one measured variable"
    measured = measured_reference

    timebounds(sol) = (sol.t[1], sol.t[end])
    @assert reference.dense "Dense (integrated) comparision requires a dense reference solution"
    @assert sol.dense "Test solution must be dense in order to use continous-time comparison"
    @assert timebounds(sol) == timebounds(reference) "Test solution has time range $(timebounds(sol)) which differs from the reference $(timebounds(reference))"

    ref_t_vars = independent_variable_symbols(reference_container)
    if length(ref_t_vars) > 1
        @error "PDE solutions not currently supported; only one iv is allowed"
    end
    ref_t_var = first(ref_t_vars) 

    function compare!(du, u, p, t) 
        du .= abs.(reference(t, idxs=measured) .- sol(t, idxs=measured))
    end
    func = ODEFunction(compare!; sys = SymbolCache(collect(Symbol.(measured)), [], ref_t_var))
    prob = ODEProblem(func, zeros(length(measured)), timebounds(reference))
    soln = solve(prob, integrator)
    return soln
end
export compare_dense_solutions

function compute_error_metrics(
    output_results, 
    ref_soln, test_soln)
    delta = ref_soln - test_soln
    output_results[:l∞] = maximum(vecvecapply((x) -> abs.(x), delta))
    output_results[:l2] = sqrt(recursive_mean(vecvecapply((x) -> float(x) .^ 2, delta)))
end