#pragma once

// Including the "ADKernel" base class here so we can extend it
#include "ADKernel.h"

/**
 * Computes the residual contribution: K / mu * grad_test * grad_u.
 */
 class DarcyPressure : public ADKernel
 {
 public:
   static InputParameters validParams();

   DarcyPressure(const InputParameters & parameters);

 protected:
   /// ADKernel objects must override computeQpResidual
   virtual ADReal computeQpResidual() override;

   /// The variables which hold the value for K and mu
   const Real _permeability;
   const Real _viscosity;
 };
