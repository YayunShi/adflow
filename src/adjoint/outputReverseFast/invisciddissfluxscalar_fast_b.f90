!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of invisciddissfluxscalar in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: *p *w *fw
!   with respect to varying inputs: *p *w *fw *radi *radj *radk
!   rw status of diff variables: *p:incr *w:incr *fw:in-out *radi:out
!                *radj:out *radk:out
!   plus diff mem management of: p:in w:in fw:in radi:in radj:in
!                radk:in
!
!      ******************************************************************
!      *                                                                *
!      * file:          invisciddissfluxscalar.f90                      *
!      * author:        edwin van der weide                             *
!      * starting date: 03-24-2003                                      *
!      * last modified: 10-29-2007                                      *
!      *                                                                *
!      ******************************************************************
!
subroutine invisciddissfluxscalar_fast_b()
!
!      ******************************************************************
!      *                                                                *
!      * invisciddissfluxscalar computes the scalar artificial          *
!      * dissipation, see aiaa paper 81-1259, for a given block.        *
!      * therefore it is assumed that the pointers in  blockpointers    *
!      * already point to the correct block.                            *
!      *                                                                *
!      ******************************************************************
!
  use constants
  use blockpointers, only : nx, ny, nz, il, jl, kl, ie, je, ke, ib, jb&
& , kb, w, wd, p, pd, pori, porj, pork, fw, fwd, radi, radid, radj, &
& radjd, radk, radkd, gamma
  use flowvarrefstate, only : gammainf, pinfcorr, rhoinf
  use inputdiscretization, only : vis2, vis4
  use inputphysics, only : equations
  use iteration, only : rfil
  use utils_fast_b, only : mydim, mydim_fast_b
  implicit none
!
!      local parameter.
!
  real(kind=realtype), parameter :: dssmax=0.25_realtype
!
!      local variables.
!
  integer(kind=inttype) :: i, j, k, ind, ii
  real(kind=realtype) :: sslim, rhoi
  real(kind=realtype) :: sfil, fis2, fis4
  real(kind=realtype) :: ppor, rrad, dis2, dis4
  real(kind=realtype) :: rradd, dis2d, dis4d
  real(kind=realtype) :: ddw1, ddw2, ddw3, ddw4, ddw5, fs
  real(kind=realtype) :: ddw1d, ddw2d, ddw3d, ddw4d, ddw5d, fsd
  real(kind=realtype), dimension(ie, je, ke, 3) :: dss
  real(kind=realtype), dimension(ie, je, ke, 3) :: dssd
  real(kind=realtype), dimension(0:ib, 0:jb, 0:kb) :: ss
  real(kind=realtype), dimension(0:ib, 0:jb, 0:kb) :: ssd
  intrinsic abs
  intrinsic mod
  intrinsic max
  intrinsic min
  real(kind=realtype) :: arg1
  real(kind=realtype) :: arg1d
  integer :: branch
  real(kind=realtype) :: temp3
  real(kind=realtype) :: tempd14
  real(kind=realtype) :: temp29
  real(kind=realtype) :: temp2
  real(kind=realtype) :: temp28
  real(kind=realtype) :: tempd13
  real(kind=realtype) :: temp1
  real(kind=realtype) :: temp27
  real(kind=realtype) :: tempd12
  real(kind=realtype) :: temp0
  real(kind=realtype) :: temp26
  real(kind=realtype) :: tempd11
  real(kind=realtype) :: temp25
  real(kind=realtype) :: tempd10
  real(kind=realtype) :: temp24
  real(kind=realtype) :: temp23
  real(kind=realtype) :: temp22
  real(kind=realtype) :: temp21
  real(kind=realtype) :: temp20
  real(kind=realtype) :: min3
  real(kind=realtype) :: min2
  real(kind=realtype) :: min1
  real(kind=realtype) :: min1d
  real(kind=realtype) :: x3
  real(kind=realtype) :: x2
  real(kind=realtype) :: x2d
  real(kind=realtype) :: x1
  real(kind=realtype) :: temp19
  real(kind=realtype) :: temp18
  real(kind=realtype) :: temp17
  real(kind=realtype) :: temp16
  real(kind=realtype) :: temp15
  real(kind=realtype) :: temp14
  real(kind=realtype) :: temp13
  real(kind=realtype) :: y3d
  real(kind=realtype) :: temp12
  real(kind=realtype) :: temp11
  real(kind=realtype) :: temp10
  real(kind=realtype) :: temp40
  real(kind=realtype) :: tempd9
  real(kind=realtype) :: tempd
  real(kind=realtype) :: tempd8
  real(kind=realtype) :: tempd7
  real(kind=realtype) :: tempd6
  real(kind=realtype) :: tempd5
  real(kind=realtype) :: tempd4
  real(kind=realtype) :: tempd3
  real(kind=realtype) :: tempd2
  real(kind=realtype) :: tempd1
  real(kind=realtype) :: tempd0
  real(kind=realtype) :: x1d
  real(kind=realtype) :: min3d
  real(kind=realtype) :: y2d
  real(kind=realtype) :: temp39
  real(kind=realtype) :: temp38
  real(kind=realtype) :: temp37
  real(kind=realtype) :: temp36
  real(kind=realtype) :: temp35
  real(kind=realtype) :: temp34
  real(kind=realtype) :: temp33
  real(kind=realtype) :: temp32
  real(kind=realtype) :: temp31
  real(kind=realtype) :: temp30
  real(kind=realtype) :: abs0
  real(kind=realtype) :: temp
  real(kind=realtype) :: temp9
  real(kind=realtype) :: temp8
  real(kind=realtype) :: min2d
  real(kind=realtype) :: tempd19
  real(kind=realtype) :: temp7
  real(kind=realtype) :: tempd18
  real(kind=realtype) :: y3
  real(kind=realtype) :: temp6
  real(kind=realtype) :: tempd17
  real(kind=realtype) :: y2
  real(kind=realtype) :: x3d
  real(kind=realtype) :: temp5
  real(kind=realtype) :: tempd16
  real(kind=realtype) :: y1
  real(kind=realtype) :: temp4
  real(kind=realtype) :: y1d
  real(kind=realtype) :: tempd15
  if (rfil .ge. 0.) then
    abs0 = rfil
  else
    abs0 = -rfil
  end if
