module ModelTestingCalibration 

using ModelTesting, ModelingToolkit
using JuliaSimModelOptimizer


function ModelTesting.validate(model::AbstractTimeDependentSystem, data; pem_coefficient=nothing, search_space = nothing, experiment_kwargs...)

    if !(:model_transformations ∈ keys(experiment_kwargs))
        if !isnothing(pem_coefficient)
            model_transformations = [PredictionErrorMethod(pem_coefficient)]
        else
            model_transformations = []
        end
    else
        model_transformations = []
    end
    println(experiment_kwargs)
    experiment = Experiment(data, model; 
        model_transformations = model_transformations, 
        filter(arg->first(arg) != :model_transformations, experiment_kwargs)...)
    # no search space - this is just a validation run
    i = InverseProblem([experiment], nothing, search_space)
    sim_sol = simulate(experiment, i)
    return compare_discrete_to_continous(sim_sol, data)
end

end