### This builds upon the model in pressure_diffusion.i by introducing the DarcyVelocity AuxKernel

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 100
  ny = 10
  xmax = 0.304
  ymax = 0.0257
[]

[Problem]
  type = FEProblem
  coord_type = RZ
  rz_coord_axis = X
[]

[Variables/pressure]
[]

[AuxVariables]
  [velocity]
    order = CONSTANT      # Since "pressure" is approximated linearly, its gradient must be constant
    family = MONOMIAL_VEC # A monomial interpolation means this is an Elemental AuxVariable
  []
[]

[Kernels]
  [darcy_pressure]
    type = DarcyPressure
    variable = pressure
  []
[]

[AuxKernels]
  [velocity]
    type = DarcyVelocity
    variable = velocity       # Store volumetric flux vector in "velocity" variable from above
    pressure = pressure       # Couple to the "pressure" variable from above
    execute_on = TIMESTEP_END # Perform calculation at the end of the solve step - after Kernels run
  []
[]

[Materials]
  [column]
    type = PackedColumn
  []
[]

[BCs]
  [inlet]
    type = DirichletBC
    variable = pressure
    boundary = left
    value = 4000
  []
  [outlet]
    type = DirichletBC
    variable = pressure
    boundary = right
    value = 0
  []
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = ' hypre    boomeramg'
[]

[Outputs]
  exodus = true
[]
