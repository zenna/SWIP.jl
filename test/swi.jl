using Test
using SWIP
using Distributions

function testintervention()
  x = 1 ~ ω -> Normal(ω, 0, 1)
  y = 2 ~ (ω -> Normal(ω, x(ω), 1)) <| (x,)
  x_ = 0.1
  y_ = 0.3
  ω = Ω(Dict((1,) => x_, (2,) => y_))

  m = rt(x, y)
  l = logpdf(m, ω)
  @test l == logpdf(Normal(0, 1), x_) + logpdf(Normal(x_, 1), y_)

  # Intervened model
  v_ = 100.0
  yⁱ = y | had(x => v_)
  mⁱ = rt(x, yⁱ)
  lⁱ = logpdf(mⁱ, ω)
  logpdf(x, ω)
  @test lⁱ == logpdf(Normal(0, 1), x_) + logpdf(Normal(v_, 1), y_)
  @test lⁱ < l
end