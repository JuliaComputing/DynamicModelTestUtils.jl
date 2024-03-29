```@meta
CurrentModule = ModelTesting
```

# ModelTesting

Documentation for [ModelTesting](https://github.com/BenChung/ModelTesting.jl).

ModelTesting is intended to facilitate the easy testing and post-facto analysis of ModelingToolkit models.
Test ensembles are constructed using two core abstractions:

* *Rollouts*, or an execution of a model. A rollout consists of a model and the data required to execute the model forward (which could consist of parameter values, real observations/control inputs, or synthetic components that should be plugged into the system). Rollouts can also modify the model being executed (such as introducing new equations to track conservation properties).
* *Timeseries*, which describe the state of a system as it executes forward (PDEs are TBD). A timeseries consists of time-indexed data whose values inhabit named states. Rollouts can be executed to create a timeseries, but you can also get a timeseries from test data or an analytic solution. 
Timeseries can be combined in a namespace-aware way with the <+ operator; combining timeseries requires that both are defined over an overlapping interval and can be evaluated at the same points (by default the union of the points). Timeseries are not nessecarily tabular!

The library then works by executing evaluations over rollouts. Timeseries are defined over a time span that's encoded into the timeseries and is checked for mutual consistentcy before evaluation. 

Questions:
* How to represent parameters? Want to be able to have multiple parameter maps and be able to overlay them. Should be version controlled separately from the models. 
* The results data in the below examples is implicitly timebased. What do we do about timeseries that don't have a consistent time base (for example how do we compare results between two different solvers or between an adaptive solver and sampled real data)?


```julia
reference = Timeseries.FromDataFrame([...])
previous = Timseries.FromFile([...])

baseline = Rollout(mymodel) + ParametersFile("baseparams.jl") + Time(0, 10) + Solver(Tsit5()) 
paramset1 = baseline + ParametersFile("params1.jl")
rk4 = baseline + Solver(RK4())
tracking = baseline + Tracking(reference)
conservation = baseline + Metrics.Conservation()

@named baseline_sol = evaluate(baseline)
@named params1_sol = evaluate(paramset1)

Results("output.nc") do 
       baseline_sol
    <+ params1_sol
    <+ reference
    <+ Evaluations.within(baseline_sol, reference_sol, 0.5; measure=norm)
    <+ Evaluations.within(baseline_sol, rk4, 0.5; measure=norm)
end
```


```@index
```

```@autodocs
Modules = [ModelTesting]
```
