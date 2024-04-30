module ModelTesting
using DataFrames, StatsBase, LinearAlgebra
using ModelingToolkit, DifferentialEquations, DiffEqDevTools, SymbolicIndexingInterface
abstract type DiscreteEvaluation end
abstract type Metric end
include("test/measured.jl")
include("test/continuous/delta_sol.jl")
include("test/discrete/single_shooting.jl")
include("test/discrete/merge.jl")
include("test/metric/metric.jl")
include("test/instantaneous/instant.jl")
include("problem_config/problem.jl")
end