!
!      ******************************************************************
!      *                                                                *
!      * begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! check if rfil == 0. if so, the dissipative flux needs not to
! be computed.
  if (abs0 .lt. thresholdreal) then
    radid = 0.0_8
    radjd = 0.0_8
    radkd = 0.0_8
  else
! determine the variables used to compute the switch.
! for the inviscid case this is the pressure; for the viscous
! case it is the entropy.
    select case  (equations) 
    case (eulerequations) 
! inviscid case. pressure switch is based on the pressure.
! also set the value of sslim. to be fully consistent this
! must have the dimension of pressure and it is therefore
! set to a fraction of the free stream value.
      sslim = 0.001_realtype*pinfcorr
! copy the pressure in ss. only need the entries used in the
! discretization, i.e. not including the corner halo's, but we'll
! just copy all anyway. 
      ss = p
      call pushcontrol2b(1)
    case (nsequations, ransequations) 
!===============================================================
! viscous case. pressure switch is based on the entropy.
! also set the value of sslim. to be fully consistent this
! must have the dimension of entropy and it is therefore
! set to a fraction of the free stream value.
      sslim = 0.001_realtype*pinfcorr/rhoinf**gammainf
! store the entropy in ss. see above. 
      do ii=0,(ib+1)*(jb+1)*(kb+1)-1
        i = mod(ii, ib + 1)
        j = mod(ii/(ib+1), jb + 1)
        k = ii/((ib+1)*(jb+1))
        ss(i, j, k) = p(i, j, k)/w(i, j, k, irho)**gamma(i, j, k)
      end do
      call pushcontrol2b(0)
    case default
      call pushcontrol2b(2)
    end select
! compute the pressure sensor for each cell, in each direction:
    do ii=0,ie*je*ke-1
      i = mod(ii, ie) + 1
      j = mod(ii/ie, je) + 1
      k = ii/(ie*je) + 1
      x1 = (ss(i+1, j, k)-two*ss(i, j, k)+ss(i-1, j, k))/(ss(i+1, j, k)+&
&       two*ss(i, j, k)+ss(i-1, j, k)+sslim)
      if (x1 .ge. 0.) then
        dss(i, j, k, 1) = x1
      else
        dss(i, j, k, 1) = -x1
      end if
      x2 = (ss(i, j+1, k)-two*ss(i, j, k)+ss(i, j-1, k))/(ss(i, j+1, k)+&
&       two*ss(i, j, k)+ss(i, j-1, k)+sslim)
      if (x2 .ge. 0.) then
        dss(i, j, k, 2) = x2
      else
        dss(i, j, k, 2) = -x2
      end if
      x3 = (ss(i, j, k+1)-two*ss(i, j, k)+ss(i, j, k-1))/(ss(i, j, k+1)+&
&       two*ss(i, j, k)+ss(i, j, k-1)+sslim)
      if (x3 .ge. 0.) then
        dss(i, j, k, 3) = x3
      else
        dss(i, j, k, 3) = -x3
      end if
    end do
! set a couple of constants for the scheme.
    fis2 = rfil*vis2
    fis4 = rfil*vis4
    sfil = one - rfil
! initialize the dissipative residual to a certain times,
! possibly zero, the previously stored value. owned cells
! only, because the halo values do not matter.
    radkd = 0.0_8
    dssd = 0.0_8
    do ii=0,nx*ny*kl-1
      i = mod(ii, nx) + 2
      j = mod(ii/nx, ny) + 2
      k = ii/(nx*ny) + 1
