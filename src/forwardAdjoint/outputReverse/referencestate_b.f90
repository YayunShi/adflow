   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of referencestate in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: gammainf pinf timeref rhoinf
   !                muref tref muinf uinf rgas pref veldirfreestream
   !                machcoef
   !   with respect to varying inputs: pref mach tempfreestream veldirfreestream
   !                machcoef
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          referenceState.f90                              *
   !      * Author:        Edwin van der Weide, Seonghyeon Hahn            *
   !      * Starting date: 05-29-2003                                      *
   !      * Last modified: 04-22-2006                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE REFERENCESTATE_B()
   !
   !      ******************************************************************
   !      *                                                                *
   !      * referenceState computes the reference state values in case     *
   !      * these have not been specified. A distinction is made between   *
   !      * internal and external flows. In case nothing has been          *
   !      * specified for the former a dimensional computation will be     *
   !      * made. For the latter the reference state is set to an          *
   !      * arbitrary state for an inviscid computation and computed for a *
   !      * viscous computation. Furthermore for internal flows an average *
   !      * velocity direction is computed from the boundary conditions,   *
   !      * which is used for initialization.                              *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BCTYPES
   USE BLOCK
   USE COMMUNICATION
   USE CONSTANTS
   USE FLOWVARREFSTATE
   USE INPUTMOTION
   USE INPUTPHYSICS
   USE INPUTTIMESPECTRAL
   USE ITERATION
   IMPLICIT NONE
   !
   !      Local variables.
   !
   INTEGER :: ierr
   INTEGER(kind=inttype) :: sps, nn, mm
   REAL(kind=realtype) :: gm1, ratio, tmp
   REAL(kind=realtype) :: mx, my, mz, re, v, tinfdim
   REAL(kind=realtype) :: mxb, myb, mzb, vb, tinfdimb
   REAL(kind=realtype), DIMENSION(3) :: dirloc, dirglob
   REAL(kind=realtype), DIMENSION(5) :: valloc, valglob
   TYPE(BCDATATYPE), DIMENSION(:), POINTER :: bcdata
   INTERFACE 
   SUBROUTINE VELMAGNANDDIRECTIONSUBFACE(vmag, dir, bcdata, mm)
   USE BLOCK
   IMPLICIT NONE
   INTEGER(kind=inttype), INTENT(IN) :: mm
   REAL(kind=realtype), INTENT(OUT) :: vmag
   REAL(kind=realtype), DIMENSION(3), INTENT(INOUT) :: dir
   TYPE(BCDATATYPE), DIMENSION(:), POINTER :: bcdata
   END SUBROUTINE VELMAGNANDDIRECTIONSUBFACE
   END INTERFACE
      INTRINSIC SQRT
   INTEGER :: branch
   REAL(kind=realtype) :: temp1
   REAL(kind=realtype) :: temp0
   REAL(kind=realtype) :: tempb8
   REAL(kind=realtype) :: tempb7
   REAL(kind=realtype) :: tempb6
   REAL(kind=realtype) :: tempb5
   REAL(kind=realtype) :: tempb4
   REAL(kind=realtype) :: tempb3
   REAL(kind=realtype) :: tempb2
   REAL(kind=realtype) :: tempb1
   REAL(kind=realtype) :: tempb0
   REAL(kind=realtype) :: tempb
   REAL(kind=realtype) :: temp
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Initialize the dimensional free stream temperature and pressure.
   ! From these values the density and viscosity is computed. For
   ! external viscous and internal computation this is corrected
   ! later on.
   pinfdim = pref
   IF (pref .LE. zero) THEN
   pinfdim = 101325.0_realType
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   tinfdim = tempfreestream
   rhoinfdim = pinfdim/(rgasdim*tinfdim)
   mudim = musuthdim*((tsuthdim+ssuthdim)/(tinfdim+ssuthdim))*(tinfdim/&
   &   tsuthdim)**1.5_realType
   ! Check the flow type we are having here.
   IF (flowtype .EQ. internalflow) THEN
   CALL PUSHCONTROL2B(0)
   ELSE
   ! External flow. Compute the value of gammaInf.
   CALL COMPUTEGAMMA(tempfreestream, gammainf, 1)
   ! In case of a viscous problem, compute the
   ! dimensional free stream density and pressure.
   IF (equations .EQ. nsequations .OR. equations .EQ. ransequations) &
   &   THEN
   ! Compute the x, y, and z-components of the Mach number
   ! relative to the body; i.e. the mesh velocity must be
   ! taken into account here.
   mx = machcoef*veldirfreestream(1)
   my = machcoef*veldirfreestream(2)
   mz = machcoef*veldirfreestream(3)
   ! Reynolds number per meter, the viscosity using sutherland's
   ! law and the free stream velocity relative to the body.
   re = reynolds/reynoldslength
   mudim = musuthdim*((tsuthdim+ssuthdim)/(tempfreestream+ssuthdim))*&
   &       (tempfreestream/tsuthdim)**1.5
   v = SQRT((mx*mx+my*my+mz*mz)*gammainf*rgasdim*tempfreestream)
   ! Compute the free stream density and pressure.
   ! Set TInfDim to tempFreestream.
   rhoinfdim = re*mudim/v
   CALL PUSHREAL8(pinfdim)
   pinfdim = rhoinfdim*rgasdim*tempfreestream
   tinfdim = tempfreestream
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   ! In case the reference pressure, density and temperature were
   ! not specified, set them to the infinity values.
   IF (pref .LE. zero) THEN
   pref = pinfdim
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   IF (rhoref .LE. zero) THEN
   rhoref = rhoinfdim
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   IF (tref .LE. zero) THEN
   tref = tinfdim
   CALL PUSHCONTROL2B(1)
   ELSE
   CALL PUSHCONTROL2B(2)
   END IF
   END IF
   ! Compute the value of muRef, such that the nonDimensional
   ! equations are identical to the dimensional ones.
   ! Note that in the non-dimensionalization of muRef there is
   ! a reference length. However this reference length is 1.0
   ! in this code, because the coordinates are converted to
   ! meters.
   muref = SQRT(pref*rhoref)
   ! Compute timeRef for a correct nonDimensionalization of the
   ! unsteady equations. Some story as for the reference viscosity
   ! concerning the reference length.
   ! Compute the nonDimensional pressure, density, velocity,
   ! viscosity and gas constant.
   pinf = pinfdim/pref
   rhoinf = rhoinfdim/rhoref
   mudimb = muinfb/muref
   murefb = murefb - mudim*muinfb/muref**2
   tempb5 = rgasdim*rgasb/pref
   trefb = trefb + rhoref*tempb5
   temp0 = gammainf*pinf/rhoinf
   temp1 = SQRT(temp0)
   IF (temp0 .EQ. 0.0_8) THEN
   tempb8 = 0.0
   ELSE
   tempb8 = mach*uinfb/(2.0*temp1*rhoinf)
   END IF
   machb = temp1*uinfb
   gammainfb = gammainfb + pinf*tempb8
   pinfb = pinfb + gammainf*tempb8
   rhoinfb = rhoinfb - temp0*tempb8
   rhoinfdimb = rhoinfb/rhoref
   pinfdimb = pinfb/pref
   IF (rhoref/pref .EQ. 0.0_8) THEN
   tempb7 = 0.0
   ELSE
   tempb7 = timerefb/(2.0*SQRT(rhoref/pref)*pref)
   END IF
   IF (pref*rhoref .EQ. 0.0_8) THEN
   tempb6 = 0.0
   ELSE
   tempb6 = murefb/(2.0*SQRT(pref*rhoref))
   END IF
   rhorefb = pref*tempb6 - rhoinfdim*rhoinfb/rhoref**2 + tempb7 + tref*&
   &   tempb5
   prefb = prefb + rhoref*tempb6 - pinfdim*pinfb/pref**2 - rhoref*tempb7/&
   &   pref - rhoref*tref*tempb5/pref
   CALL POPCONTROL2B(branch)
   IF (branch .EQ. 0) THEN
   tempfreestreamb = 0.0_8
   tinfdimb = 0.0_8
   ELSE
   IF (branch .EQ. 1) THEN
   tinfdimb = trefb
   ELSE
   tinfdimb = 0.0_8
   END IF
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) rhoinfdimb = rhoinfdimb + rhorefb
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   pinfdimb = pinfdimb + prefb
   prefb = 0.0_8
   END IF
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   rhoinfdimb = rhoinfdimb + rgasdim*tempfreestream*pinfdimb
   tempb3 = re*rhoinfdimb/v
   mudimb = mudimb + tempb3
   vb = -(mudim*tempb3/v)
   temp = mx**2 + my**2 + mz**2
   IF (rgasdim*(temp*(gammainf*tempfreestream)) .EQ. 0.0_8) THEN
   tempb2 = 0.0
   ELSE
   tempb2 = rgasdim*vb/(2.0*SQRT(rgasdim*(temp*(gammainf*&
   &         tempfreestream))))
   END IF
   tempb1 = musuthdim*(tsuthdim+ssuthdim)*mudimb/(ssuthdim+&
   &       tempfreestream)
   tempfreestreamb = rgasdim*rhoinfdim*pinfdimb + (1.5*(&
   &       tempfreestream/tsuthdim)**0.5/tsuthdim-(tempfreestream/tsuthdim)&
   &       **1.5/(ssuthdim+tempfreestream))*tempb1 + temp*gammainf*tempb2 +&
   &       tinfdimb
   CALL POPREAL8(pinfdim)
   tinfdim = tempfreestream
   tempb4 = gammainf*tempfreestream*tempb2
   mxb = 2*mx*tempb4
   myb = 2*my*tempb4
   mzb = 2*mz*tempb4
   gammainfb = gammainfb + temp*tempfreestream*tempb2
   machcoefb = machcoefb + veldirfreestream(2)*myb + veldirfreestream&
   &       (1)*mxb + veldirfreestream(3)*mzb
   veldirfreestreamb(3) = veldirfreestreamb(3) + machcoef*mzb
   veldirfreestreamb(2) = veldirfreestreamb(2) + machcoef*myb
   veldirfreestreamb(1) = veldirfreestreamb(1) + machcoef*mxb
   mudimb = 0.0_8
   rhoinfdimb = 0.0_8
   pinfdimb = 0.0_8
   tinfdimb = 0.0_8
   ELSE
   tempfreestreamb = 0.0_8
   END IF
   CALL COMPUTEGAMMA_B(tempfreestream, tempfreestreamb, gammainf, &
   &                 gammainfb, 1)
   END IF
   tempb0 = rhoinfdimb/(rgasdim*tinfdim)
   tempb = musuthdim*(tsuthdim+ssuthdim)*mudimb/(ssuthdim+tinfdim)
   tinfdimb = tinfdimb + (1.5_realType*(tinfdim/tsuthdim)**0.5/tsuthdim-(&
   &   tinfdim/tsuthdim)**1.5_realType/(ssuthdim+tinfdim))*tempb - pinfdim*&
   &   tempb0/tinfdim
   pinfdimb = pinfdimb + tempb0
   tempfreestreamb = tempfreestreamb + tinfdimb
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) pinfdimb = 0.0_8
   prefb = prefb + pinfdimb
      CONTAINS
   !=================================================================
   !===============================================================
   FUNCTION MAXVALUESUBFACE(var)
   IMPLICIT NONE
   !
   !        Function type
   !
   REAL(kind=realtype) :: maxvaluesubface
   !
   !        Function argument.
   !
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: var
   !
   !        Local variables.
   !
   INTEGER(kind=inttype) :: i, j
   INTRINSIC ASSOCIATED
   INTRINSIC MAX
   !
   !        ****************************************************************
   !        *                                                              *
   !        * Begin execution                                              *
   !        *                                                              *
   !        ****************************************************************
   !
   ! Initialize the function to -1 and return immediately if
   ! var is not associated with data.
   maxvaluesubface = -one
   IF (.NOT.ASSOCIATED(var)) THEN
   RETURN
   ELSE
   ! Loop over the owned faces of the subface. As the cell range
   ! may contain halo values, the nodal range is used.
   DO j=bcdata(mm)%jnbeg+1,bcdata(mm)%jnend
   DO i=bcdata(mm)%inbeg+1,bcdata(mm)%inend
   IF (maxvaluesubface .LT. var(i, j)) THEN
   maxvaluesubface = var(i, j)
   ELSE
   maxvaluesubface = maxvaluesubface
   END IF
   END DO
   END DO
   END IF
   END FUNCTION MAXVALUESUBFACE
   END SUBROUTINE REFERENCESTATE_B