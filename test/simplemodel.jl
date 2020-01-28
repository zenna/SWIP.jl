using SWIP
using Base.Test

# Untemplated model
H ~ :H normal(0, 1)
X = normal(θ, 1)
Y = normal(X, Y)
X ⟂ (Y ¦ x => 2)

t = trace((H = 1.23, X = 1.34. Y = 1.23))

# Templated model
x ~ Real

# Unspecified Distributions
X ⟂ (Y ¦ x => x)
H ~ ud(0, 1)
X = ud(θ, 1)
Y = ud(X, Y)
@test_throws UninterpretedDensity sample(Y)