! compute the dissipation coefficients for this face.
      ppor = zero
      if (pork(i, j, k) .eq. normalflux) ppor = half
      rrad = ppor*(radk(i, j, k)+radk(i, j, k+1))
      if (dss(i, j, k, 3) .lt. dss(i, j, k+1, 3)) then
        y3 = dss(i, j, k+1, 3)
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
        y3 = dss(i, j, k, 3)
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      if (dssmax .gt. y3) then
        min3 = y3
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
        min3 = dssmax
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      dis2 = fis2*rrad*min3
      arg1 = fis4*rrad
      dis4 = mydim(arg1, dis2)
! compute and scatter the dissipative flux.
! density. store it in the mass flow of the
! appropriate sliding mesh interface.
      ddw1 = w(i, j, k+1, irho) - w(i, j, k, irho)
! x-momentum.
      ddw2 = w(i, j, k+1, ivx)*w(i, j, k+1, irho) - w(i, j, k, ivx)*w(i&
&       , j, k, irho)
! y-momentum.
      ddw3 = w(i, j, k+1, ivy)*w(i, j, k+1, irho) - w(i, j, k, ivy)*w(i&
&       , j, k, irho)
! z-momentum.
      ddw4 = w(i, j, k+1, ivz)*w(i, j, k+1, irho) - w(i, j, k, ivz)*w(i&
&       , j, k, irho)
! energy.
      ddw5 = w(i, j, k+1, irhoe) + p(i, j, k+1) - (w(i, j, k, irhoe)+p(i&
&       , j, k))
      fsd = fwd(i, j, k+1, irhoe) - fwd(i, j, k, irhoe)
      tempd15 = -(dis4*fsd)
      dis2d = ddw5*fsd
      ddw5d = dis2*fsd - three*tempd15
      dis4d = -((w(i, j, k+2, irhoe)+p(i, j, k+2)-w(i, j, k-1, irhoe)-p(&
&       i, j, k-1)-three*ddw5)*fsd)
      wd(i, j, k+2, irhoe) = wd(i, j, k+2, irhoe) + tempd15
      pd(i, j, k+2) = pd(i, j, k+2) + tempd15
      wd(i, j, k-1, irhoe) = wd(i, j, k-1, irhoe) - tempd15
      pd(i, j, k-1) = pd(i, j, k-1) - tempd15
      wd(i, j, k+1, irhoe) = wd(i, j, k+1, irhoe) + ddw5d
      pd(i, j, k+1) = pd(i, j, k+1) + ddw5d
      wd(i, j, k, irhoe) = wd(i, j, k, irhoe) - ddw5d
      pd(i, j, k) = pd(i, j, k) - ddw5d
      fsd = fwd(i, j, k+1, imz) - fwd(i, j, k, imz)
      temp40 = w(i, j, k-1, irho)
      temp39 = w(i, j, k-1, ivz)
      temp38 = w(i, j, k+2, irho)
      temp37 = w(i, j, k+2, ivz)
      tempd16 = -(dis4*fsd)
      dis2d = dis2d + ddw4*fsd
      ddw4d = dis2*fsd - three*tempd16
      dis4d = dis4d - (temp37*temp38-temp39*temp40-three*ddw4)*fsd
      wd(i, j, k+2, ivz) = wd(i, j, k+2, ivz) + temp38*tempd16
      wd(i, j, k+2, irho) = wd(i, j, k+2, irho) + temp37*tempd16
      wd(i, j, k-1, ivz) = wd(i, j, k-1, ivz) - temp40*tempd16
      wd(i, j, k-1, irho) = wd(i, j, k-1, irho) - temp39*tempd16
      wd(i, j, k+1, ivz) = wd(i, j, k+1, ivz) + w(i, j, k+1, irho)*ddw4d
      wd(i, j, k+1, irho) = wd(i, j, k+1, irho) + w(i, j, k+1, ivz)*&
&       ddw4d
      wd(i, j, k, ivz) = wd(i, j, k, ivz) - w(i, j, k, irho)*ddw4d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivz)*ddw4d
      fsd = fwd(i, j, k+1, imy) - fwd(i, j, k, imy)
      temp36 = w(i, j, k-1, irho)
      temp35 = w(i, j, k-1, ivy)
      temp34 = w(i, j, k+2, irho)
      temp33 = w(i, j, k+2, ivy)
      tempd17 = -(dis4*fsd)
      dis2d = dis2d + ddw3*fsd
      ddw3d = dis2*fsd - three*tempd17
      dis4d = dis4d - (temp33*temp34-temp35*temp36-three*ddw3)*fsd
      wd(i, j, k+2, ivy) = wd(i, j, k+2, ivy) + temp34*tempd17
      wd(i, j, k+2, irho) = wd(i, j, k+2, irho) + temp33*tempd17
      wd(i, j, k-1, ivy) = wd(i, j, k-1, ivy) - temp36*tempd17
      wd(i, j, k-1, irho) = wd(i, j, k-1, irho) - temp35*tempd17
      wd(i, j, k+1, ivy) = wd(i, j, k+1, ivy) + w(i, j, k+1, irho)*ddw3d
      wd(i, j, k+1, irho) = wd(i, j, k+1, irho) + w(i, j, k+1, ivy)*&
