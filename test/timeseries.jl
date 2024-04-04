Base.isapprox((v1, t1)::Tuple{Vector{Float64}, Float64}, (v2, t2)::Tuple{Vector{Float64}, Float64}) = v1 ≈ v2 && t1 ≈ t2
tol = 1e-6

@testset "Continous" begin 
    @testset "Model-Model Mixed (self-discretized) Comparison" begin 
        @variables t 
        D = Differential(t)
        # using ModelingToolkit: t_nounits as t, D_nounits as D
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
    @testset "Model-Model Continous Comparison" begin 
        @variables t 
        D = Differential(t)
        #using ModelingToolkit: t_nounits as t, D_nounits as D
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

        results = compare_dense_solutions(:reference=>sol1, [:good=>sol2, :bad=>sol3])
        @test results[Symbol("good/x(t)"), end] < tol
        @test results[Symbol("good/y(t)"), end] < tol
        @test results[Symbol("bad/x(t)"), end] > tol
        @test results[Symbol("bad/y(t)"), end] > tol
    end
end

@testset "Discrete" begin 
    @testset "JSMO" begin 
        @variables t 
        D = Differential(t)
        #using ModelingToolkit: t_nounits as t, D_nounits as D
        @variables x(t)=0.0 [measured=true] y(t) [measured=true]
        @parameters τ=1.0
        @named fol_sys = ODESystem([D(x) ~ (1 - y) / τ; y ~ x], t)
        fol = structural_simplify(fol_sys)

        #generate the reference data
        ref_prob = ODEProblem(fol, [fol.x => 0.0], (0.0, 10.0), [fol.τ => 1.0])
        ref_sol = solve(ref_prob, Tsit5(), reltol = 1e-8, abstol = 1e-8)
        data = DataFrame(["timestamp" => Float64[], "x(t)" => Float64[], "y(t)" => Float64[]])
        for t in LinRange(0.0, 1.0, 1000)
            push!(data, [t, ref_sol(t, idxs=fol.x) + randn() * 0.1, ref_sol(t, idxs=fol.y) * randn() * 0.1])
        end
        
        results_bad = ModelTesting.validate(fol, data; search_space=[fol.τ => (0.5,0.5)], params = [fol.τ => 0.5], u0 = [fol.x => 0.0])
        results_good = ModelTesting.validate(fol, data; search_space=[fol.τ => (1.0,1.0)], params = [fol.τ => 1.0], u0 = [fol.x => 0.0])
        @test results_good[:metrics][:l∞] < results_bad[:metrics][:l∞]
        @test results_good[:metrics][:l2] < results_bad[:metrics][:l2]
        CSV.write("results.csv", results_bad[:data])
        display(results_good[:data])
    end
end