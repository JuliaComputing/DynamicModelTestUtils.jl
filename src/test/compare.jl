struct DefaultComparison
    field_cmp::Dict{Symbol, Function}
    function DefaultComparison(field_cmp::Dict{Symbol, Function}=Dict{Symbol, Function}(); use_defaults=true) 
        if use_defaults
            merge!(field_cmp, Dict{Symbol, Function}([
                :L∞ => (delta, t) -> norm.(delta, Inf), 
                :L1 => (delta, t) -> norm.(delta, 1), 
                :L2 => (delta, t) -> norm.(delta, 2), 
                :rms => (delta, t) -> sqrt.(1/length(t) .* sum.(map(d-> d .^ 2, delta)))]))
        end
        return new(field_cmp)
    end
end
function (d::DefaultComparison)(c, b, t, n, r) 
    delta = map((o, re) -> o .- re, n, r)
    cmps = [name => cmper(delta, t) for (name, cmper) in d.field_cmp]
    return DataFrame([:var => b, cmps...,
        :observed => SymbolicIndexingInterface.is_observed.(c, b)])
end


function compare(
    new_sol::SciMLBase.AbstractTimeseriesSolution, basis::Vector, 
    reference::DataFrame, reference_basis::Vector,
    cmp; warn_observed=true)
    @assert "timestamp" ∈ names(reference) "The dataset must contain a column named `timestamp`"
    new_container = SymbolicIndexingInterface.symbolic_container(new_sol)
    @assert all(SymbolicIndexingInterface.is_observed.((new_container, ), basis) .| SymbolicIndexingInterface.is_variable.((new_container, ), basis)) "All basis symbols must be observed in the new system"
    @assert all(b ∈ names(reference) for b in reference_basis) "The reference basis must be a subset of the columns in the reference data"
    if new_sol.dense
        dat = new_sol(reference[:, :timestamp], idxs=basis)
        obs = [[dat[j][i] for j=1:nrow(reference)] for i in eachindex(basis)]
        ref = collect.(eachcol(reference[:, Not(:timestamp)]))
        cmp(new_container, basis, reference[:, :timestamp], obs, ref)
    else 
        foldl(red, cmp(row[:timestamp], new_sol[row[:timestamp], basis], row[reference_basis]) for row in eachrow(reference); init=isnothing(init) ? nothing : init(basis))
    end
end

function compare(
    new_sol::SciMLBase.AbstractTimeseriesSolution,
    reference::DataFrame,
    cmp=DefaultComparison(); to_name=string, warn_observed=true)
    @assert "timestamp" ∈ names(reference) "The dataset must contain a column named `timestamp`"

    new_container = SymbolicIndexingInterface.symbolic_container(new_sol)
    all_available = SymbolicIndexingInterface.all_variable_symbols(new_container)
    all_available_syms = Dict(to_name.(all_available) .=> all_available)
    eval_syms = [ begin
        @assert ref_name ∈ keys(all_available_syms) "Reference value $ref_name not found in the new solution (either as state or observed)"
        matching_sym = all_available_syms[ref_name]
        if warn_observed && SymbolicIndexingInterface.is_observed(new_container, matching_sym)
            @warn "The variable $matching_sym is observed in the new solution while the past $ref_name is provided explicitly; problem structure may have changed"
        end
        matching_sym 
    end for ref_name in setdiff(names(reference), ["timestamp"])] 
    return compare(new_sol, eval_syms, reference, setdiff(names(reference), ["timestamp"]), cmp)
end
export compare