&       ddw3d
      wd(i, j, k, ivy) = wd(i, j, k, ivy) - w(i, j, k, irho)*ddw3d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivy)*ddw3d
      fsd = fwd(i, j, k+1, imx) - fwd(i, j, k, imx)
      temp32 = w(i, j, k-1, irho)
      temp31 = w(i, j, k-1, ivx)
      temp30 = w(i, j, k+2, irho)
      temp29 = w(i, j, k+2, ivx)
      tempd18 = -(dis4*fsd)
      dis2d = dis2d + ddw2*fsd
      ddw2d = dis2*fsd - three*tempd18
      dis4d = dis4d - (temp29*temp30-temp31*temp32-three*ddw2)*fsd
      wd(i, j, k+2, ivx) = wd(i, j, k+2, ivx) + temp30*tempd18
      wd(i, j, k+2, irho) = wd(i, j, k+2, irho) + temp29*tempd18
      wd(i, j, k-1, ivx) = wd(i, j, k-1, ivx) - temp32*tempd18
      wd(i, j, k-1, irho) = wd(i, j, k-1, irho) - temp31*tempd18
      wd(i, j, k+1, ivx) = wd(i, j, k+1, ivx) + w(i, j, k+1, irho)*ddw2d
      wd(i, j, k+1, irho) = wd(i, j, k+1, irho) + w(i, j, k+1, ivx)*&
&       ddw2d
      wd(i, j, k, ivx) = wd(i, j, k, ivx) - w(i, j, k, irho)*ddw2d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivx)*ddw2d
      fsd = fwd(i, j, k+1, irho) - fwd(i, j, k, irho)
      tempd19 = -(dis4*fsd)
      dis2d = dis2d + ddw1*fsd
      ddw1d = dis2*fsd - three*tempd19
      dis4d = dis4d - (w(i, j, k+2, irho)-w(i, j, k-1, irho)-three*ddw1)&
&       *fsd
      wd(i, j, k+2, irho) = wd(i, j, k+2, irho) + tempd19
      wd(i, j, k-1, irho) = wd(i, j, k-1, irho) - tempd19
      wd(i, j, k+1, irho) = wd(i, j, k+1, irho) + ddw1d
      wd(i, j, k, irho) = wd(i, j, k, irho) - ddw1d
      arg1d = 0.0_8
      call mydim_fast_b(arg1, arg1d, dis2, dis2d, dis4d)
      rradd = fis2*min3*dis2d + fis4*arg1d
      min3d = fis2*rrad*dis2d
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        y3d = min3d
      else
        y3d = 0.0_8
      end if
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        dssd(i, j, k+1, 3) = dssd(i, j, k+1, 3) + y3d
      else
        dssd(i, j, k, 3) = dssd(i, j, k, 3) + y3d
      end if
      radkd(i, j, k) = radkd(i, j, k) + ppor*rradd
      radkd(i, j, k+1) = radkd(i, j, k+1) + ppor*rradd
    end do
    radjd = 0.0_8
    do ii=0,nx*jl*nz-1
      i = mod(ii, nx) + 2
      j = mod(ii/nx, jl) + 1
      k = ii/(nx*jl) + 2
! compute the dissipation coefficients for this face.
      ppor = zero
      if (porj(i, j, k) .eq. normalflux) ppor = half
      rrad = ppor*(radj(i, j, k)+radj(i, j+1, k))
      if (dss(i, j, k, 2) .lt. dss(i, j+1, k, 2)) then
        y2 = dss(i, j+1, k, 2)
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
        y2 = dss(i, j, k, 2)
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      if (dssmax .gt. y2) then
        min2 = y2
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
        min2 = dssmax
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      dis2 = fis2*rrad*min2
      arg1 = fis4*rrad
      dis4 = mydim(arg1, dis2)
! compute and scatter the dissipative flux.
! density. store it in the mass flow of the
! appropriate sliding mesh interface.
      ddw1 = w(i, j+1, k, irho) - w(i, j, k, irho)
