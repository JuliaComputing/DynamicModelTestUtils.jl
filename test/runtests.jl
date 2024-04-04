using JuliaSimModelOptimizer
using ModelTesting
using DifferentialEquations, DataFrames, ModelingToolkit
import SymbolicIndexingInterface
using Test

@testset "ModelTesting.jl" begin
    include("timeseries.jl")
end
