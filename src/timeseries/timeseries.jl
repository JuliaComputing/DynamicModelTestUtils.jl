"""
    Timeseries 

A timeseries describes the components of a system at discrete points in time. 
Timeseries must implement:

* `observed(series::Timeseries) :: AbstractArray{Num}` to get the observations that are observed in `state`.
* `domain(series::Timeseries) :: Tuple{Float64, Float64}` the infumum and supremum of the times over which the series is defined.
* `evaluate(series::Timeseries, t0::Float64) :: TimeEvaluator` evaluate the Timeseries starting at time `t0`; note that the real start time
will be determined by the result of the first call to `tick`.
"""
abstract type Timeseries end
export Timeseries

abstract type TimeEvaluator end 

"""
    observed(series::Timeseries) :: AbstractArray{Num}

Get the (potentially namespaced) variables defined by the timeseries `series`.
"""
observed(series::Timeseries)::AbstractArray{Num} = throw("observed not implemented for timeseries of type $(typeof(series))")
export observed

"""
Get a name for the timeseries for namespacing.
"""
name(series::Timeseries)::Symbol = throw("name not implemented for timeseries of type $(typeof(series))")
export name

"""
Returns the (infumum, supremum) of the domain of the timeseries.
"""
domain(series::Timeseries)::Tuple{Float64, Float64} = throw("domain not implemented for timeseries of type $(typeof(series))")
export domain

"""
Get a TimeEvaluator associated with this Timeseries starting at time `t0`.
"""
evaluate(series::Timeseries, t0::Float64) :: TimeEvaluator = throw("evaluate not defined for $(typeof(series))")
export evaluate

struct Unspecified end
export Unspecified

tick!(t::TimeEvaluator)::Union{Nothing, Unspecified, Int64} = throw("tick not defined for $(typeof(t))")
tock(t::TimeEvaluator, tn::Float64) = throw("Dense tock not defined for $(typeof(t))")
tock(t::TimeEvaluator, tn::Int64) = throw("Sparse tock not defined for $(typeof(t))")
tock!(out::AbstractArray, t::TimeEvaluator, tn::Float64) = throw("Dense in-place tock not defined for $(typeof(t))")
tock!(out::AbstractArray, t::TimeEvaluator, tn::Int64) = throw("Sparse in-place tock not defined for $(typeof(t))")
export tick!, tock, tock!

include("dataframe.jl")
include("model.jl")