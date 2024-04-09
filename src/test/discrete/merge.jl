function merge_results(
    results...
)
    for (name, result) in results 
        @assert "timestamp" ∈ names(result) "Each result must have a column `timestamp`; the result set $(name) is missing this."
    end

    merged = nothing
    for (name, result) in results
        col_rename(n) = string(n) == "timestamp" ? Symbol(n) : namespace_symbol(name, n)
        if isnothing(merged)
            merged = rename(result, names(result) .=> col_rename.(names(result)))
        else 
            merged = outerjoin(merged, result; 
                on=:timestamp, 
                validate=(true, true), 
                renamecols = (x -> x) => col_rename)
        end
    end
    return merged
end
export merge_results