using ModelTesting
using DifferentialEquations, DataFrames
import SymbolicIndexingInterface
using Test

@testset "ModelTesting.jl" begin
    include("timeseries.jl")
end
