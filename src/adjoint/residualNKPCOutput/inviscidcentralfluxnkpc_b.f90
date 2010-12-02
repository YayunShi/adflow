   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !  Differentiation of inviscidcentralfluxnkpc in reverse (adjoint) mode:
   !   gradient     of useful results: padj dwadj wadj
   !   with respect to varying inputs: padj dwadj wadj
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          inviscidCentralFluxAdj.f90                      *
   !      * Author:        Edwin van der Weide, C.A.(Sandy) Mader          *
   !      *                Seongim Choi                                    *
   !      * Starting date: 11-21-2007                                      *
   !      * Last modified: 10-22-2008                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE INVISCIDCENTRALFLUXNKPC_B(wadj, wadjb, padj, padjb, dwadj, &
   &  dwadjb, siadj, sjadj, skadj, voladj, sfaceiadj, sfacejadj, sfacekadj, &
   &  rotrateadj, icell, jcell, kcell, nn, level, sps)
   USE CGNSGRID
   USE BLOCKPOINTERS
   USE INPUTTIMESPECTRAL
   USE INPUTPHYSICS
   USE FLOWVARREFSTATE
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * inviscidCentralFluxAdj computes the Euler fluxes using a       *
   !      * central discretization for the cell iCell, jCell, kCell of the *
   !      * block to which the variables in blockPointers currently point  *
   !      * to.                                                            *
   !      *                                                                *
   !      ******************************************************************
   !
   ! sFaceI,sFaceJ,sFaceK,sI,sJ,sK,blockismoving,addgridvelocities
   ! vol, nbkGlobal
   ! constants (irho, ivx, ivy, imx,..), timeRef
   ! equationMode, steady
   !
   !nTimeIntervalsSpectral
   !
   !      Subroutine arguments
   !
   INTEGER(kind=inttype) :: icell, jcell, kcell, nn, level, sps
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, nw, &
   &  ntimeintervalsspectral), INTENT(IN) :: wadj
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, nw, &
   &  ntimeintervalsspectral) :: wadjb
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: padj
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral) :: padjb
   REAL(kind=realtype), DIMENSION(nw, ntimeintervalsspectral), INTENT(&
   &  INOUT) :: dwadj
   REAL(kind=realtype), DIMENSION(nw, ntimeintervalsspectral) :: dwadjb
   REAL(kind=realtype), DIMENSION(-3:2, -3:2, -3:2, 3, &
   &  ntimeintervalsspectral), INTENT(IN) :: siadj, sjadj, skadj
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: sfaceiadj, sfacejadj, sfacekadj
   REAL(kind=realtype), DIMENSION(0:0, 0:0, 0:0, ntimeintervalsspectral),&
   &  INTENT(IN) :: voladj
   REAL(kind=realtype), DIMENSION(3), INTENT(IN) :: rotrateadj
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: i, j, k, ii, jj, kk
   REAL(kind=realtype) :: qsp, qsm, rqsp, rqsm, porvel, porflux
   REAL(kind=realtype) :: qspb, qsmb, rqspb, rqsmb
   REAL(kind=realtype) :: pa, fs, sface, vnp, vnm, fact
   REAL(kind=realtype) :: pab, fsb, vnpb, vnmb
   REAL(kind=realtype) :: wx, wy, wz, rvol
   REAL(kind=realtype) :: rvolb
   !     testing vars
   REAL(kind=realtype) :: wx2, wy2, wz2, rvol2
   INTEGER :: branch
   REAL(kind=realtype) :: tempb1
   REAL(kind=realtype) :: tempb0
   REAL(kind=realtype) :: tempb
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Initialize sFace to zero. This value will be used if the
   ! block is not moving.
   sface = 0.0
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advective fluxes in the i-direction.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   i = icell - 1
   j = jcell
   k = kcell
   fact = -one
   ! Loop over the two faces which contribute to the residual of
   ! the cell considered.
   DO ii=-1,0
   ! Set the dot product of the grid velocity and the
   ! normal in i-direction for a moving face.
   IF (addgridvelocities) sface = sfaceiadj(ii, 0, 0, sps)
   CALL PUSHREAL8ARRAY(vnp, realtype/8)
   ! Compute the normal velocities of the left and right state.
   vnp = wadj(ii+1, 0, 0, ivx, sps)*siadj(ii, 0, 0, 1, sps) + wadj(ii+1&
   &      , 0, 0, ivy, sps)*siadj(ii, 0, 0, 2, sps) + wadj(ii+1, 0, 0, ivz, &
   &      sps)*siadj(ii, 0, 0, 3, sps)
   CALL PUSHREAL8ARRAY(vnm, realtype/8)
   vnm = wadj(ii, 0, 0, ivx, sps)*siadj(ii, 0, 0, 1, sps) + wadj(ii, 0&
   &      , 0, ivy, sps)*siadj(ii, 0, 0, 2, sps) + wadj(ii, 0, 0, ivz, sps)*&
   &      siadj(ii, 0, 0, 3, sps)
   CALL PUSHREAL8ARRAY(porvel, realtype/8)
   !print *,'vnp',wAdj(ii+1,0,0,ivx,sps),sIAdj(ii,0,0,1,sps),sps
   ! Set the values of the porosities for this face.
   ! porVel defines the porosity w.r.t. velocity;
   ! porFlux defines the porosity w.r.t. the entire flux.
   ! The latter is only zero for a discontinuous block
   ! boundary that must be treated conservatively.
   ! The default value of porFlux is 0.5, such that the
   ! correct central flux is scattered to both cells.
   ! In case of a boundFlux the normal velocity is set
   ! to sFace.
   porvel = one
   CALL PUSHREAL8ARRAY(porflux, realtype/8)
   porflux = half
   IF (pori(i, j, k) .EQ. noflux) porflux = 0.0
   IF (pori(i, j, k) .EQ. boundflux) THEN
   porvel = 0.0
   vnp = sface
   vnm = sface
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   ! Incorporate porFlux in porVel.
   porvel = porvel*porflux
   CALL PUSHREAL8ARRAY(qsp, realtype/8)
   ! Compute the normal velocities relative to the grid for
   ! the face as well as the mass fluxes.
   qsp = (vnp-sface)*porvel
   CALL PUSHREAL8ARRAY(qsm, realtype/8)
   qsm = (vnm-sface)*porvel
   ! Compute the sum of the pressure multiplied by porFlux.
   ! For the default value of porFlux, 0.5, this leads to
   ! the average pressure.
   ! Compute the fluxes through this face.
   ! Update i and set fact to 1 for the second face.
   i = i + 1
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = one
   END DO
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advective fluxes in the j-direction.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   i = icell
   j = jcell - 1
   k = kcell
   fact = -one
   ! Loop over the two faces which contribute to the residual of
   ! the cell considered.
   DO jj=-1,0
   ! Set the dot product of the grid velocity and the
   ! normal in j-direction for a moving face.
   IF (addgridvelocities) sface = sfacejadj(0, jj, 0, sps)
   CALL PUSHREAL8ARRAY(vnp, realtype/8)
   ! Compute the normal velocities of the left and right state.
   vnp = wadj(0, jj+1, 0, ivx, sps)*sjadj(0, jj, 0, 1, sps) + wadj(0, &
   &      jj+1, 0, ivy, sps)*sjadj(0, jj, 0, 2, sps) + wadj(0, jj+1, 0, ivz&
   &      , sps)*sjadj(0, jj, 0, 3, sps)
   CALL PUSHREAL8ARRAY(vnm, realtype/8)
   vnm = wadj(0, jj, 0, ivx, sps)*sjadj(0, jj, 0, 1, sps) + wadj(0, jj&
   &      , 0, ivy, sps)*sjadj(0, jj, 0, 2, sps) + wadj(0, jj, 0, ivz, sps)*&
   &      sjadj(0, jj, 0, 3, sps)
   CALL PUSHREAL8ARRAY(porvel, realtype/8)
   ! Set the values of the porosities for this face.
   ! porVel defines the porosity w.r.t. velocity;
   ! porFlux defines the porosity w.r.t. the entire flux.
   ! The latter is only zero for a discontinuous block
   ! boundary that must be treated conservatively.
   ! The default value of porFlux is 0.5, such that the
   ! correct central flux is scattered to both cells.
   ! In case of a boundFlux the normal velocity is set
   ! to sFace.
   porvel = one
   CALL PUSHREAL8ARRAY(porflux, realtype/8)
   porflux = half
   IF (porj(i, j, k) .EQ. noflux) porflux = 0.0
   IF (porj(i, j, k) .EQ. boundflux) THEN
   porvel = 0.0
   vnp = sface
   vnm = sface
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   ! Incorporate porFlux in porVel.
   porvel = porvel*porflux
   CALL PUSHREAL8ARRAY(qsp, realtype/8)
   ! Compute the normal velocities relative to the grid for
   ! the face as well as the mass fluxes.
   qsp = (vnp-sface)*porvel
   CALL PUSHREAL8ARRAY(qsm, realtype/8)
   qsm = (vnm-sface)*porvel
   ! Compute the sum of the pressure multiplied by porFlux.
   ! For the default value of porFlux, 0.5, this leads to
   ! the average pressure.
   ! Compute the fluxes through this face.
   ! Update j and set fact to 1 for the second face.
   j = j + 1
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = one
   END DO
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Advective fluxes in the k-direction.                           *
   !      *                                                                *
   !      ******************************************************************
   !
   !       should this be inside, have k=kCell+kk?
   i = icell
   j = jcell
   k = kcell - 1
   fact = -one
   ! Loop over the two faces which contribute to the residual of
   ! the cell considered.
   DO kk=-1,0
   ! Set the dot product of the grid velocity and the
   ! normal in k-direction for a moving face.
   IF (addgridvelocities) sface = sfacekadj(0, 0, kk, sps)
   CALL PUSHREAL8ARRAY(vnp, realtype/8)
   ! Compute the normal velocities of the left and right state.
   vnp = wadj(0, 0, kk+1, ivx, sps)*skadj(0, 0, kk, 1, sps) + wadj(0, 0&
   &      , kk+1, ivy, sps)*skadj(0, 0, kk, 2, sps) + wadj(0, 0, kk+1, ivz, &
   &      sps)*skadj(0, 0, kk, 3, sps)
   CALL PUSHREAL8ARRAY(vnm, realtype/8)
   vnm = wadj(0, 0, kk, ivx, sps)*skadj(0, 0, kk, 1, sps) + wadj(0, 0, &
   &      kk, ivy, sps)*skadj(0, 0, kk, 2, sps) + wadj(0, 0, kk, ivz, sps)*&
   &      skadj(0, 0, kk, 3, sps)
   CALL PUSHREAL8ARRAY(porvel, realtype/8)
   ! Set the values of the porosities for this face.
   ! porVel defines the porosity w.r.t. velocity;
   ! porFlux defines the porosity w.r.t. the entire flux.
   ! The latter is only zero for a discontinuous block
   ! boundary that must be treated conservatively.
   ! The default value of porFlux is 0.5, such that the
   ! correct central flux is scattered to both cells.
   ! In case of a boundFlux the normal velocity is set
   ! to sFace.
   porvel = one
   CALL PUSHREAL8ARRAY(porflux, realtype/8)
   porflux = half
   IF (pork(i, j, k) .EQ. noflux) porflux = 0.0
   IF (pork(i, j, k) .EQ. boundflux) THEN
   porvel = 0.0
   vnp = sface
   vnm = sface
   CALL PUSHINTEGER4(1)
   ELSE
   CALL PUSHINTEGER4(0)
   END IF
   ! Incorporate porFlux in porVel.
   porvel = porvel*porflux
   CALL PUSHREAL8ARRAY(qsp, realtype/8)
   ! Compute the normal velocities relative to the grid for
   ! the face as well as the mass fluxes.
   qsp = (vnp-sface)*porvel
   CALL PUSHREAL8ARRAY(qsm, realtype/8)
   qsm = (vnm-sface)*porvel
   ! Compute the sum of the pressure multiplied by porFlux.
   ! For the default value of porFlux, 0.5, this leads to
   ! the average pressure.
   ! Compute the fluxes through this face.
   ! Update k and set fact to 1 for the second face.
   k = k + 1
   CALL PUSHREAL8ARRAY(fact, realtype/8)
   fact = one
   END DO
   ! Add the rotational source terms for a moving block in a
   ! steady state computation. These source terms account for the
   ! centrifugal acceleration and the coriolis term. However, as
   ! the equations are solved in the inertial frame and not
   ! in the moving frame, the form is different than what you
   ! normally find in a text book.
   IF (blockismoving .AND. equationmode .EQ. steady) THEN
   !          wx = timeRef*rotRateAdj(1)
   !          wy = timeRef*rotRateAdj(2)
   !          wz = timeRef*rotRateAdj(3)
   !timeref is taken into account in copyAdjointStencil...
   wx = rotrateadj(1)
   wy = rotrateadj(2)
   wz = rotrateadj(3)
   rvol = wadj(0, 0, 0, irho, sps)*voladj(0, 0, 0, sps)
   rvolb = (wz*wadj(0, 0, 0, ivx, sps)-wx*wadj(0, 0, 0, ivz, sps))*&
   &      dwadjb(imy, sps) + (wy*wadj(0, 0, 0, ivz, sps)-wz*wadj(0, 0, 0, &
   &      ivy, sps))*dwadjb(imx, sps) + (wx*wadj(0, 0, 0, ivy, sps)-wy*wadj(&
   &      0, 0, 0, ivx, sps))*dwadjb(imz, sps)
   wadjb(0, 0, 0, ivy, sps) = wadjb(0, 0, 0, ivy, sps) + rvol*wx*dwadjb&
   &      (imz, sps)
   wadjb(0, 0, 0, ivx, sps) = wadjb(0, 0, 0, ivx, sps) + rvol*wz*dwadjb&
   &      (imy, sps) - rvol*wy*dwadjb(imz, sps)
   wadjb(0, 0, 0, ivz, sps) = wadjb(0, 0, 0, ivz, sps) + rvol*wy*dwadjb&
   &      (imx, sps) - rvol*wx*dwadjb(imy, sps)
   wadjb(0, 0, 0, ivy, sps) = wadjb(0, 0, 0, ivy, sps) - rvol*wz*dwadjb&
   &      (imx, sps)
   wadjb(0, 0, 0, irho, sps) = wadjb(0, 0, 0, irho, sps) + voladj(0, 0&
   &      , 0, sps)*rvolb
   END IF
   DO kk=0,-1,-1
   CALL POPREAL8ARRAY(fact, realtype/8)
   fsb = fact*dwadjb(irhoe, sps)
   tempb1 = porflux*fsb
   qspb = wadj(0, 0, kk+1, irhoe, sps)*fsb
   wadjb(0, 0, kk+1, irhoe, sps) = wadjb(0, 0, kk+1, irhoe, sps) + qsp*&
   &      fsb
   qsmb = wadj(0, 0, kk, irhoe, sps)*fsb
   wadjb(0, 0, kk, irhoe, sps) = wadjb(0, 0, kk, irhoe, sps) + qsm*fsb
   fsb = fact*dwadjb(imz, sps)
   rqsm = qsm*wadj(0, 0, kk, irho, sps)
   rqsp = qsp*wadj(0, 0, kk+1, irho, sps)
   rqspb = wadj(0, 0, kk+1, ivz, sps)*fsb
   wadjb(0, 0, kk+1, ivz, sps) = wadjb(0, 0, kk+1, ivz, sps) + rqsp*fsb
   rqsmb = wadj(0, 0, kk, ivz, sps)*fsb
   wadjb(0, 0, kk, ivz, sps) = wadjb(0, 0, kk, ivz, sps) + rqsm*fsb
   pab = skadj(0, 0, kk, 3, sps)*fsb
   fsb = fact*dwadjb(imy, sps)
   rqspb = rqspb + wadj(0, 0, kk+1, ivy, sps)*fsb
   wadjb(0, 0, kk+1, ivy, sps) = wadjb(0, 0, kk+1, ivy, sps) + rqsp*fsb
   rqsmb = rqsmb + wadj(0, 0, kk, ivy, sps)*fsb
   wadjb(0, 0, kk, ivy, sps) = wadjb(0, 0, kk, ivy, sps) + rqsm*fsb
   pab = pab + skadj(0, 0, kk, 2, sps)*fsb
   fsb = fact*dwadjb(imx, sps)
   rqspb = rqspb + wadj(0, 0, kk+1, ivx, sps)*fsb
   wadjb(0, 0, kk+1, ivx, sps) = wadjb(0, 0, kk+1, ivx, sps) + rqsp*fsb
   rqsmb = rqsmb + wadj(0, 0, kk, ivx, sps)*fsb
   wadjb(0, 0, kk, ivx, sps) = wadjb(0, 0, kk, ivx, sps) + rqsm*fsb
   pab = pab + skadj(0, 0, kk, 1, sps)*fsb
   fsb = fact*dwadjb(irho, sps)
   rqspb = rqspb + fsb
   qspb = qspb + wadj(0, 0, kk+1, irho, sps)*rqspb
   vnpb = porvel*qspb + padj(0, 0, kk+1, sps)*tempb1
   padjb(0, 0, kk+1, sps) = padjb(0, 0, kk+1, sps) + vnp*tempb1
   rqsmb = rqsmb + fsb
   qsmb = qsmb + wadj(0, 0, kk, irho, sps)*rqsmb
   vnmb = porvel*qsmb + padj(0, 0, kk, sps)*tempb1
   padjb(0, 0, kk, sps) = padjb(0, 0, kk, sps) + vnm*tempb1
   padjb(0, 0, kk+1, sps) = padjb(0, 0, kk+1, sps) + porflux*pab
   padjb(0, 0, kk, sps) = padjb(0, 0, kk, sps) + porflux*pab
   wadjb(0, 0, kk, irho, sps) = wadjb(0, 0, kk, irho, sps) + qsm*rqsmb
   wadjb(0, 0, kk+1, irho, sps) = wadjb(0, 0, kk+1, irho, sps) + qsp*&
   &      rqspb
   CALL POPREAL8ARRAY(qsm, realtype/8)
   CALL POPREAL8ARRAY(qsp, realtype/8)
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 1) THEN
   vnmb = 0.0
   vnpb = 0.0
   END IF
   CALL POPREAL8ARRAY(porflux, realtype/8)
   CALL POPREAL8ARRAY(porvel, realtype/8)
   CALL POPREAL8ARRAY(vnm, realtype/8)
   wadjb(0, 0, kk, ivx, sps) = wadjb(0, 0, kk, ivx, sps) + skadj(0, 0, &
   &      kk, 1, sps)*vnmb
   wadjb(0, 0, kk, ivy, sps) = wadjb(0, 0, kk, ivy, sps) + skadj(0, 0, &
   &      kk, 2, sps)*vnmb
   wadjb(0, 0, kk, ivz, sps) = wadjb(0, 0, kk, ivz, sps) + skadj(0, 0, &
   &      kk, 3, sps)*vnmb
   CALL POPREAL8ARRAY(vnp, realtype/8)
   wadjb(0, 0, kk+1, ivx, sps) = wadjb(0, 0, kk+1, ivx, sps) + skadj(0&
   &      , 0, kk, 1, sps)*vnpb
   wadjb(0, 0, kk+1, ivy, sps) = wadjb(0, 0, kk+1, ivy, sps) + skadj(0&
   &      , 0, kk, 2, sps)*vnpb
   wadjb(0, 0, kk+1, ivz, sps) = wadjb(0, 0, kk+1, ivz, sps) + skadj(0&
   &      , 0, kk, 3, sps)*vnpb
   END DO
   DO jj=0,-1,-1
   CALL POPREAL8ARRAY(fact, realtype/8)
   fsb = fact*dwadjb(irhoe, sps)
   tempb0 = porflux*fsb
   qspb = wadj(0, jj+1, 0, irhoe, sps)*fsb
   wadjb(0, jj+1, 0, irhoe, sps) = wadjb(0, jj+1, 0, irhoe, sps) + qsp*&
   &      fsb
   qsmb = wadj(0, jj, 0, irhoe, sps)*fsb
   wadjb(0, jj, 0, irhoe, sps) = wadjb(0, jj, 0, irhoe, sps) + qsm*fsb
   fsb = fact*dwadjb(imz, sps)
   rqsm = qsm*wadj(0, jj, 0, irho, sps)
   rqsp = qsp*wadj(0, jj+1, 0, irho, sps)
   rqspb = wadj(0, jj+1, 0, ivz, sps)*fsb
   wadjb(0, jj+1, 0, ivz, sps) = wadjb(0, jj+1, 0, ivz, sps) + rqsp*fsb
   rqsmb = wadj(0, jj, 0, ivz, sps)*fsb
   wadjb(0, jj, 0, ivz, sps) = wadjb(0, jj, 0, ivz, sps) + rqsm*fsb
   pab = sjadj(0, jj, 0, 3, sps)*fsb
   fsb = fact*dwadjb(imy, sps)
   rqspb = rqspb + wadj(0, jj+1, 0, ivy, sps)*fsb
   wadjb(0, jj+1, 0, ivy, sps) = wadjb(0, jj+1, 0, ivy, sps) + rqsp*fsb
   rqsmb = rqsmb + wadj(0, jj, 0, ivy, sps)*fsb
   wadjb(0, jj, 0, ivy, sps) = wadjb(0, jj, 0, ivy, sps) + rqsm*fsb
   pab = pab + sjadj(0, jj, 0, 2, sps)*fsb
   fsb = fact*dwadjb(imx, sps)
   rqspb = rqspb + wadj(0, jj+1, 0, ivx, sps)*fsb
   wadjb(0, jj+1, 0, ivx, sps) = wadjb(0, jj+1, 0, ivx, sps) + rqsp*fsb
   rqsmb = rqsmb + wadj(0, jj, 0, ivx, sps)*fsb
   wadjb(0, jj, 0, ivx, sps) = wadjb(0, jj, 0, ivx, sps) + rqsm*fsb
   pab = pab + sjadj(0, jj, 0, 1, sps)*fsb
   fsb = fact*dwadjb(irho, sps)
   rqspb = rqspb + fsb
   qspb = qspb + wadj(0, jj+1, 0, irho, sps)*rqspb
   vnpb = porvel*qspb + padj(0, jj+1, 0, sps)*tempb0
   padjb(0, jj+1, 0, sps) = padjb(0, jj+1, 0, sps) + vnp*tempb0
   rqsmb = rqsmb + fsb
   qsmb = qsmb + wadj(0, jj, 0, irho, sps)*rqsmb
   vnmb = porvel*qsmb + padj(0, jj, 0, sps)*tempb0
   padjb(0, jj, 0, sps) = padjb(0, jj, 0, sps) + vnm*tempb0
   padjb(0, jj+1, 0, sps) = padjb(0, jj+1, 0, sps) + porflux*pab
   padjb(0, jj, 0, sps) = padjb(0, jj, 0, sps) + porflux*pab
   wadjb(0, jj, 0, irho, sps) = wadjb(0, jj, 0, irho, sps) + qsm*rqsmb
   wadjb(0, jj+1, 0, irho, sps) = wadjb(0, jj+1, 0, irho, sps) + qsp*&
   &      rqspb
   CALL POPREAL8ARRAY(qsm, realtype/8)
   CALL POPREAL8ARRAY(qsp, realtype/8)
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 1) THEN
   vnmb = 0.0
   vnpb = 0.0
   END IF
   CALL POPREAL8ARRAY(porflux, realtype/8)
   CALL POPREAL8ARRAY(porvel, realtype/8)
   CALL POPREAL8ARRAY(vnm, realtype/8)
   wadjb(0, jj, 0, ivx, sps) = wadjb(0, jj, 0, ivx, sps) + sjadj(0, jj&
   &      , 0, 1, sps)*vnmb
   wadjb(0, jj, 0, ivy, sps) = wadjb(0, jj, 0, ivy, sps) + sjadj(0, jj&
   &      , 0, 2, sps)*vnmb
   wadjb(0, jj, 0, ivz, sps) = wadjb(0, jj, 0, ivz, sps) + sjadj(0, jj&
   &      , 0, 3, sps)*vnmb
   CALL POPREAL8ARRAY(vnp, realtype/8)
   wadjb(0, jj+1, 0, ivx, sps) = wadjb(0, jj+1, 0, ivx, sps) + sjadj(0&
   &      , jj, 0, 1, sps)*vnpb
   wadjb(0, jj+1, 0, ivy, sps) = wadjb(0, jj+1, 0, ivy, sps) + sjadj(0&
   &      , jj, 0, 2, sps)*vnpb
   wadjb(0, jj+1, 0, ivz, sps) = wadjb(0, jj+1, 0, ivz, sps) + sjadj(0&
   &      , jj, 0, 3, sps)*vnpb
   END DO
   DO ii=0,-1,-1
   CALL POPREAL8ARRAY(fact, realtype/8)
   fsb = fact*dwadjb(irhoe, sps)
   tempb = porflux*fsb
   qspb = wadj(ii+1, 0, 0, irhoe, sps)*fsb
   wadjb(ii+1, 0, 0, irhoe, sps) = wadjb(ii+1, 0, 0, irhoe, sps) + qsp*&
   &      fsb
   qsmb = wadj(ii, 0, 0, irhoe, sps)*fsb
   wadjb(ii, 0, 0, irhoe, sps) = wadjb(ii, 0, 0, irhoe, sps) + qsm*fsb
   fsb = fact*dwadjb(imz, sps)
   rqsm = qsm*wadj(ii, 0, 0, irho, sps)
   rqsp = qsp*wadj(ii+1, 0, 0, irho, sps)
   rqspb = wadj(ii+1, 0, 0, ivz, sps)*fsb
   wadjb(ii+1, 0, 0, ivz, sps) = wadjb(ii+1, 0, 0, ivz, sps) + rqsp*fsb
   rqsmb = wadj(ii, 0, 0, ivz, sps)*fsb
   wadjb(ii, 0, 0, ivz, sps) = wadjb(ii, 0, 0, ivz, sps) + rqsm*fsb
   pab = siadj(ii, 0, 0, 3, sps)*fsb
   fsb = fact*dwadjb(imy, sps)
   rqspb = rqspb + wadj(ii+1, 0, 0, ivy, sps)*fsb
   wadjb(ii+1, 0, 0, ivy, sps) = wadjb(ii+1, 0, 0, ivy, sps) + rqsp*fsb
   rqsmb = rqsmb + wadj(ii, 0, 0, ivy, sps)*fsb
   wadjb(ii, 0, 0, ivy, sps) = wadjb(ii, 0, 0, ivy, sps) + rqsm*fsb
   pab = pab + siadj(ii, 0, 0, 2, sps)*fsb
   fsb = fact*dwadjb(imx, sps)
   rqspb = rqspb + wadj(ii+1, 0, 0, ivx, sps)*fsb
   wadjb(ii+1, 0, 0, ivx, sps) = wadjb(ii+1, 0, 0, ivx, sps) + rqsp*fsb
   rqsmb = rqsmb + wadj(ii, 0, 0, ivx, sps)*fsb
   wadjb(ii, 0, 0, ivx, sps) = wadjb(ii, 0, 0, ivx, sps) + rqsm*fsb
   pab = pab + siadj(ii, 0, 0, 1, sps)*fsb
   fsb = fact*dwadjb(irho, sps)
   rqspb = rqspb + fsb
   qspb = qspb + wadj(ii+1, 0, 0, irho, sps)*rqspb
   vnpb = porvel*qspb + padj(ii+1, 0, 0, sps)*tempb
   padjb(ii+1, 0, 0, sps) = padjb(ii+1, 0, 0, sps) + vnp*tempb
   rqsmb = rqsmb + fsb
   qsmb = qsmb + wadj(ii, 0, 0, irho, sps)*rqsmb
   vnmb = porvel*qsmb + padj(ii, 0, 0, sps)*tempb
   padjb(ii, 0, 0, sps) = padjb(ii, 0, 0, sps) + vnm*tempb
   padjb(ii+1, 0, 0, sps) = padjb(ii+1, 0, 0, sps) + porflux*pab
   padjb(ii, 0, 0, sps) = padjb(ii, 0, 0, sps) + porflux*pab
   wadjb(ii, 0, 0, irho, sps) = wadjb(ii, 0, 0, irho, sps) + qsm*rqsmb
   wadjb(ii+1, 0, 0, irho, sps) = wadjb(ii+1, 0, 0, irho, sps) + qsp*&
   &      rqspb
   CALL POPREAL8ARRAY(qsm, realtype/8)
   CALL POPREAL8ARRAY(qsp, realtype/8)
   CALL POPINTEGER4(branch)
   IF (.NOT.branch .LT. 1) THEN
   vnmb = 0.0
   vnpb = 0.0
   END IF
   CALL POPREAL8ARRAY(porflux, realtype/8)
   CALL POPREAL8ARRAY(porvel, realtype/8)
   CALL POPREAL8ARRAY(vnm, realtype/8)
   wadjb(ii, 0, 0, ivx, sps) = wadjb(ii, 0, 0, ivx, sps) + siadj(ii, 0&
   &      , 0, 1, sps)*vnmb
   wadjb(ii, 0, 0, ivy, sps) = wadjb(ii, 0, 0, ivy, sps) + siadj(ii, 0&
   &      , 0, 2, sps)*vnmb
   wadjb(ii, 0, 0, ivz, sps) = wadjb(ii, 0, 0, ivz, sps) + siadj(ii, 0&
   &      , 0, 3, sps)*vnmb
   CALL POPREAL8ARRAY(vnp, realtype/8)
   wadjb(ii+1, 0, 0, ivx, sps) = wadjb(ii+1, 0, 0, ivx, sps) + siadj(ii&
   &      , 0, 0, 1, sps)*vnpb
   wadjb(ii+1, 0, 0, ivy, sps) = wadjb(ii+1, 0, 0, ivy, sps) + siadj(ii&
   &      , 0, 0, 2, sps)*vnpb
   wadjb(ii+1, 0, 0, ivz, sps) = wadjb(ii+1, 0, 0, ivz, sps) + siadj(ii&
   &      , 0, 0, 3, sps)*vnpb
   END DO
   END SUBROUTINE INVISCIDCENTRALFLUXNKPC_B