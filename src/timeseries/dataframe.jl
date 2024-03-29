struct DataframeTimeseries <: Timeseries 
    data::DataFrame
    time_field::Symbol
    name::Symbol
    states
    function DataframeTimeseries(data, time_field, name)
        # todo: check that time_field is in the timeseries
        return new(data, time_field, name, filter(x -> x != time_field, Symbol.(names(data))))
    end
end
export DataframeTimeseries

# invariant: we assume that `data` is sorted in time order
# todo: check this on initialization
mutable struct DataframeEvaluator <: TimeEvaluator 
    backing::DataframeTimeseries
    now::Union{Int64, Nothing}
end

observed(series::DataframeTimeseries) = filter(s->s != series.time_field, Symbol.(names(series.data)))
value(series::DataframeTimeseries, var, ts) = series.data[ts, var] # I don't think that this will actually work
name(series::DataframeTimeseries) = series.name 
domain(series::DataframeTimeseries) = 
    (minimum(series.data[:, series.time_field]), maximum(series.data[:, series.time_field]))

evaluate(series::DataframeTimeseries, t0::Float64) =
    DataframeEvaluator(series, 
        let firstel = findfirst(series.data[:, series.time_field] .<= t0)
            isnothing(firstel) || firstel == 1 ? nothing : firstel - 1 # back the first element up by 1 so that `tick` works
        end)

function tick!(ev::DataframeEvaluator) 
    if isnothing(ev.now)
        ev.now = 1
    else 
        ev.now += 1
    end
    if ev.now > nrow(ev.backing.data)
        return nothing
    end
    return ev.now
end
function tock(ev::DataframeEvaluator, tn::Int64)
    @assert ev.now <= nrow(ev.backing.data) "Time span of backing data exceeded at $(ev.now)"
    @assert tn == ev.now "Discrete timeseries must be `tocked`/iterated with exactly their specified time basis points (got $tn expected $(ev.backing.data[ev.now, ev.backing.time_field]))"
    return (collect(ev.backing.data[tn, ev.backing.states]), ev.backing.data[tn, ev.backing.time_field])
end
function tock!(out::AbstractArray, ev::DataframeEvaluator, tn::Int64)
    @assert ev.now <= nrow(ev.backing.data) "Time span of backing data exceeded at $(ev.now)"
    @assert tn == ev.now "Discrete timeseries must be `tocked`/iterated with exactly their specified time basis points (got $tn expected $(ev.backing.data[ev.now, ev.backing.time_field]))"
    out .= ev.backing.data[tn, ev.backing.states]
    return ev.backing.data[tn, ev.backing.time_field]
end