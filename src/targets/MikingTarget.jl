struct MikingTarget <: StreamTarget
    command::Cmd
end
java_seed_32bit(rng::AbstractRNG) = rand(rng, UInt32)

initialization(target::MikingTarget, rng::AbstractRNG, replica_index::Int64) =
  StreamState(
              `$(target.command)
              $(java_seed_32bit(rng))`,
              replica_index)

  miking_coin() =
MikingTarget(`$(miking_executable("miking-dppl","out")) `)

function setup_miking(
  repo_name,
  organization = "miking-lang",branch_name= "develop")

  auto_install_folder = mkpath(mpi_settings_folder())
  repo_path="$auto_install_folder/$repo_name"
  if isdir(repo_path)
    @info "it seems setup_miking() was already ran for $repo_name; to force re-runing the setup for $repo_name, first remove the folder $repo_path"
    return nothing
  end

   cd(auto_install_folder) do
     run(`git clone -b $branch_name --single-branch https://github.com/$organization/$repo_name.git`)

  end

  cd(repo_path) do
    run(`make install`)
  end
  return nothing
end

function miking_compile_model(repo_name,model_path)
  repo_path = miking_repo_path(repo_name)
  cd(repo_path) do
    run(`cppl $repo_path/$model_path -m mcmc-naive --cps none --temper --no-print-samples`)
  end

end

miking_repo_path(repo_name)= 
    "$(mkpath(mpi_settings_folder()))/$repo_name"

function miking_executable(repo_name,exec_name)
    repo_path = miking_repo_path(repo_name)
    if !isdir(repo_path)
        error("run Pigeons.setup_miking(\"$repo_name\") first (this only needs to be done once)")
    end
    
    return `$repo_path/$exec_name`
end

