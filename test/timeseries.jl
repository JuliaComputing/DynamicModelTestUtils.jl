Base.isapprox((v1, t1)::Tuple{Vector{Float64}, Float64}, (v2, t2)::Tuple{Vector{Float64}, Float64}) = v1 ≈ v2 && t1 ≈ t2


@testset "Timeseries" begin 
    @testset "Model" begin 
        f(u, p, t) = 1.01 * u
        u0 = 1 / 2
        tspan = (0.0, 1.0)
        prob = ODEProblem(
            ODEFunction(f, sys = SymbolicIndexingInterface.SymbolCache([:x], [], :t)), u0, tspan)
        sol = solve(prob, Tsit5(), reltol = 1e-8, abstol = 1e-8)
        series = ModelSolutionTimeseries(sol, [:x], :test_sol)
        @test observed(series) == [:x]
        @test domain(series) == tspan
        evaluator = evaluate(series, 0.0)
        @test tick!(evaluator) == Unspecified()
        @test tock(evaluator, 0.0) ≈ ([sol[1]], 0.0)
        @test tick!(evaluator) == Unspecified()
        @test tock(evaluator, 1.0) ≈ ([sol[end]], 1.0)
    end
    @testset "Dataframe" begin 
        data = DataFrame(t=[0.0, 0.5, 1.0], x=[0.0, 1.0, 2.0])
        series = DataframeTimeseries(data, :t, :test_data)
        @test observed(series) == [:x]
        @test domain(series) == (0.0, 1.0)
        evaluator = evaluate(series, 0.0)
        @test tick!(evaluator) == 1
        @test tock(evaluator, 1) ≈ ([data[1, :x]], 0.0)
        @test tick!(evaluator) == 2
        @test tock(evaluator, 2) ≈ ([data[2, :x]], 0.5)
        @test tick!(evaluator) == 3
        @test tock(evaluator, 3) ≈ ([data[3, :x]], 1.0)
    end
    
end