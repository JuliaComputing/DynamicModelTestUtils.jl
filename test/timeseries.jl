Base.isapprox((v1, t1)::Tuple{Vector{Float64}, Float64}, (v2, t2)::Tuple{Vector{Float64}, Float64}) = v1 ≈ v2 && t1 ≈ t2
tol = 1e-8

@testset "Continous" begin 
    @testset "Model-Model Comparison" begin 
        using ModelingToolkit: t_nounits as t, D_nounits as D
        @variables x(t) [measured=true] y(t) [measured=true]
        @parameters τ
        @named fol_sys = ODESystem([D(x) ~ (1 - y) / τ; y ~ x], t)
        fol = structural_simplify(fol_sys)
        prob1 = ODEProblem(fol, [fol.x => 0.0], (0.0, 10.0), [fol.τ => 3.0])
        sol1 = solve(prob1, Tsit5(), reltol = 1e-8, abstol = 1e-8)
        prob2 = ODEProblem(fol, [fol.x => 0.0], (0.0, 10.0), [fol.τ => 3.0])
        sol2 = solve(prob2, Tsit5(), reltol = 1e-8, abstol = 1e-8)
        prob3 = ODEProblem(fol, [fol.x => 0.0], (0.0, 10.0), [fol.τ => 1.0])
        sol3 = solve(prob3, Tsit5(), reltol = 1e-8, abstol = 1e-8)

        results = compare_solutions(:reference=>sol1, [:good=>sol2, :bad=>sol3])
        
        @test results[:metrics][:good][:l∞] < tol
        @test results[:metrics][:good][:l2] < tol
        @test results[:metrics][:good][:final] < tol
        @test results[:metrics][:bad][:l∞] > tol
        @test results[:metrics][:bad][:l2] > tol
        @test results[:metrics][:bad][:final] > tol

        knots = collect(1:0.1:10)
        results = compare_solutions(:reference=>sol1, [:good=>sol2, :bad=>sol3]; knots=knots)
        
        @test nrow(results[:data]) == length(knots)
        @test results[:metrics][:good][:l∞] < tol
        @test results[:metrics][:good][:l2] < tol
        @test results[:metrics][:good][:final] < tol
        @test results[:metrics][:bad][:l∞] > tol
        @test results[:metrics][:bad][:l2] > tol
        @test results[:metrics][:bad][:final] > tol
    end
end