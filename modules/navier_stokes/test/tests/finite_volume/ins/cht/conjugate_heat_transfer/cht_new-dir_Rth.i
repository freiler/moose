rho_salt = 2000
cp_salt = 2000
k_salt = 0.6
# L = 425000
# T_solidus = 730
# T_liquidus = 732

rho_solid = 2000
cp_solid = 900
k_solid = 10

T_hot = 400
T_cold = 300
h_s = 0.0

# Reference enthalpy: h(T_solidus) = 0
# h_hot_salt = ${fparse L + cp_salt*(T_hot - T_solidus)}

[Problem]
  kernel_coverage_check = false
  material_coverage_check = false
  previous_nl_solution_required = true
  linear_sys_names = 'energy_system  p_system u_system solid_energy_system'
[]
[FVInterpolationMethods]
  [harm]
    type = FVHarmonicAverage
  []
[]
[Mesh]
  [solid_mesh]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 400
    xmin = 0.0
    xmax = 0.5
    subdomain_ids = 0
    bias_x = 1.0
  []

  [fluid_mesh]
    type = GeneratedMeshGenerator
    dim = 1
    nx = 400
    xmin = 0.5
    xmax = 1.0
    subdomain_ids = 1
    bias_x = 1.0
  []

  [name_solid]
    type = RenameBlockGenerator
    input = solid_mesh
    old_block = 0
    new_block = 'solid'
  []

  [name_salt]
    type = RenameBlockGenerator
    input = fluid_mesh
    old_block = 1
    new_block = 'salt'
  []

  [stitch]
    type = StitchMeshGenerator
    inputs = 'name_solid name_salt'
    stitch_boundaries_pairs = 'right left'
  []

  [interface]
    type = SideSetsBetweenSubdomainsGenerator
    input = stitch
    primary_block = 'solid'
    paired_block = 'salt'
    new_boundary = interface
  []
[]

[UserObjects]
  [rc]
    type = RhieChowMassFlux
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = pressure
    rho = 1
    p_diffusion_kernel = p_diffusion
    block = salt
  []
[]

[Variables]
  # [h_salt]
  #   type = MooseLinearVariableFVReal
  #   solver_sys = energy_system
  #   block = salt
  #   initial_condition = ${h_hot_salt}
  # []
  # [temperature]
  #   type = MooseLinearVariableFVReal
  #   solver_sys = energy_system
  # []
  [temp_salt]
    type = MooseLinearVariableFVReal
    solver_sys = energy_system
    block = salt
    initial_condition = ${T_hot}
  []
  [temp_solid]
    type = MooseLinearVariableFVReal
    solver_sys = solid_energy_system
    block = solid
    initial_condition = ${T_cold}
  []
  [vel_x]
    type = MooseLinearVariableFVReal
    solver_sys = 'u_system'
    initial_condition = 0
    block = salt
  []
  [pressure]
    type = MooseLinearVariableFVReal
    solver_sys = 'p_system'
    initial_condition = 0
    block = salt
  []
[]

# [FVICs]
#   [ic_u_1]
#     type = FVConstantIC
#     variable = temperature
#     value = 300
#     block = 'solid'
#   []
#   [ic_u_2]
#     type = FVConstantIC
#     variable = temperature
#     value = 400
#     block = 'salt'
#   []
# []

[AuxVariables]
  # [temp_salt]
  #   type = MooseLinearVariableFVReal
  #   block = salt
  # []
  # [fl]
  #   type = MooseVariableFVReal
  #   block = salt
  #   initial_condition = 1.0
  # []
[]

[AuxKernels]
  # [T_from_h]
  #   type = FunctorAux
  #   functor = T_from_p_h
  #   variable = temp_salt
  #   block = salt
  #   execute_on = 'INITIAL TIMESTEP_END'
  # []
  # [fl_from_h]
  #   type = FunctorAux
  #   functor = liquid_fraction
  #   variable = fl
  #   block = salt
  #   execute_on = 'INITIAL TIMESTEP_END'
  # []
[]

[LinearFVKernels]
  [p_diffusion]
    type = LinearFVAnisotropicDiffusion
    variable = pressure
    diffusion_tensor = Ainv
    block = salt
    use_nonorthogonal_correction = false
  []

  # [h_time]
  #   type = LinearFVTimeDerivative
  #   variable = h_salt
  #   factor = ${rho_salt}
  #   block = salt
  # []

  # [h_conduction]
  #   type = LinearFVDiffusion
  #   variable = h_salt
  #   diffusion_coeff = kappa_h_salt
  #   use_nonorthogonal_correction = false
  #   block = salt
  # []
  [h_time]
    type = LinearFVTimeDerivative
    variable = temp_salt
    factor = ${fparse rho_salt*cp_salt}
    block = salt
  []
  [h_conduction]
    type = LinearFVDiffusion
    variable = temp_salt
    diffusion_coeff = ${k_salt}
    use_nonorthogonal_correction = false
    block = salt
    coeff_interp_method = harm
  []

  [solid_time]
    type = LinearFVTimeDerivative
    variable = temp_solid
    factor = ${fparse rho_solid*cp_solid}
    block = solid
  []

  [solid_conduction]
    type = LinearFVDiffusion
    variable = temp_solid
    diffusion_coeff = ${k_solid}
    use_nonorthogonal_correction = false
    block = solid
    coeff_interp_method = harm
  []