! x-momentum.
      ddw2 = w(i, j+1, k, ivx)*w(i, j+1, k, irho) - w(i, j, k, ivx)*w(i&
&       , j, k, irho)
! y-momentum.
      ddw3 = w(i, j+1, k, ivy)*w(i, j+1, k, irho) - w(i, j, k, ivy)*w(i&
&       , j, k, irho)
! z-momentum.
      ddw4 = w(i, j+1, k, ivz)*w(i, j+1, k, irho) - w(i, j, k, ivz)*w(i&
&       , j, k, irho)
! energy.
      ddw5 = w(i, j+1, k, irhoe) + p(i, j+1, k) - (w(i, j, k, irhoe)+p(i&
&       , j, k))
      fsd = fwd(i, j+1, k, irhoe) - fwd(i, j, k, irhoe)
      tempd10 = -(dis4*fsd)
      dis2d = ddw5*fsd
      ddw5d = dis2*fsd - three*tempd10
      dis4d = -((w(i, j+2, k, irhoe)+p(i, j+2, k)-w(i, j-1, k, irhoe)-p(&
&       i, j-1, k)-three*ddw5)*fsd)
      wd(i, j+2, k, irhoe) = wd(i, j+2, k, irhoe) + tempd10
      pd(i, j+2, k) = pd(i, j+2, k) + tempd10
      wd(i, j-1, k, irhoe) = wd(i, j-1, k, irhoe) - tempd10
      pd(i, j-1, k) = pd(i, j-1, k) - tempd10
      wd(i, j+1, k, irhoe) = wd(i, j+1, k, irhoe) + ddw5d
      pd(i, j+1, k) = pd(i, j+1, k) + ddw5d
      wd(i, j, k, irhoe) = wd(i, j, k, irhoe) - ddw5d
      pd(i, j, k) = pd(i, j, k) - ddw5d
      fsd = fwd(i, j+1, k, imz) - fwd(i, j, k, imz)
      temp28 = w(i, j-1, k, irho)
      temp27 = w(i, j-1, k, ivz)
      temp26 = w(i, j+2, k, irho)
      temp25 = w(i, j+2, k, ivz)
      tempd11 = -(dis4*fsd)
      dis2d = dis2d + ddw4*fsd
      ddw4d = dis2*fsd - three*tempd11
      dis4d = dis4d - (temp25*temp26-temp27*temp28-three*ddw4)*fsd
      wd(i, j+2, k, ivz) = wd(i, j+2, k, ivz) + temp26*tempd11
      wd(i, j+2, k, irho) = wd(i, j+2, k, irho) + temp25*tempd11
      wd(i, j-1, k, ivz) = wd(i, j-1, k, ivz) - temp28*tempd11
      wd(i, j-1, k, irho) = wd(i, j-1, k, irho) - temp27*tempd11
      wd(i, j+1, k, ivz) = wd(i, j+1, k, ivz) + w(i, j+1, k, irho)*ddw4d
      wd(i, j+1, k, irho) = wd(i, j+1, k, irho) + w(i, j+1, k, ivz)*&
&       ddw4d
      wd(i, j, k, ivz) = wd(i, j, k, ivz) - w(i, j, k, irho)*ddw4d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivz)*ddw4d
      fsd = fwd(i, j+1, k, imy) - fwd(i, j, k, imy)
      temp24 = w(i, j-1, k, irho)
      temp23 = w(i, j-1, k, ivy)
      temp22 = w(i, j+2, k, irho)
      temp21 = w(i, j+2, k, ivy)
      tempd12 = -(dis4*fsd)
      dis2d = dis2d + ddw3*fsd
      ddw3d = dis2*fsd - three*tempd12
      dis4d = dis4d - (temp21*temp22-temp23*temp24-three*ddw3)*fsd
      wd(i, j+2, k, ivy) = wd(i, j+2, k, ivy) + temp22*tempd12
      wd(i, j+2, k, irho) = wd(i, j+2, k, irho) + temp21*tempd12
      wd(i, j-1, k, ivy) = wd(i, j-1, k, ivy) - temp24*tempd12
      wd(i, j-1, k, irho) = wd(i, j-1, k, irho) - temp23*tempd12
      wd(i, j+1, k, ivy) = wd(i, j+1, k, ivy) + w(i, j+1, k, irho)*ddw3d
      wd(i, j+1, k, irho) = wd(i, j+1, k, irho) + w(i, j+1, k, ivy)*&
&       ddw3d
      wd(i, j, k, ivy) = wd(i, j, k, ivy) - w(i, j, k, irho)*ddw3d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivy)*ddw3d
      fsd = fwd(i, j+1, k, imx) - fwd(i, j, k, imx)
      temp20 = w(i, j-1, k, irho)
      temp19 = w(i, j-1, k, ivx)
      temp18 = w(i, j+2, k, irho)
      temp17 = w(i, j+2, k, ivx)
      tempd13 = -(dis4*fsd)
      dis2d = dis2d + ddw2*fsd
      ddw2d = dis2*fsd - three*tempd13
      dis4d = dis4d - (temp17*temp18-temp19*temp20-three*ddw2)*fsd
      wd(i, j+2, k, ivx) = wd(i, j+2, k, ivx) + temp18*tempd13
      wd(i, j+2, k, irho) = wd(i, j+2, k, irho) + temp17*tempd13
      wd(i, j-1, k, ivx) = wd(i, j-1, k, ivx) - temp20*tempd13
      wd(i, j-1, k, irho) = wd(i, j-1, k, irho) - temp19*tempd13
      wd(i, j+1, k, ivx) = wd(i, j+1, k, ivx) + w(i, j+1, k, irho)*ddw2d
      wd(i, j+1, k, irho) = wd(i, j+1, k, irho) + w(i, j+1, k, ivx)*&
