export set_up_workers

function set_up_workers(target_cpus=Int(floor(Sys.CPU_THREADS/4)))
    # Decide on our exe flag
    exeflag = "--project=$(Base.current_project())"
    # If we're on a SLURM machine, add SLURM_JOB_CPUS_PER_TASK distributed workers
    try
        addprocs(ENV["SLURM_JOB_CPUS_PER_TASK"], exeflags=exeflag)
        print("Running job on $nworkers() workers")
    # Otherwise, add target_cpus workers 
    catch e
        if nworkers() < target_cpus
            if nworkers() == 1
                addprocs(target_cpus, exeflags=exeflag)
            else
                addprocs(target_cpus - nworkers(), exeflags=exeflag)
            end
        end
    end
end