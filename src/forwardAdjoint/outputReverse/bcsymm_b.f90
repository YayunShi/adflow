   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !  Differentiation of bcsymm in reverse (adjoint) mode (with options i4 dr8 r8 noISIZE):
   !   gradient     of useful results: *rev *p *w *rlv
   !   with respect to varying inputs: *rev *p *w *rlv
   !   Plus diff mem management of: rev:in p:in gamma:in w:in rlv:in
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          bcSymm.f90                                      *
   !      * Author:        Edwin van der Weide                             *
   !      * Starting date: 03-07-2003                                      *
   !      * Last modified: 06-12-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE BCSYMM_B(secondhalo)
   !
   !      ******************************************************************
   !      *                                                                *
   !      * bcSymm applies the symmetry boundary conditions to a block.    *
   !      * It is assumed that the pointers in blockPointers are already   *
   !      * set to the correct block on the correct grid level.            *
   !      *                                                                *
   !      * In case also the second halo must be set the loop over the     *
   !      * boundary subfaces is executed twice. This is the only correct  *
   !      * way in case the block contains only 1 cell between two         *
   !      * symmetry planes, i.e. a 2D problem.                            *
   !      *                                                                *
   !      ******************************************************************
   !
   USE BLOCKPOINTERS_B
   USE BCTYPES
   USE CONSTANTS
   USE FLOWVARREFSTATE
   USE ITERATION
   IMPLICIT NONE
   !
   !      Subroutine arguments.
   !
   LOGICAL, INTENT(IN) :: secondhalo
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: kk, mm, nn, i, j, l
   REAL(kind=realtype) :: vn, nnx, nny, nnz
   REAL(kind=realtype) :: vnb
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ww1, ww2
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ww1b, ww2b
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp1, pp2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp1b, pp2b
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: gamma1, gamma2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rlv1, rlv2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rlv1b, rlv2b
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rev1, rev2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rev1b, rev2b
   INTERFACE 
   SUBROUTINE SETBCPOINTERS(nn, ww1, ww2, pp1, pp2, rlv1, rlv2, &
   &       rev1, rev2, offset)
   USE BLOCKPOINTERS_B
   IMPLICIT NONE
   INTEGER(kind=inttype), INTENT(IN) :: nn, offset
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ww1, ww2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp1, pp2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rlv1, rlv2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rev1, rev2
   END SUBROUTINE SETBCPOINTERS
   END INTERFACE
      INTERFACE 
   SUBROUTINE SETBCPOINTERS_B(nn, ww1, ww1b, ww2, ww2b, pp1, pp1b, &
   &       pp2, pp2b, rlv1, rlv1b, rlv2, rlv2b, rev1, rev1b, rev2, rev2b, &
   &       offset)
   USE BLOCKPOINTERS_B
   IMPLICIT NONE
   INTEGER(kind=inttype), INTENT(IN) :: nn, offset
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ww1, ww2
   REAL(kind=realtype), DIMENSION(:, :, :), POINTER :: ww1b, ww2b
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp1, pp2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: pp1b, pp2b
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rlv1, rlv2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rlv1b, rlv2b
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rev1, rev2
   REAL(kind=realtype), DIMENSION(:, :), POINTER :: rev1b, rev2b
   END SUBROUTINE SETBCPOINTERS_B
   END INTERFACE
      REAL(kind=realtype) :: tmp
   REAL(kind=realtype) :: tmp0
   REAL(kind=realtype) :: tmp1
   REAL(kind=realtype) :: tmp2
   REAL(kind=realtype) :: tmp3
   REAL(kind=realtype) :: tmp4
   REAL(kind=realtype) :: tmp5
   REAL(kind=realtype) :: tmp6
   REAL(kind=realtype) :: tmp7
   REAL(kind=realtype) :: tmp8
   INTEGER :: branch
   INTEGER :: ad_from
   INTEGER :: ad_to
   INTEGER :: ad_from0
   INTEGER :: ad_to0
   INTERFACE 
   SUBROUTINE PUSHPOINTER4(pp)
   REAL, POINTER :: pp
   END SUBROUTINE PUSHPOINTER4
   SUBROUTINE LOOKPOINTER4(pp)
   REAL, POINTER :: pp
   END SUBROUTINE LOOKPOINTER4
   SUBROUTINE POPPOINTER4(pp)
   REAL, POINTER :: pp
   END SUBROUTINE POPPOINTER4
   END INTERFACE
      REAL(kind=realtype) :: tmpb7
   REAL(kind=realtype) :: tmpb6
   REAL(kind=realtype) :: tmpb5
   REAL(kind=realtype) :: tmpb4
   REAL(kind=realtype) :: tmpb3
   REAL(kind=realtype) :: tmpb
   REAL(kind=realtype) :: tmpb2
   REAL(kind=realtype) :: tmpb1
   REAL(kind=realtype) :: tmpb0
   REAL(kind=realtype) :: tempb
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Set the value of kk; kk == 0 means only single halo, kk == 1
   ! double halo.
   kk = 0
   IF (secondhalo) kk = 1
   ! Loop over the number of times the halo computation must be done.
   nhalo:DO mm=0,kk
   ! Loop over the boundary condition subfaces of this block.
   bocos:DO nn=1,nbocos
   ! Check for symmetry boundary condition.
   IF (bctype(nn) .EQ. symm) THEN
   ! Nullify the pointers, because some compilers require that.
   !nullify(ww1, ww2, pp1, pp2, rlv1, rlv2, rev1, rev2)
   ! Set the pointers to the correct subface.
   CALL PUSHPOINTER4(rev2)
   CALL PUSHPOINTER4(rev1)
   CALL PUSHPOINTER4(rlv2)
   CALL PUSHPOINTER4(rlv1)
   CALL PUSHPOINTER4(pp2)
   CALL PUSHPOINTER4(pp1)
   CALL PUSHPOINTER4(ww2)
   CALL PUSHPOINTER4(ww1)
   CALL SETBCPOINTERS(nn, ww1, ww2, pp1, pp2, rlv1, rlv2, rev1, &
   &                       rev2, mm)
   ! Set the additional pointers for gamma1 and gamma2.
   SELECT CASE  (bcfaceid(nn)) 
   CASE (imin) 
   gamma2 => gamma(2, 1:, 1:)
   CASE (imax) 
   gamma2 => gamma(il, 1:, 1:)
   CASE (jmin) 
   gamma2 => gamma(1:, 2, 1:)
   CASE (jmax) 
   gamma2 => gamma(1:, jl, 1:)
   CASE (kmin) 
   gamma2 => gamma(1:, 1:, 2)
   CASE (kmax) 
   gamma2 => gamma(1:, 1:, kl)
   END SELECT
   ad_from0 = bcdata(nn)%jcbeg
   ! Loop over the generic subface to set the state in the
   ! halo cells.
   DO j=ad_from0,bcdata(nn)%jcend
   ad_from = bcdata(nn)%icbeg
   DO i=ad_from,bcdata(nn)%icend
   ! Store the three components of the unit normal a
   ! bit easier.
   nnx = bcdata(nn)%norm(i, j, 1)
   nny = bcdata(nn)%norm(i, j, 2)
   nnz = bcdata(nn)%norm(i, j, 3)
   ! Determine twice the normal velocity component,
   ! which must be substracted from the donor velocity
   ! to obtain the halo velocity.
   vn = two*(ww2(i, j, ivx)*nnx+ww2(i, j, ivy)*nny+ww2(i, j, &
   &             ivz)*nnz)
   ! Determine the flow variables in the halo cell.
   tmp = ww2(i, j, irho)
   CALL PUSHREAL8(ww1(i, j, irho))
   ww1(i, j, irho) = tmp
   tmp0 = ww2(i, j, ivx) - vn*nnx
   CALL PUSHREAL8(ww1(i, j, ivx))
   ww1(i, j, ivx) = tmp0
   tmp1 = ww2(i, j, ivy) - vn*nny
   CALL PUSHREAL8(ww1(i, j, ivy))
   ww1(i, j, ivy) = tmp1
   tmp2 = ww2(i, j, ivz) - vn*nnz
   CALL PUSHREAL8(ww1(i, j, ivz))
   ww1(i, j, ivz) = tmp2
   tmp3 = ww2(i, j, irhoe)
   CALL PUSHREAL8(ww1(i, j, irhoe))
   ww1(i, j, irhoe) = tmp3
   ! Simply copy the turbulent variables.
   DO l=nt1mg,nt2mg
   tmp4 = ww2(i, j, l)
   CALL PUSHREAL8(ww1(i, j, l))
   ww1(i, j, l) = tmp4
   END DO
   ! Set the pressure and gamma and possibly the
   ! laminar and eddy viscosity in the halo.
   tmp5 = gamma2(i, j)
   gamma1(i, j) = tmp5
   tmp6 = pp2(i, j)
   pp1(i, j) = tmp6
   IF (viscous) THEN
   tmp7 = rlv2(i, j)
   CALL PUSHREAL8(rlv1(i, j))
   rlv1(i, j) = tmp7
   CALL PUSHCONTROL1B(0)
   ELSE
   CALL PUSHCONTROL1B(1)
   END IF
   IF (eddymodel) THEN
   tmp8 = rev2(i, j)
   rev1(i, j) = tmp8
   CALL PUSHCONTROL1B(1)
   ELSE
   CALL PUSHCONTROL1B(0)
   END IF
   END DO
   CALL PUSHINTEGER4(i - 1)
   CALL PUSHINTEGER4(ad_from)
   END DO
   CALL PUSHINTEGER4(j - 1)
   CALL PUSHINTEGER4(ad_from0)
   CALL PUSHCONTROL1B(1)
   ELSE
   CALL PUSHCONTROL1B(0)
   END IF
   END DO bocos
   END DO nhalo
   DO mm=kk,0,-1
   DO nn=nbocos,1,-1
   CALL POPCONTROL1B(branch)
   IF (branch .NE. 0) THEN
   CALL POPINTEGER4(ad_from0)
   CALL POPINTEGER4(ad_to0)
   DO j=ad_to0,ad_from0,-1
   CALL POPINTEGER4(ad_from)
   CALL POPINTEGER4(ad_to)
   DO i=ad_to,ad_from,-1
   CALL POPCONTROL1B(branch)
   IF (branch .NE. 0) THEN
   tmpb7 = rev1b(i, j)
   rev1b(i, j) = 0.0_8
   rev2b(i, j) = rev2b(i, j) + tmpb7
   END IF
   CALL POPCONTROL1B(branch)
   IF (branch .EQ. 0) THEN
   CALL POPREAL8(rlv1(i, j))
   tmpb6 = rlv1b(i, j)
   rlv1b(i, j) = 0.0_8
   rlv2b(i, j) = rlv2b(i, j) + tmpb6
   END IF
   tmpb5 = pp1b(i, j)
   pp1b(i, j) = 0.0_8
   pp2b(i, j) = pp2b(i, j) + tmpb5
   DO l=nt2mg,nt1mg,-1
   CALL POPREAL8(ww1(i, j, l))
   tmpb4 = ww1b(i, j, l)
   ww1b(i, j, l) = 0.0_8
   ww2b(i, j, l) = ww2b(i, j, l) + tmpb4
   END DO
   CALL POPREAL8(ww1(i, j, irhoe))
   tmpb = ww1b(i, j, irhoe)
   ww1b(i, j, irhoe) = 0.0_8
   ww2b(i, j, irhoe) = ww2b(i, j, irhoe) + tmpb
   nnz = bcdata(nn)%norm(i, j, 3)
   CALL POPREAL8(ww1(i, j, ivz))
   tmpb0 = ww1b(i, j, ivz)
   ww1b(i, j, ivz) = 0.0_8
   ww2b(i, j, ivz) = ww2b(i, j, ivz) + tmpb0
   nny = bcdata(nn)%norm(i, j, 2)
   CALL POPREAL8(ww1(i, j, ivy))
   tmpb1 = ww1b(i, j, ivy)
   ww1b(i, j, ivy) = 0.0_8
   ww2b(i, j, ivy) = ww2b(i, j, ivy) + tmpb1
   nnx = bcdata(nn)%norm(i, j, 1)
   CALL POPREAL8(ww1(i, j, ivx))
   tmpb2 = ww1b(i, j, ivx)
   vnb = -(nny*tmpb1) - nnx*tmpb2 - nnz*tmpb0
   ww1b(i, j, ivx) = 0.0_8
   ww2b(i, j, ivx) = ww2b(i, j, ivx) + tmpb2
   CALL POPREAL8(ww1(i, j, irho))
   tmpb3 = ww1b(i, j, irho)
   ww1b(i, j, irho) = 0.0_8
   ww2b(i, j, irho) = ww2b(i, j, irho) + tmpb3
   tempb = two*vnb
   ww2b(i, j, ivx) = ww2b(i, j, ivx) + nnx*tempb
   ww2b(i, j, ivy) = ww2b(i, j, ivy) + nny*tempb
   ww2b(i, j, ivz) = ww2b(i, j, ivz) + nnz*tempb
   END DO
   END DO
   CALL POPPOINTER4(ww1)
   CALL POPPOINTER4(ww2)
   CALL POPPOINTER4(pp1)
   CALL POPPOINTER4(pp2)
   CALL POPPOINTER4(rlv1)
   CALL POPPOINTER4(rlv2)
   CALL POPPOINTER4(rev1)
   CALL POPPOINTER4(rev2)
   CALL SETBCPOINTERS_B(nn, ww1, ww1b, ww2, ww2b, pp1, pp1b, pp2, &
   &                      pp2b, rlv1, rlv1b, rlv2, rlv2b, rev1, rev1b, rev2&
   &                      , rev2b, mm)
   END IF
   END DO
   END DO
   END SUBROUTINE BCSYMM_B