&       ddw2d
      wd(i, j, k, ivx) = wd(i, j, k, ivx) - w(i, j, k, irho)*ddw2d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivx)*ddw2d
      fsd = fwd(i, j+1, k, irho) - fwd(i, j, k, irho)
      tempd14 = -(dis4*fsd)
      dis2d = dis2d + ddw1*fsd
      ddw1d = dis2*fsd - three*tempd14
      dis4d = dis4d - (w(i, j+2, k, irho)-w(i, j-1, k, irho)-three*ddw1)&
&       *fsd
      wd(i, j+2, k, irho) = wd(i, j+2, k, irho) + tempd14
      wd(i, j-1, k, irho) = wd(i, j-1, k, irho) - tempd14
      wd(i, j+1, k, irho) = wd(i, j+1, k, irho) + ddw1d
      wd(i, j, k, irho) = wd(i, j, k, irho) - ddw1d
      arg1d = 0.0_8
      call mydim_fast_b(arg1, arg1d, dis2, dis2d, dis4d)
      rradd = fis2*min2*dis2d + fis4*arg1d
      min2d = fis2*rrad*dis2d
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        y2d = min2d
      else
        y2d = 0.0_8
      end if
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        dssd(i, j+1, k, 2) = dssd(i, j+1, k, 2) + y2d
      else
        dssd(i, j, k, 2) = dssd(i, j, k, 2) + y2d
      end if
      radjd(i, j, k) = radjd(i, j, k) + ppor*rradd
      radjd(i, j+1, k) = radjd(i, j+1, k) + ppor*rradd
    end do
    radid = 0.0_8
    do ii=0,il*ny*nz-1
      i = mod(ii, il) + 1
      j = mod(ii/il, ny) + 2
      k = ii/(il*ny) + 2
! compute the dissipation coefficients for this face.
      ppor = zero
      if (pori(i, j, k) .eq. normalflux) ppor = half
      rrad = ppor*(radi(i, j, k)+radi(i+1, j, k))
      if (dss(i, j, k, 1) .lt. dss(i+1, j, k, 1)) then
        y1 = dss(i+1, j, k, 1)
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
        y1 = dss(i, j, k, 1)
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      if (dssmax .gt. y1) then
        min1 = y1
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
        min1 = dssmax
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      dis2 = fis2*rrad*min1
      arg1 = fis4*rrad
      dis4 = mydim(arg1, dis2)
! compute and scatter the dissipative flux.
! density. store it in the mass flow of the
! appropriate sliding mesh interface.
      ddw1 = w(i+1, j, k, irho) - w(i, j, k, irho)
! x-momentum.
      ddw2 = w(i+1, j, k, ivx)*w(i+1, j, k, irho) - w(i, j, k, ivx)*w(i&
&       , j, k, irho)
! y-momentum.
      ddw3 = w(i+1, j, k, ivy)*w(i+1, j, k, irho) - w(i, j, k, ivy)*w(i&
&       , j, k, irho)
! z-momentum.
      ddw4 = w(i+1, j, k, ivz)*w(i+1, j, k, irho) - w(i, j, k, ivz)*w(i&
&       , j, k, irho)
! energy.
      ddw5 = w(i+1, j, k, irhoe) + p(i+1, j, k) - (w(i, j, k, irhoe)+p(i&
&       , j, k))
      fsd = fwd(i+1, j, k, irhoe) - fwd(i, j, k, irhoe)
      tempd5 = -(dis4*fsd)
      dis2d = ddw5*fsd
      ddw5d = dis2*fsd - three*tempd5
      dis4d = -((w(i+2, j, k, irhoe)+p(i+2, j, k)-w(i-1, j, k, irhoe)-p(&
&       i-1, j, k)-three*ddw5)*fsd)
      wd(i+2, j, k, irhoe) = wd(i+2, j, k, irhoe) + tempd5
      pd(i+2, j, k) = pd(i+2, j, k) + tempd5
      wd(i-1, j, k, irhoe) = wd(i-1, j, k, irhoe) - tempd5
      pd(i-1, j, k) = pd(i-1, j, k) - tempd5
      wd(i+1, j, k, irhoe) = wd(i+1, j, k, irhoe) + ddw5d
      pd(i+1, j, k) = pd(i+1, j, k) + ddw5d
      wd(i, j, k, irhoe) = wd(i, j, k, irhoe) - ddw5d
      pd(i, j, k) = pd(i, j, k) - ddw5d
      fsd = fwd(i+1, j, k, imz) - fwd(i, j, k, imz)
      temp16 = w(i-1, j, k, irho)
      temp15 = w(i-1, j, k, ivz)
      temp14 = w(i+2, j, k, irho)
      temp13 = w(i+2, j, k, ivz)
      tempd6 = -(dis4*fsd)
      dis2d = dis2d + ddw4*fsd
      ddw4d = dis2*fsd - three*tempd6
      dis4d = dis4d - (temp13*temp14-temp15*temp16-three*ddw4)*fsd
      wd(i+2, j, k, ivz) = wd(i+2, j, k, ivz) + temp14*tempd6
      wd(i+2, j, k, irho) = wd(i+2, j, k, irho) + temp13*tempd6
      wd(i-1, j, k, ivz) = wd(i-1, j, k, ivz) - temp16*tempd6
      wd(i-1, j, k, irho) = wd(i-1, j, k, irho) - temp15*tempd6
      wd(i+1, j, k, ivz) = wd(i+1, j, k, ivz) + w(i+1, j, k, irho)*ddw4d
      wd(i+1, j, k, irho) = wd(i+1, j, k, irho) + w(i+1, j, k, ivz)*&
