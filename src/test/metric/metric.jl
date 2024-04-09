

evaluate(e::DiscreteEvaluation, sys, dt1::DataFrame, dt2::DataFrame) = throw("Unimplemented evaluate for $(typeof(e))")

function _require_solution(sys, dt::DataFrame; name=nothing) 
    @assert "timestamp" ∈ names(dt) "The dataset $name must contain a column named `timestamp`"
    measured = measured_values(sys)
    measured_cols = measured_names(measured)
    @assert all(c->c ∈ names(dt), measured_cols) "All measured values must exist in both datasets (missing value in $name)"
end

function _require_joint_solution(sys, dt1, dt2; check_only_final = false)
    _require_solution(sys, dt1; name = "dt1")
    _require_solution(sys, dt2; name = "dt2")
    if !check_only_final
        @assert dt1[:, :timestamp] == dt2[:, :timestamp] "Both data frames need to share a temporal discretization"
    else
        @assert dt1[end, :timestamp] == dt2[end, :timestamp] "Ending times differ"
    end
end

struct FinalState{M<:Metric} <: DiscreteEvaluation  
    name::Symbol
    metric::M
    FinalState(m::M; name=:final) where {M <: Metric} = new{M}(name, m)
end
function evaluate(f::FinalState, sys, dt1::DataFrame, dt2::DataFrame)
    _require_joint_solution(sys, dt1, dt2; check_only_final = true)
    measured_cols = setdiff(intersect(names(dt1), names(dt2)), "timestamp")
    output = compare(f.metric, sys, dt1[end, measured_cols], dt2[end, measured_cols])
    return name(f) => Dict(outputs(f.metric) .=> output)
end
name(f::FinalState) = f.name

struct Accumulate{M<:Metric, T} <: DiscreteEvaluation 
    name::Symbol
    metric::M
    op::T
    Accumulate(m::M; name=:stage) where {M<:Metric} = let op = acc_op(m); new{M, typeof(op)}(name, m, op) end
    Accumulate(m::M, op::T; name=:stage) where {M<:Metric, T} = new{M, T}(name, m, op)
end
name(f::Accumulate) = f.name

function evaluate(f::Accumulate, sys, dt1::DataFrame, dt2::DataFrame; init = nothing)
    _require_joint_solution(sys, dt1, dt2)
    measured_cols = setdiff(intersect(names(dt1), names(dt2)), "timestamp")
    output = isnothing(init) ? initial_output(f.metric) : init
    for (row1, row2) in Iterators.zip(eachrow(dt1[!, measured_cols]), eachrow(dt2[!, measured_cols]))
        new_output = compare(f.metric, sys, row1, row2)
        output = f.op(output, new_output)
    end
    return name(f) => Dict(outputs(f.metric) .=> output)
end

struct Mean{M<:Metric, T} <: DiscreteEvaluation 
    name::Symbol
    metric::M
    op::T
    Mean(m::M; name=:mean) where {M<:Metric} = let op = acc_op(m); new{M, typeof(op)}(name, m, op) end
    Mean(m::M, op::T; name=:mean) where {M<:Metric, T} = new{M, T}(name, m, op)
end
name(f::Mean) = f.name

function evaluate(f::Mean, sys, dt1::DataFrame, dt2::DataFrame; init = nothing)
    _require_joint_solution(sys, dt1, dt2)
    measured_cols = setdiff(intersect(names(dt1), names(dt2)), "timestamp")
    output = isnothing(init) ? initial_output(f.metric) : init
    for (row1, row2) in Iterators.zip(eachrow(dt1[!, measured_cols]), eachrow(dt2[!, measured_cols]))
        new_output = compare(f.metric, sys, row1, row2)
        output = f.op(output, new_output)
    end
    return name(f) => Dict(outputs(f.metric) .=> mean.(output))
end

acc_op(m::Metric) = (a,b) -> b # throw away the prior state by default 

name(m::Metric)::Symbol = throw("Unimplemented name for metric $(typeof(m))")
outputs(m::Metric)::Vector{Symbol} = throw("Unimplemented outputs for metric $(typeof(m))")
initial_output(m::Metric) = throw("Unimplemented metric output initialization for $(typeof(m)); specify an explicit initalization")

compare(m::Metric, sys, state_a, state_b) = throw("Unimplemented discrete metric comparison for $(typeof(m))")
compare!(o, m::Metric, sys, state_a, state_b) = o .= compare(m, sys, state_a, state_b)


struct L∞ <: Metric
    name::Union{Nothing, Symbol}
    L∞(;name::Union{Nothing, Symbol} = nothing) = new(name)
end
acc_op(::L∞) = (a,b) -> max.(a,b)
name(m::L∞) = m.name
initial_output(m::L∞) = [0.0]
outputs(m::L∞) = [name(m)]
compare(m::L∞, sys, state_a, state_b) = [maximum(abs.(collect(state_a) .- collect(state_b)))]

struct L2 <: Metric 
    name::Union{Nothing, Symbol}
end
acc_op(::L2) = (a,b) -> a .+ b
name(m::L2) = m.name
initial_output(m::L2) = [0.0]
outputs(m::L2) = [name(m)]
compare(m::L2, sys, state_a, state_b) = [norm(collect(state_a) .- collect(state_b))]

export Metric, L∞, L2