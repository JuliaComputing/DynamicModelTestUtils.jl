
struct MeasuredVariable end
Symbolics.option_to_metadata_type(::Val{:measured}) = MeasuredVariable
ismeasured(x::Num, args...) = ismeasured(Symbolics.unwrap(x), args...)
function ismeasured(x, default = true)
    p = Symbolics.getparent(x, nothing)
    p === nothing || (x = p)
    Symbolics.getmetadata(x, MeasuredVariable, default)
end

function measured_values(sys, v=all_variable_symbols(sys))
    filter(x -> ismeasured(x, false), v)
end
