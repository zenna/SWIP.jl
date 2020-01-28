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
  @test lⁱ = logpdf(Normal(0, 1), x_) + logpdf(Normal(x_, 1), v_)
  @test lⁱ < l
  # yⁱ(ω)
  # yⁱ = y ⌿ x => 100
end

function test()
  x = normal(0, 1)
  y = normal(x, 1)
  x_ = 1.2
  y_ = 2.3
  v_ = 3.4
  ω = Ω(Dict(x.id => x_, y.id => y_))
  
  m = (x, y) | swi(x => v_)
  l = logdensity(m, ω)
  @test l = logpdf(x_, Normal(0, 1)) + logpdf(y_, Normal(v_, 1))
end
