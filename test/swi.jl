using Test
using SWIP
using Distributions

function testintervention()
  # Normally distributed random variable with id 1
  x = 1 ~ ω -> Normal(ω, 0, 1)
  
  # Normally distributed random variable with id 2 and x as mean
  y = 2 ~ (ω -> Normal(ω, x(ω), 1)) <| (x,)
  x_ = 0.1
  y_ = 0.3

  # An omega object -- like a trace
  ω = Ω(Dict((1,) => x_, (2,) => y_))

  # model -- tuple-valued random variable ω -> (x(ω), y(ω)), becase we want joint pdf
  m = rt(x, y)

  # Log density of model wrt ω
  l = logpdf(m, ω)

  # Check it is what it should be
  @test l == logpdf(Normal(0, 1), x_) + logpdf(Normal(x_, 1), y_)

  # Intervened model
  v_ = 100.0

  # y had x been v_
  yⁱ = y | had(x => v_)

  # new model with Intervened variables
  mⁱ = rt(x, yⁱ)

  # log pdf of interved model on same ω
  lⁱ = logpdf(mⁱ, ω)
  logpdf(x, ω)

  
  @test lⁱ == logpdf(Normal(0, 1), x_) + logpdf(Normal(v_, 1), y_)
  @test lⁱ < l
end