[]

[FunctorMaterials]
  # [phase_change_enthalpy]
  #   type = INSFVPhaseChangeEnthalpyFunctorMaterial
  #   cp_solid = ${cp_salt}
  #   cp_liquid = ${cp_salt}
  #   L = ${L}
  #   T_solidus = ${T_solidus}
  #   T_liquidus = ${T_liquidus}
  #   temperature = ${T_solidus}
  #   enthalpy = h_salt
  #   block = salt
  # []
  # [k_eff]
  #   type = PiecewiseByBlockFunctorMaterial
  #   prop_name = 'k_eff'
  #   subdomain_to_prop_value = 'salt 0.6
  #                              solid 10.'
  # []
  # [rhocp_eff]
  #   type = PiecewiseByBlockFunctorMaterial
  #   prop_name = 'rhocp_eff'
  #   subdomain_to_prop_value = 'salt 4e6
  #                              solid 1.8e6'
  # []

  # [kappa_h_salt]
  #   type = ParsedFunctorMaterial
  #   property_name = kappa_h_salt
  #   functor_names = 'dTdh'
  #   functor_symbols = 'dTdh'
  #   expression = '${k_salt}*dTdh'
  #   block = salt
  # []

  # Converts the interface temperature on the solid side into
  # the enthalpy value needed by the fluid-side Dirichlet CHT BC
  # [interface_enthalpy]
  #   type = INSFVPhaseChangeEnthalpyFunctorMaterial
  #   h_from_p_T_name = interface_enthalpy_solid_interface
  #   T_from_p_h_name = T_from_p_h_interface
  #   liquid_fraction_name = liquid_fraction_interface
  #   dTdh_name = dTdh_interface
  #   cp_solid = ${cp_salt}
  #   cp_liquid = ${cp_salt}
  #   L = ${L}
  #   T_solidus = ${T_solidus}
  #   T_liquidus = ${T_liquidus}
  #   temperature = interface_temperature_solid_interface
  #   enthalpy = ${h_hot_salt}
  # []
[]

[LinearFVBCs]
  [solid_left]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    variable = temp_solid
    boundary = left
    functor = ${T_cold}
  []

  # [fluid_solid]
  #   type = LinearFVRobinCHTBC
  #   variable = temp_salt #h_salt
  #   boundary = interface
  #   h = ${h_s}
  #   thermal_conductivity = 0.6 #Thermal conductivity shouldnt matter, only flux
  #   incoming_flux = heat_flux_to_fluid_interface
  #   surface_temperature = interface_temperature_to_fluid_interface
  # []
  # [solid_fluid]
  #   type = LinearFVDirichletCHTBC
  #   variable = temp_solid
  #   boundary = interface
  #   functor = interface_temperature_to_solid_interface #temp_salt
  # []
  [fluid_solid]
    type = LinearFVRobinCHTBC
    variable = temp_salt
    boundary = interface
    h = 20
    thermal_conductivity = ${k_salt}
    incoming_flux = heat_flux_to_fluid_interface
    surface_temperature = interface_temperature_to_fluid_interface
  []

  [solid_fluid]
    type = LinearFVRobinCHTBC
    variable = temp_solid
    boundary = interface
    h = 20
    thermal_conductivity = ${k_solid}
    incoming_flux = heat_flux_to_solid_interface
    surface_temperature = interface_temperature_to_solid_interface
  []
  # no BC on the fluid right boundary
[]

[Executioner]
  type = PIMPLE

  dt = 1.
  end_time = 100
  num_iterations = 2
  continue_on_max_its = true
  print_fields = false

  energy_system = energy_system
  solid_energy_system = solid_energy_system

  rhie_chow_user_object = 'rc'
  momentum_systems = 'u_system'
  pressure_system = 'p_system'
  should_solve_momentum = false
  should_solve_pressure = false

  energy_l_abs_tol = 1e-18
  energy_l_tol = 1e-18
  solid_energy_l_abs_tol = 1e-18
  solid_energy_l_tol = 1e-18

  energy_absolute_tolerance = 1e-18
  solid_energy_absolute_tolerance = 1e-18

  energy_equation_relaxation = 0.85
  energy_field_relaxation = 0.85

  energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  energy_petsc_options_value = 'hypre boomeramg'
  solid_energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  solid_energy_petsc_options_value = 'hypre boomeramg'

  cht_interfaces = interface
  thermal_resistance = 0.01
  cht_solid_flux_relaxation = 0.9
  cht_fluid_flux_relaxation = 0.9
  cht_solid_temperature_relaxation = 0.9
  cht_fluid_temperature_relaxation = 0.9
  cht_heat_flux_tolerance = 1e-8
  max_cht_fpi = 100
[]

[Outputs]
  [out_test_Rth]
    type = Exodus
    #time_step_interval = 50
  []
[]
