using Cassette
import Base:~
import Distributions.logpdf
export sample, unif, pointwise, <|, rt, Ω, logpdf
const ID = NTuple{N, Int} where N

# Random variables are functions from a sample space to some realization space.
# They are either primitive, or pointwise functions of primitives, i.e., derived
# The sample space object is a mapping from identifiers to outputs of primitives

"Sample space object"
struct Ω{T}
  data::T
end

# A projection of ω to some index id is simply ω[id]
# ΩProj is a symbolic representation of this projection
# It's useful to maintain a reference to the parent ω

"id'th element of ω, with refeence to parent"
struct ΩProj{OM}
  ω::OM
  id::ID
end

"Project `ω` onto id"
proj(ω, id) = ΩProj(ω, id)

# # Sampling
# "Sample a random ω ∈ Ω"
# sample(::Type{Ω{T}}) where T = Ω(T())
# sample(f) = f(sample(Ω))

# Primitives

# FIXME: get! should be omega type dependent
function (T::Type{<:Distributions.Distribution})(ωπ::ΩProj, args...)
  get!(ωπ.ω.data, ωπ.id, rand(T(args...)))
end

(T::Type{<:Distributions.Distribution})(ω::Ω, args...) =
  T(proj(ω, (1,)), args...)

# Conditioning
struct Observation{X, V}
  x::X
  v::V
end
observe(x, v) = Observation(x, v)
Base.:|(x, y::Observation) = Observation()

# log pdf
"Wraps val, and is mutable"
mutable struct Wrapper{T}
  val::T
  seen::Set{ID}
end
Cassette.@context LogPdfCtx

function logpdf(rv, ω)
  # FIXME: Don't double count
  ld = Wrapper(0.0, Set{ID}()) # log 1
  ctx = LogPdfCtx(metadata = ld)
  Cassette.overdub(ctx, rv, ω)
  ld.val
end

function Cassette.posthook(ctx::LogPdfCtx, ret, T::Type{<:Distributions.Distribution}, ωπ::ΩProj, args...)
  # @show ωπ.id
  # println("")
  if ωπ.id ∉ ctx.metadata.seen
    # @show ret
    # @show args  
    @show ctx.metadata.val += Distributions.logpdf(T(args...), ret)
    push!(ctx.metadata.seen, ωπ.id)
  end
  println("")
  ret
end

# This is necessary to compose contexts, in particular logpdf and hadctx
function Cassette.posthook(ctx::LogPdfCtx, ret, ::typeof(Cassette.overdub), ictx, T::Type{<:Distributions.Distribution}, ωπ::ΩProj, args...)
  println("")?
  if ωπ.id ∉ ctx.metadata.seen
    # @show ret
    # @show args 
    @show ctx.metadata.val += Distributions.logpdf(T(args...), ret)
    push!(ctx.metadata.seen, ωπ.id)
  end
  println("")
  ret
end

# (Conditional) independence 
Cassette.@context CIIDCtx # Use cassette to augment enivonrment with extra state

"""Conditionally independent and identically distributed given `shared` parents

Returns the `id`th element of an (exchangeable) sequence of random variables
that are identically distributed with `f` but conditionally independent given
random variables in `shared`.

This is essentially constructs a plate where all variables in shared are shared,
and all other parents are not.
"""
function ciid(f, id::ID, shared)
  let ctx = CIIDCtx(metadata = (shared = shared, id = id))
    ω -> withctx(ctx, f, ω)
  end
end

withctx(ctx, f, ω) = Cassette.overdub(ctx, f, ω)
function Cassette.overdub(ctx::CIIDCtx, ::typeof(withctx), ctxinner, f, ω)
  # Merge the scope
  id = (ctxinner.metadata.id..., ctx.metadata.id...)
  shared = (ctxinner.metadata.shared..., ctx.metadata.shared...)
  Cassette.overdub(CIIDCtx(metadata = (shared = shared, id = id)), f, ω)
end

"I.I.D.: `ciid` with nothing shar ed"
ciid(f, id::ID) = ciid(f, id, ())
ciid(f, id::Integer) = ciid(f, (id,))
ciid(f, id::Integer, shared) = ciid(f, (id,), shared)

function Cassette.overdub(ctx::CIIDCtx, T::Type{<:Distributions.Distribution}, ω::Ω, args...)
  @show proj(ω, ctx.metadata.id) 
  T(proj(ω, ctx.metadata.id), args...)
end

function Cassette.overdub(ctx::CIIDCtx, x, ω::Ω)
  # @show x
  # @show ctx.metadata.shared
  # TODO: This is using julia function equivalence which is a bit shaky eh
  if x in ctx.metadata.shared
    x(ω)
  else
    Cassette.recurse(ctx, x, ω)
  end
end

# Syntactic Sugar (to make model-building nicer)

"Random tuple"
rt(fs...) = ω -> map(f -> f(ω), fs)

"""Supports notation `i ~ x <| (y,z,)`
which is the ith element of an (exchangeable) sequence of random variables that are
identically distributed with x but conditionally independent given y and z.
"""
struct Plate{F, S}
  f::F
  shared::S
end

@inline <|(f, shared::Tuple) = Plate(f, shared)
~(id, f) = ciid(f, id)
~(id, plate::Plate) = ciid(plate.f, id, plate.shared)

# Pointwise
Cassette.@context PWCtx
Lifted = Union{map(typeof, (+, -, /, *))...}
Cassette.overdub(::PWCtx, op::Lifted, x::Function) = ω -> op(x(ω))
Cassette.overdub(::PWCtx, op::Lifted, x::Function, y::Function) = ω -> op(x(ω), y(ω))
Cassette.overdub(::PWCtx, op::Lifted, x::Function, y) = ω -> op(x(ω), y)
Cassette.overdub(::PWCtx, op::Lifted, x, y::Function) = ω -> op(x, y(ω))
pointwise(f) = Cassette.overdub(PWCtx(), f)