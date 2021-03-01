### This builds upon the model in pressure_diffusion.i by introducing the DarcyVelocity AuxKernel

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 100
  ny = 10
  xmax = 0.304  # Length of test chamber
  ymax = 0.0257 # Test chamber radius
[]

[Problem]
  type = FEProblem
  coord_type = RZ
  rz_coord_axis = X
[]

[Variables/pressure]
[]

[AuxVariables]
  # [velocity_x]
  #   order = CONSTANT
  #   family = MONOMIAL
  # []
  # [velocity_y]
  #   order = CONSTANT
  #   family = MONOMIAL
  # []
  # [velocity_z]
  #   order = CONSTANT
  #   family = MONOMIAL
  # []
  [velocity]
    order = CONSTANT
    family = MONOMIAL_VEC
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
    variable = velocity
    pressure = pressure
    execute_on = TIMESTEP_END
  []
  # [velocity_x]
  #   type = VectorVariableComponentAux
  #   variable = velocity_x
  #   component = x
  #   execute_on = timestep_end
  #   vector_variable = velocity
  # []
  # [velocity_y]
  #   type = VectorVariableComponentAux
  #   variable = velocity_y
  #   component = y
  #   execute_on = timestep_end
  #   vector_variable = velocity
  # []
  # [velocity_z]
  #   type = VectorVariableComponentAux
  #   variable = velocity_z
  #   component = z
  #   execute_on = timestep_end
  #   vector_variable = velocity
  # []
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
  l_tol = 1e-16 # tolerate max 64-bit precision (16 significant digits) to avoid round-off errors
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = ' hypre    boomeramg'
[]

[Outputs]
  exodus = true
[]
