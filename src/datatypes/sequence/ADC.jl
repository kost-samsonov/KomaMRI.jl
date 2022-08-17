"""
    ADC(N, T)
    ADC(N, T, delay)
    ADC(N, T, delay, Δf, ϕ)

The ADC object.

!!! note
    All the time inputs are meant to be non-negative. When inputs are not defined, they are
    set to zero.

# Arguments
- `N::Int64`: number of acquired samples
- `T::Float64`: duration to acquire the samples
- `delay::Float64`: delay to start the acquisition
- `Δf::Float64`: the delta frequency. It's meant to compensate RF pulse phases
- `ϕ::Float64`: the phase. It's meant to compensate RF pulse phases
"""
mutable struct ADC
    N::Int64
    T::Float64
    delay::Float64
    Δf::Float64
    ϕ::Float64
    function ADC(N, T, delay, Δf, ϕ)
      T < 0 || delay < 0 ? error("ADC timings must be positive.") : new(N, T, delay, Δf, ϕ)
    end
    function ADC(N, T, delay)
		T < 0 || delay < 0 ? error("ADC timings must be positive.") : new(N, T, delay, 0, 0)
    end
    function ADC(N, T)
		T < 0 ? error("ADC timings must be positive.") : new(N, T, 0, 0, 0)
    end
end

"""
    getproperty(x::Vector{ADC}, f::Symbol)

Overchages Base.getproperty(). It is meant to access properties of the ADC vector `x`
directly without the need to iterate elementwise.

# Arguments
- `x::Vector{ADC}`: the vector of ADC objects
- `f::Symbol`: custom options are the `:dur` symbol. `:dur` represents the acquisition time
    regarding the delay

# Returns
- `y`: (::Vector{Any}) the vector with the property defined by the `f` for all elements of
    the ADC vector `x`

``` julia-repl
julia> ADCs = [ADC(16, 8, 2); ADC(8, 4, 6); ADC(4, 2, 8)]
3-element Vector{ADC}:
 ADC(16, 8.0, 2.0, 0.0, 0.0)
 ADC(8, 4.0, 6.0, 0.0, 0.0)
 ADC(4, 2.0, 8.0, 0.0, 0.0)

julia> getproperty(ADCs, :dur)
3-element Vector{Float64}:
 10.0
 10.0
 10.0
```
"""
getproperty(x::Vector{ADC}, f::Symbol) = begin
  if f == :dur
		T, delay = x.T, x.delay
		ΔT = T .+ delay
		ΔT
  else
    getproperty.(x, f)
  end
end

"""
    times = get_sample_times(seq)

Returns an array of times where the samples of the sequence `seq` are acquired.

# Arguments
- `seq`: (::Sequence) the sequence object

# Returns
- `times`: (::Vector{Float64}) the time array of acquired samples
"""
function get_sample_times(seq)
    T0 = cumsum([0; durs(seq)], dims=1)
    times = []
    for i = 1:length(seq)
        if is_ADC_on(seq[i])
            δ = seq.ADC[i].delay
            T = seq.ADC[i].T
            N = seq.ADC[i].N
            t = range(0, T; length=N).+T0[i].+δ #range(0,T,N) works in Julia 1.7
            append!(times, t)
        end
    end
    return times
end

"""
    phase = get_sample_phase_compensation(seq)

Returns the array of phases for every acquired sample in the sequence `seq`.

!!! note
    This function is useful to compensate the phase when the RF pulse has a phase too. Refer
    to the end of the [`run_sim_time_iter`](@ref) function to see its usage.

# Arguments
- `seq`: (::Sequence) the sequence object

# Returns
- `phase`: (::Vector{Complex{Int64}}) the array of phases for every acquired sample
"""
function get_sample_phase_compensation(seq)
  phase = []
  for i = 1:length(seq)
      if is_ADC_on(seq[i])
          N = seq.ADC[i].N
          ϕ = seq.ADC[i].ϕ
          aux = ones(N) .* exp(1im*ϕ)
          append!(phase, aux)
      end
  end
  return phase
end
