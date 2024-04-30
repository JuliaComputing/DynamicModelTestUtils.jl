using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant

@testset "Block Modeling" begin 
    @testset "RC Explicit" begin 
        R = 1.0
        C = 1.0
        V = 1.0
        @variables t
        @named resistor = Resistor(R = R)
        @named capacitor = Capacitor(C = C)
        @named source = Voltage()
        @named constant = Constant(k = V)
        @named ground = Ground()

        @named sensor = PotentialSensor()
        @named key_parameter = MeasureComponent()

        rc_eqs = [connect(constant.output, source.V)
                connect(source.p, resistor.p)
                connect(resistor.n, capacitor.p)
                connect(capacitor.n, source.n, ground.g)
                connect(sensor.p, capacitor.p)
                sensor.phi ~ key_parameter.value]

        @named rc_model = ODESystem(rc_eqs, t,
            systems = [resistor, capacitor, constant, source, ground, sensor, key_parameter])
        sys = structural_simplify(rc_model)
        prob1 = ODEProblem(sys, Pair[], (0, 10.0))
        sol1 = solve(prob1, Tsit5())
        prob2 = ODEProblem(sys, Pair[capacitor.C => 0.9], (0, 10.0))
        sol2 = solve(prob2, Tsit5())
        prob3 = ODEProblem(sys, Pair[capacitor.C => 5.0], (0, 10.0))
        sol3 = solve(prob3, Tsit5())

        d1 = discretize_solution(sol1, sol1)
        d2 = discretize_solution(sol2, sol1)
        d3 = discretize_solution(sol3, sol1)
        results_good = compare_discrete(sys, d1, d2)
        results_bad = compare_discrete(sys, d1, d3)
    end
    @testset "RC Functional" begin 
        R = 1.0
        C = 1.0
        V = 1.0
        @variables t
        @named resistor = Resistor(R = R)
        @named capacitor = Capacitor(C = C)
        @named source = Voltage()
        @named constant = Constant(k = V)
        @named ground = Ground()

        @named sensor = PotentialSensor()
        @named key_parameter = Measurement(sensor)

        rc_eqs = [connect(constant.output, source.V)
                connect(source.p, resistor.p)
                connect(resistor.n, capacitor.p)
                connect(capacitor.n, source.n, ground.g)
                connect(sensor.p, capacitor.p)]

        @named rc_model = ODESystem(rc_eqs, t,
            systems = [resistor, capacitor, constant, source, ground, sensor, key_parameter])
        sys = structural_simplify(rc_model)
        prob1 = ODEProblem(sys, Pair[], (0, 10.0))
        sol1 = solve(prob1, Tsit5())

        ref = DataFrame(:timestamp => sol1.t, Symbol(resistor.v) => sol1[resistor.v])
        measure, measured_sys = compare_data(resistor.v, ref)(sys)
        prob_measured = ODEProblem(measured_sys, Pair[], (0, 10.0))
        sol_measured = solve(prob_measured, Tsit5())

        prob2 = ODEProblem(sys, Pair[capacitor.C => 0.9], (0, 10.0))
        sol2 = solve(prob2, Tsit5())
        prob3 = ODEProblem(sys, Pair[capacitor.C => 5.0], (0, 10.0))
        sol3 = solve(prob3, Tsit5())

        d1 = discretize_solution(sol1, sol1)
        d2 = discretize_solution(sol2, sol1)
        d3 = discretize_solution(sol3, sol1)
        results_good = compare_discrete(sys, d1, d2)
        results_bad = compare_discrete(sys, d1, d3)
    end
end