&       ddw4d
      wd(i, j, k, ivz) = wd(i, j, k, ivz) - w(i, j, k, irho)*ddw4d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivz)*ddw4d
      fsd = fwd(i+1, j, k, imy) - fwd(i, j, k, imy)
      temp12 = w(i-1, j, k, irho)
      temp11 = w(i-1, j, k, ivy)
      temp10 = w(i+2, j, k, irho)
      temp9 = w(i+2, j, k, ivy)
      tempd7 = -(dis4*fsd)
      dis2d = dis2d + ddw3*fsd
      ddw3d = dis2*fsd - three*tempd7
      dis4d = dis4d - (temp9*temp10-temp11*temp12-three*ddw3)*fsd
      wd(i+2, j, k, ivy) = wd(i+2, j, k, ivy) + temp10*tempd7
      wd(i+2, j, k, irho) = wd(i+2, j, k, irho) + temp9*tempd7
      wd(i-1, j, k, ivy) = wd(i-1, j, k, ivy) - temp12*tempd7
      wd(i-1, j, k, irho) = wd(i-1, j, k, irho) - temp11*tempd7
      wd(i+1, j, k, ivy) = wd(i+1, j, k, ivy) + w(i+1, j, k, irho)*ddw3d
      wd(i+1, j, k, irho) = wd(i+1, j, k, irho) + w(i+1, j, k, ivy)*&
&       ddw3d
      wd(i, j, k, ivy) = wd(i, j, k, ivy) - w(i, j, k, irho)*ddw3d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivy)*ddw3d
      fsd = fwd(i+1, j, k, imx) - fwd(i, j, k, imx)
      temp8 = w(i-1, j, k, irho)
      temp7 = w(i-1, j, k, ivx)
      temp6 = w(i+2, j, k, irho)
      temp5 = w(i+2, j, k, ivx)
      tempd8 = -(dis4*fsd)
      dis2d = dis2d + ddw2*fsd
      ddw2d = dis2*fsd - three*tempd8
      dis4d = dis4d - (temp5*temp6-temp7*temp8-three*ddw2)*fsd
      wd(i+2, j, k, ivx) = wd(i+2, j, k, ivx) + temp6*tempd8
      wd(i+2, j, k, irho) = wd(i+2, j, k, irho) + temp5*tempd8
      wd(i-1, j, k, ivx) = wd(i-1, j, k, ivx) - temp8*tempd8
      wd(i-1, j, k, irho) = wd(i-1, j, k, irho) - temp7*tempd8
      wd(i+1, j, k, ivx) = wd(i+1, j, k, ivx) + w(i+1, j, k, irho)*ddw2d
      wd(i+1, j, k, irho) = wd(i+1, j, k, irho) + w(i+1, j, k, ivx)*&
&       ddw2d
      wd(i, j, k, ivx) = wd(i, j, k, ivx) - w(i, j, k, irho)*ddw2d
      wd(i, j, k, irho) = wd(i, j, k, irho) - w(i, j, k, ivx)*ddw2d
      fsd = fwd(i+1, j, k, irho) - fwd(i, j, k, irho)
      tempd9 = -(dis4*fsd)
      dis2d = dis2d + ddw1*fsd
      ddw1d = dis2*fsd - three*tempd9
      dis4d = dis4d - (w(i+2, j, k, irho)-w(i-1, j, k, irho)-three*ddw1)&
