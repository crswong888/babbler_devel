#include "DarcyVelocity.h"

#include "metaphysicl/raw_type.h"

registerMooseObject("BabblerApp", DarcyVelocity);

InputParameters
DarcyVelocity::validParams()
{
  InputParameters params = VectorAuxKernel::validParams();

  // Add a "coupling paramater" to get a variable from the input file.
  params.addRequiredCoupledVar("pressure", "The pressure field.");

  return params;
}

DarcyVelocity::DarcyVelocity(const InputParameters & parameters)
  : VectorAuxKernel(parameters),

    // Get the gradient of the variable
    _grad_p(coupledGradient("pressure")),

    // Set reference to the permeability MaterialProperty.
    // Only AuxKernels operating on Elemental Auxiliary Variables can do this
    _permeability(getADMaterialProperty<Real>("permeability")),

    // Set reference to the viscosity MaterialProperty.
    // Only AuxKernels operating on Elemental Auxiliary Variables can do this
    _viscosity(getADMaterialProperty<Real>("viscosity"))
{
}

RealVectorValue
DarcyVelocity::computeValue()
{
  // Access the gradient of the pressure at this quadrature point, then pull out the "component" of
  // it requested (x, y or z). Note, that getting a particular component of a gradient is done using
  // the parenthesis operator.

  /// note: QPs at {-1, 1} / sqrt(3) in natural coordinates of each element
  std::cout << std::setprecision(6)
            << "\n\nFor QP = ("
            << (_q_point[_qp])(0) << ", "
            << (_q_point[_qp])(1) << ", "
            << (_q_point[_qp])(2) << ")\n";

  std::cout << std::setprecision(std::numeric_limits<Real>::digits10)
            << "K = " << MetaPhysicL::raw_value(_permeability[_qp]) << "\n"
            << "mu = " << MetaPhysicL::raw_value(_viscosity[_qp]) << "\n"
            << "K / mu = " << MetaPhysicL::raw_value(_permeability[_qp] / _viscosity[_qp]) << "\n"
            << "grad_p" << _grad_p[_qp] << "\n"
            << "K / mu * grad_p"
            << MetaPhysicL::raw_value(_permeability[_qp] / _viscosity[_qp]) * _grad_p[_qp] << "\n";

  return -MetaPhysicL::raw_value(_permeability[_qp] / _viscosity[_qp]) * _grad_p[_qp];
}
