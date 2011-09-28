   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !  Differentiation of sa_block in forward (tangent) mode:
   !   variations   of useful results: *rev *bvtj1 *bvtj2 *bmtk1 *w
   !                *bmtk2 *bvtk1 *bvtk2 *bmti1 *bmti2 *bvti1 *bvti2
   !                *bmtj1 *bmtj2
   !   with respect to varying inputs: *rev *bvtj1 *bvtj2 *bmtk1 *w
   !                *bmtk2 *rlv *bvtk1 *bvtk2 *d2wall *bmti1 *bmti2
   !                *bvti1 *bvti2 *bmtj1 *bmtj2 *(*bcdata.turbinlet)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          sa.f90                                          *
   !      * Author:        Georgi Kalitzin, Edwin van der Weide            *
   !      * Starting date: 06-11-2003                                      *
   !      * Last modified: 04-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE SA_BLOCK_D(resonly)
   USE BLOCKPOINTERS_D
   USE INPUTTIMESPECTRAL
   USE ITERATION
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * sa solves the transport equation for the Spalart-Allmaras      *
   !      * turbulence model in a segregated manner using a diagonal       *
   !      * dominant ADI-scheme.                                           *
   !      *                                                                *
   !      ******************************************************************
   !
   !
   !      Subroutine argument.
   !
   LOGICAL, INTENT(IN) :: resonly
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: nn, sps
   EXTERNAL SASOLVE_MOD
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Compute the time derivative for the time spectral mode.
   CALL UNSTEADYTURBSPECTRAL(itu1, itu1)
   ! Loop over the number of spectral modes and local blocks.
   ! Set the arrays for the boundary condition treatment.
   CALL BCTURBTREATMENT_D()
   ! Solve the transport equation for nuTilde.
   CALL SASOLVE_MOD(resonly)
   ! The eddy viscosity and the boundary conditions are only
   ! applied if an actual update has been computed in saSolve.
   IF (.NOT.resonly) THEN
   ! Compute the corresponding eddy viscosity.
   CALL SAEDDYVISCOSITY_D()
   ! Set the halo values for the turbulent variables.
   ! We are on the finest mesh, so the second layer of halo
   ! cells must be computed as well.
   CALL APPLYALLTURBBCTHISBLOCK_D(.true.)
   ! Write the loglaw for a flat plate boundary layer.
   ! call writeLoglaw
   bvtj1d = 0.0
   bvtj2d = 0.0
   bmtk1d = 0.0
   bmtk2d = 0.0
   bvtk1d = 0.0
   bvtk2d = 0.0
   bmti1d = 0.0
   bmti2d = 0.0
   bvti1d = 0.0
   bvti2d = 0.0
   bmtj1d = 0.0
   bmtj2d = 0.0
   ELSE
   revd = 0.0
   END IF
   END SUBROUTINE SA_BLOCK_D