&       *fsd
      wd(i+2, j, k, irho) = wd(i+2, j, k, irho) + tempd9
      wd(i-1, j, k, irho) = wd(i-1, j, k, irho) - tempd9
      wd(i+1, j, k, irho) = wd(i+1, j, k, irho) + ddw1d
      wd(i, j, k, irho) = wd(i, j, k, irho) - ddw1d
      arg1d = 0.0_8
      call mydim_fast_b(arg1, arg1d, dis2, dis2d, dis4d)
      rradd = fis2*min1*dis2d + fis4*arg1d
      min1d = fis2*rrad*dis2d
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        y1d = min1d
      else
        y1d = 0.0_8
      end if
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        dssd(i+1, j, k, 1) = dssd(i+1, j, k, 1) + y1d
      else
        dssd(i, j, k, 1) = dssd(i, j, k, 1) + y1d
      end if
      radid(i, j, k) = radid(i, j, k) + ppor*rradd
      radid(i+1, j, k) = radid(i+1, j, k) + ppor*rradd
    end do
    fwd = sfil*fwd
    ssd = 0.0_8
    do ii=0,ie*je*ke-1
      i = mod(ii, ie) + 1
      j = mod(ii/ie, je) + 1
      k = ii/(ie*je) + 1
      x1 = (ss(i+1, j, k)-two*ss(i, j, k)+ss(i-1, j, k))/(ss(i+1, j, k)+&
&       two*ss(i, j, k)+ss(i-1, j, k)+sslim)
      if (x1 .ge. 0.) then
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      x2 = (ss(i, j+1, k)-two*ss(i, j, k)+ss(i, j-1, k))/(ss(i, j+1, k)+&
&       two*ss(i, j, k)+ss(i, j-1, k)+sslim)
      if (x2 .ge. 0.) then
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 0
      else
myIntPtr = myIntPtr + 1
 myIntStack(myIntPtr) = 1
      end if
      x3 = (ss(i, j, k+1)-two*ss(i, j, k)+ss(i, j, k-1))/(ss(i, j, k+1)+&
&       two*ss(i, j, k)+ss(i, j, k-1)+sslim)
      if (x3 .ge. 0.) then
        x3d = dssd(i, j, k, 3)
        dssd(i, j, k, 3) = 0.0_8
      else
        x3d = -dssd(i, j, k, 3)
        dssd(i, j, k, 3) = 0.0_8
      end if
      temp4 = sslim + ss(i, j, k+1) + two*ss(i, j, k) + ss(i, j, k-1)
      tempd3 = x3d/temp4
      tempd4 = -((ss(i, j, k+1)-two*ss(i, j, k)+ss(i, j, k-1))*tempd3/&
&       temp4)
      ssd(i, j, k+1) = ssd(i, j, k+1) + tempd4 + tempd3
      ssd(i, j, k) = ssd(i, j, k) + two*tempd4 - two*tempd3
      ssd(i, j, k-1) = ssd(i, j, k-1) + tempd4 + tempd3
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        x2d = dssd(i, j, k, 2)
        dssd(i, j, k, 2) = 0.0_8
      else
        x2d = -dssd(i, j, k, 2)
        dssd(i, j, k, 2) = 0.0_8
      end if
      temp3 = sslim + ss(i, j+1, k) + two*ss(i, j, k) + ss(i, j-1, k)
      tempd1 = x2d/temp3
      tempd2 = -((ss(i, j+1, k)-two*ss(i, j, k)+ss(i, j-1, k))*tempd1/&
&       temp3)
      ssd(i, j+1, k) = ssd(i, j+1, k) + tempd2 + tempd1
      ssd(i, j, k) = ssd(i, j, k) + two*tempd2 - two*tempd1
      ssd(i, j-1, k) = ssd(i, j-1, k) + tempd2 + tempd1
branch = myIntStack(myIntPtr)
 myIntPtr = myIntPtr - 1
      if (branch .eq. 0) then
        x1d = dssd(i, j, k, 1)
        dssd(i, j, k, 1) = 0.0_8
      else
        x1d = -dssd(i, j, k, 1)
        dssd(i, j, k, 1) = 0.0_8
      end if
      temp2 = sslim + ss(i+1, j, k) + two*ss(i, j, k) + ss(i-1, j, k)
      tempd = x1d/temp2
      tempd0 = -((ss(i+1, j, k)-two*ss(i, j, k)+ss(i-1, j, k))*tempd/&
&       temp2)
      ssd(i+1, j, k) = ssd(i+1, j, k) + tempd0 + tempd
      ssd(i, j, k) = ssd(i, j, k) + two*tempd0 - two*tempd
      ssd(i-1, j, k) = ssd(i-1, j, k) + tempd0 + tempd
    end do
    call popcontrol2b(branch)
    if (branch .eq. 0) then
      do ii=0,(ib+1)*(jb+1)*(kb+1)-1
        i = mod(ii, ib + 1)
        j = mod(ii/(ib+1), jb + 1)
        k = ii/((ib+1)*(jb+1))
        temp1 = gamma(i, j, k)
        temp0 = w(i, j, k, irho)
        temp = temp0**temp1
        pd(i, j, k) = pd(i, j, k) + ssd(i, j, k)/temp
        if (.not.(temp0 .le. 0.0_8 .and. (temp1 .eq. 0.0_8 .or. temp1 &
&           .ne. int(temp1)))) wd(i, j, k, irho) = wd(i, j, k, irho) - p&
&           (i, j, k)*temp1*temp0**(temp1-1)*ssd(i, j, k)/temp**2
        ssd(i, j, k) = 0.0_8
      end do
    else if (branch .eq. 1) then
      pd = pd + ssd
    end if
  end if
end subroutine invisciddissfluxscalar_fast_b
