[Mesh]
  type = GeneratedMesh
  dim = 1
[]

[Problem]
  solve = false
[]

[Variables]
  [u]
  []
[]

[Kernels]
  [zero_viscosity]
    type = DarcyPressure
    variable = u
    permeability = 0.8451e-09
    viscosity = 0
  []
[]

[Executioner]
  type = Steady
[]
