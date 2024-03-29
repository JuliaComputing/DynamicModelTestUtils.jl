struct AppendingTimeseries{TA<:Timeseries, TB<:Timeseries} <: Timeseries 
    a::TA
    b::TB
end

observed(a::AppendingTimeseries) = 
    [mkpath.((a.name, ), observed(a.a)); 
     mkpath.((b.name, ), observed(a.b)); ]
function value(a::AppendingTimeseries, var, ts)
    tag = first(pathels(var))
    if tag == a.name
        return value(a.a, mkpath(pathels(var)[2:end]), ts)
    elseif tag == b.name 
        return value(a.b, mkpath(pathels(var)[2:end]), ts)
    else 
        throw("Path tag $(tag) not found in appended timeseries!")
    end
end
    