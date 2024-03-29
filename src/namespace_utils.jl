mkpath(a::Symbol, b::Symbol) = Symbol(string(a) * "/" * string(b))
function mkpath(s :: Vararg{Symbol})
    if length(s) == 0
        throw("Concatening empty path!")
    end
    return reduce(mkpath, s)
end
pathels(p::Symbol) = Symbol.(split(string(p), '/'))