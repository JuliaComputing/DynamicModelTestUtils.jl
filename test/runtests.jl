using JuliaSimModelOptimizer
using ModelTesting
using DifferentialEquations, DataFrames, ModelingToolkit
import SymbolicIndexingInterface
using Test

@testset "ModelTesting.jl" begin
    include("timeseries.jl")
    include("block_modeling.jl")
end
