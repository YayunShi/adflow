!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module flowutils_fast_b
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------

contains
  subroutine computettot(rho, u, v, w, p, ttot)
!
!      ******************************************************************
!      *                                                                *
!      * computettot computes the total temperature for the given       *
!      * pressures, densities and velocities.                           *
!      *                                                                *
!      ******************************************************************
!
    use cpcurvefits
    use flowvarrefstate
    use inputphysics
    use utils_fast_b, only : terminate
    implicit none
!
!      subroutine arguments.
!
    real(kind=realtype), intent(in) :: rho, p, u, v, w
    real(kind=realtype), intent(out) :: ttot
!
!      local variables.
!
    integer(kind=inttype) :: i
    real(kind=realtype) :: govgm1, t, kin
! determine the cp model used.
    select case  (cpmodel) 
    case (cpconstant) 
! constant cp and thus constant gamma. the well-known
! formula is valid.
      govgm1 = gammainf/(gammainf-one)
      t = p/(rho*rgas)
      kin = half*(u*u+v*v+w*w)
      ttot = t*(one+rho*kin/(govgm1*p))
    case (cptempcurvefits) 
!===============================================================
! cp is a function of the temperature. the formula used for
! constant cp is not valid anymore and a more complicated
! procedure must be followed.
      call terminate('computettot', &
&              'variable cp formulation not implemented yet')
    end select
  end subroutine computettot
  subroutine computegamma(t, gamma, mm)
!
!      ******************************************************************
!      *                                                                *
!      * computegamma computes the corresponding values of gamma for    *
!      * the given dimensional temperatures.                            *
!      *                                                                *
!      ******************************************************************
!
    use constants
    use cpcurvefits
    use inputphysics
    implicit none
    integer(kind=inttype), intent(in) :: mm
!
!      subroutine arguments.
!
    real(kind=realtype), dimension(mm), intent(in) :: t
    real(kind=realtype), dimension(mm), intent(out) :: gamma
!
!      local variables.
!
    integer(kind=inttype) :: i, ii, nn, start
    real(kind=realtype) :: cp, t2
! determine the cp model used in the computation.
    select case  (cpmodel) 
    case (cpconstant) 
! constant cp and thus constant gamma. set the values.
      do i=1,mm
        gamma(i) = gammaconstant
      end do
    case (cptempcurvefits) 
!        ================================================================
! cp as function of the temperature is given via curve fits.
      do 100 i=1,mm
! determine the case we are having here.
        if (t(i) .le. cptrange(0)) then
! temperature is less than the smallest temperature
! in the curve fits. use cv0 to compute gamma.
          gamma(i) = (cv0+one)/cv0
        else if (t(i) .ge. cptrange(cpnparts)) then
! temperature is larger than the largest temperature
! in the curve fits. use cvn to compute gamma.
          gamma(i) = (cvn+one)/cvn
        else
! temperature is in the curve fit range.
! first find the valid range.
          ii = cpnparts
          start = 1
 interval:do 
! next guess for the interval.
            nn = start + ii/2
! determine the situation we are having here.
            if (t(i) .gt. cptrange(nn)) then
! temperature is larger than the upper boundary of
! the current interval. update the lower boundary.
              start = nn + 1
              ii = ii - 1
            else if (t(i) .ge. cptrange(nn-1)) then
! nn contains the correct curve fit interval.
! compute the value of cp.
              cp = zero
              do ii=1,cptempfit(nn)%nterm
                t2 = t(i)**cptempfit(nn)%exponents(ii)
                cp = cp + cptempfit(nn)%constants(ii)*t2
              end do
! compute the corresponding value of gamma.
              gamma(i) = cp/(cp-one)
              goto 100
            end if
! this is the correct range. exit the do-loop.
! modify ii for the next branch to search.
            ii = ii/2
          end do interval
        end if
 100  continue
    end select
  end subroutine computegamma
  subroutine computeptot(rho, u, v, w, p, ptot)
!
!      ******************************************************************
!      *                                                                *
!      * computeptot computes the total pressure for the given          *
!      * pressures, densities and velocities.                           *
!      *                                                                *
!      ******************************************************************
!
    use cpcurvefits
    use flowvarrefstate
    use inputphysics
    implicit none
    real(kind=realtype), intent(in) :: rho, p, u, v, w
    real(kind=realtype), intent(out) :: ptot
!
!      local parameters.
!
    real(kind=realtype), parameter :: dtstop=0.01_realtype
!
!      local variables.
!
    integer(kind=inttype) :: i, ii, mm, nn, nnt, start
    real(kind=realtype) :: govgm1, kin
    real(kind=realtype) :: t, t2, tt, dt, h, htot, cp, scale, alp
    real(kind=realtype) :: intcport, intcportt, intcporttt
    intrinsic log
    intrinsic abs
    intrinsic exp
    real(kind=realtype) :: abs0
!
! determine the cp model used.
    select case  (cpmodel) 
    case (cpconstant) 
! constant cp and thus constant gamma. the well-known
! formula is valid.
      govgm1 = gammainf/(gammainf-one)
      kin = half*(u*u+v*v+w*w)
      ptot = p*(one+rho*kin/(govgm1*p))**govgm1
    case (cptempcurvefits) 
!===============================================================
! cp is a function of the temperature. the formula used for
! constant cp is not valid anymore and a more complicated
! procedure must be followed.
! compute the dimensional temperature and the scale
! factor to convert the integral of cp to the correct
! nondimensional value.
      t = tref*p/(rgas*rho)
      scale = rgas/tref
! compute the enthalpy and the integrand of cp/(r*t) at the
! given temperature. take care of the exceptional situations.
      if (t .le. cptrange(0)) then
! temperature is smaller than the smallest temperature in
! the curve fit range. use extrapolation using constant cp.
        nn = 0
        cp = cv0 + one
        h = scale*(cphint(0)+cp*(t-cptrange(0)))
        intcportt = cp*log(t)
      else if (t .ge. cptrange(cpnparts)) then
! temperature is larger than the largest temperature in the
! curve fit range. use extrapolation using constant cp.
        nn = cpnparts + 1
        cp = cvn + one
        h = scale*(cphint(cpnparts)+cp*(t-cptrange(cpnparts)))
        intcportt = cp*log(t)
      else
! temperature lies in the curve fit range. find the correct
! interval.
        ii = cpnparts
        start = 1
interval:do 
! next guess for the interval.
          nn = start + ii/2
! determine the situation we are having here.
          if (t .gt. cptrange(nn)) then
! temperature is larger than the upper boundary of
! the current interval. update the lower boundary.
            start = nn + 1
            ii = ii - 1
          else if (t .ge. cptrange(nn-1)) then
! nn contains the correct curve fit interval.
! integrate cp to compute h and the integrand of cp/(r*t)
            h = cptempfit(nn)%eint0
            intcportt = zero
            do ii=1,cptempfit(nn)%nterm
              if (cptempfit(nn)%exponents(ii) .eq. -1_inttype) then
                h = h + cptempfit(nn)%constants(ii)*log(t)
              else
                mm = cptempfit(nn)%exponents(ii) + 1
                t2 = t**mm
                h = h + cptempfit(nn)%constants(ii)*t2/mm
              end if
              if (cptempfit(nn)%exponents(ii) .eq. 0_inttype) then
                intcportt = intcportt + cptempfit(nn)%constants(ii)*log(&
&                 t)
              else
                mm = cptempfit(nn)%exponents(ii)
                t2 = t**mm
                intcportt = intcportt + cptempfit(nn)%constants(ii)*t2/&
&                 mm
              end if
            end do
            h = scale*h
            goto 100
          end if
! this is the correct range. exit the do-loop.
! modify ii for the next branch to search.
          ii = ii/2
        end do interval
      end if
! compute the total enthalpy. divide by scale to get the same
! dimensions as for the integral of cp/r.
 100  htot = (h+half*(u*u+v*v+w*w))/scale
! compute the corresponding total temperature. first determine
! the situation we are having here.
      if (htot .le. cphint(0)) then
! total enthalpy is smaller than the lowest value of the
! curve fit. use extrapolation using constant cp.
        nnt = 0
        tt = cptrange(0) + (htot-cphint(0))/(cv0+one)
      else if (htot .ge. cphint(cpnparts)) then
! total enthalpy is larger than the largest value of the
! curve fit. use extrapolation using constant cp.
        nnt = cpnparts + 1
        tt = cptrange(cpnparts) + (htot-cphint(cpnparts))/(cvn+one)
      else
! total temperature is in the range of the curve fits.
! use a newton algorithm to find the correct temperature.
! first find the correct interval.
        ii = cpnparts
        start = 1
intervaltt:do 
! next guess for the interval.
          nnt = start + ii/2
! determine the situation we are having here.
          if (htot .gt. cphint(nnt)) then
! enthalpy is larger than the upper boundary of
! the current interval. update the lower boundary.
            start = nnt + 1
            ii = ii - 1
          else if (htot .ge. cphint(nnt-1)) then
! nnt contains the range in which the newton algorithm must
! be applied. initial guess of the total temperature.
            alp = (cphint(nnt)-htot)/(cphint(nnt)-cphint(nnt-1))
            tt = alp*cptrange(nnt-1) + (one-alp)*cptrange(nnt)
! the actual newton algorithm to compute the total
! temperature.
     newton:do 
! compute the energy as well as the value of cv/r for the
! given temperature.
              cp = zero
              h = cptempfit(nnt)%eint0
              do ii=1,cptempfit(nnt)%nterm
! update cp.
                t2 = tt**cptempfit(nnt)%exponents(ii)
                cp = cp + cptempfit(nnt)%constants(ii)*t2
! update h, for which this contribution must be
! integrated. take the exceptional case that the
! exponent == -1 into account.
                if (cptempfit(nnt)%exponents(ii) .eq. -1_inttype) then
                  h = h + cptempfit(nnt)%constants(ii)*log(tt)
                else
                  h = h + cptempfit(nnt)%constants(ii)*t2*tt/(cptempfit(&
&                   nnt)%exponents(ii)+1)
                end if
              end do
! compute the update and the new total temperature.
              dt = (htot-h)/cp
              tt = tt + dt
              if (dt .ge. 0.) then
                abs0 = dt
              else
                abs0 = -dt
              end if
! exit the newton loop if the update is smaller than the
! threshold value.
              if (abs0 .lt. dtstop) goto 110
            end do newton
          end if
! this is the correct range. exit the do-loop.
! modify ii for the next branch to search.
          ii = ii/2
        end do intervaltt
      end if
! to compute the total pressure, the integral of cp/(r*t)
! must be computed from t = t to t = tt. compute the integrand
! at t = tt; take care of the exceptional situations.
 110  if (tt .le. cptrange(0)) then
        intcporttt = (cv0+one)*log(tt)
      else if (tt .ge. cptrange(cpnparts)) then
        intcporttt = (cvn+one)*log(tt)
      else
        intcporttt = zero
        do ii=1,cptempfit(nnt)%nterm
          if (cptempfit(nnt)%exponents(ii) .eq. 0_inttype) then
            intcporttt = intcporttt + cptempfit(nnt)%constants(ii)*log(&
&             tt)
          else
            mm = cptempfit(nnt)%exponents(ii)
            t2 = tt**mm
            intcporttt = intcporttt + cptempfit(nnt)%constants(ii)*t2/mm
          end if
        end do
      end if
! compute the integral of cp/(r*t) from t to tt. first
! substract the lower boundary from the upper boundary.
      intcport = intcporttt - intcportt
! add the contributions from the possible internal curve fit
! boundaries if tt and t are in different curve fit intervals.
      do mm=nn+1,nnt
        ii = mm - 1
        if (ii .eq. 0_inttype) then
          intcport = intcport + (cv0+one)*log(cptrange(0))
        else
          intcport = intcport + cptempfit(ii)%intcpovrt_2
        end if
        if (mm .gt. cpnparts) then
          intcport = intcport - (cvn+one)*log(cptrange(cpnparts))
        else
          intcport = intcport - cptempfit(mm)%intcpovrt_1
        end if
      end do
! and finally, compute the total pressure.
      ptot = p*exp(intcport)
    end select
  end subroutine computeptot
!  differentiation of computespeedofsoundsquared in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: *aa *p *w
!   with respect to varying inputs: *aa *p *w
!   rw status of diff variables: *aa:in-out *p:incr *w:incr
!   plus diff mem management of: aa:in p:in w:in
  subroutine computespeedofsoundsquared_fast_b()
!
!      ******************************************************************
!      *                                                                *
!      * computespeedofsoundsquared does what it says.                  *
!      *                                                                *
!      ******************************************************************
!
    use constants
    use blockpointers, only : ie, je, ke, w, wd, p, pd, aa, aad, gamma
    use utils_fast_b, only : getcorrectfork
    implicit none
!
!      local variables.
!
    real(kind=realtype), parameter :: twothird=two*third
    integer(kind=inttype) :: i, j, k, ii
    real(kind=realtype) :: pp
    real(kind=realtype) :: ppd
    logical :: correctfork
    intrinsic mod
    real(kind=realtype) :: temp0
    real(kind=realtype) :: tempd
    real(kind=realtype) :: tempd0
    real(kind=realtype) :: temp
! determine if we need to correct for k
    correctfork = getcorrectfork()
    if (correctfork) then
      do ii=0,ie*je*ke-1
        i = mod(ii, ie) + 1
        j = mod(ii/ie, je) + 1
        k = ii/(ie*je) + 1
        pp = p(i, j, k) - twothird*w(i, j, k, irho)*w(i, j, k, itu1)
        temp = w(i, j, k, irho)
        tempd = gamma(i, j, k)*aad(i, j, k)/temp
        ppd = tempd
        wd(i, j, k, irho) = wd(i, j, k, irho) - pp*tempd/temp
        aad(i, j, k) = 0.0_8
        pd(i, j, k) = pd(i, j, k) + ppd
        wd(i, j, k, irho) = wd(i, j, k, irho) - twothird*w(i, j, k, itu1&
&         )*ppd
        wd(i, j, k, itu1) = wd(i, j, k, itu1) - twothird*w(i, j, k, irho&
&         )*ppd
      end do
    else
      do ii=0,ie*je*ke-1
        i = mod(ii, ie) + 1
        j = mod(ii/ie, je) + 1
        k = ii/(ie*je) + 1
        temp0 = w(i, j, k, irho)
        tempd0 = gamma(i, j, k)*aad(i, j, k)/temp0
        pd(i, j, k) = pd(i, j, k) + tempd0
        wd(i, j, k, irho) = wd(i, j, k, irho) - p(i, j, k)*tempd0/temp0
        aad(i, j, k) = 0.0_8
      end do
    end if
  end subroutine computespeedofsoundsquared_fast_b
  subroutine computespeedofsoundsquared()
!
!      ******************************************************************
!      *                                                                *
!      * computespeedofsoundsquared does what it says.                  *
!      *                                                                *
!      ******************************************************************
!
    use constants
    use blockpointers, only : ie, je, ke, w, p, aa, gamma
    use utils_fast_b, only : getcorrectfork
    implicit none
!
!      local variables.
!
    real(kind=realtype), parameter :: twothird=two*third
    integer(kind=inttype) :: i, j, k, ii
    real(kind=realtype) :: pp
    logical :: correctfork
    intrinsic mod
! determine if we need to correct for k
    correctfork = getcorrectfork()
    if (correctfork) then
      do ii=0,ie*je*ke-1
        i = mod(ii, ie) + 1
        j = mod(ii/ie, je) + 1
        k = ii/(ie*je) + 1
        pp = p(i, j, k) - twothird*w(i, j, k, irho)*w(i, j, k, itu1)
        aa(i, j, k) = gamma(i, j, k)*pp/w(i, j, k, irho)
      end do
    else
      do ii=0,ie*je*ke-1
        i = mod(ii, ie) + 1
        j = mod(ii/ie, je) + 1
        k = ii/(ie*je) + 1
        aa(i, j, k) = gamma(i, j, k)*p(i, j, k)/w(i, j, k, irho)
      end do
    end if
  end subroutine computespeedofsoundsquared
!
!      ******************************************************************
!      *                                                                *
!      * file:          computeetot.f90                                 *
!      * author:        edwin van der weide, steve repsher              *
!      * starting date: 08-13-2003                                      *
!      * last modified: 10-14-2005                                      *
!      *                                                                *
!      ******************************************************************
!
  subroutine computeetotblock(istart, iend, jstart, jend, kstart, kend, &
&   correctfork)
!
!      ******************************************************************
!      *                                                                *
!      * computeetot computes the total energy from the given density,  *
!      * velocity and presssure. for a calorically and thermally        *
!      * perfect gas the well-known expression is used; for only a      *
!      * thermally perfect gas, cp is a function of temperature, curve  *
!      * fits are used and a more complex expression is obtained.       *
!      * it is assumed that the pointers in blockpointers already       *
!      * point to the correct block.                                    *
!      *                                                                *
!      ******************************************************************
!
    use blockpointers
    use flowvarrefstate
    use inputphysics
    implicit none
!
!      subroutine arguments.
!
    integer(kind=inttype), intent(in) :: istart, iend, jstart, jend
    integer(kind=inttype), intent(in) :: kstart, kend
    logical, intent(in) :: correctfork
!
!      local variables.
!
    integer(kind=inttype) :: i, j, k
    real(kind=realtype) :: ovgm1, factk, scale
!      ******************************************************************
!      *                                                                *
!      * begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! determine the cp model used in the computation.
    select case  (cpmodel) 
    case (cpconstant) 
! constant cp and thus constant gamma.
! abbreviate 1/(gamma -1) a bit easier.
      ovgm1 = one/(gammaconstant-one)
! loop over the given range of the block and compute the first
! step of the energy.
      do k=kstart,kend
        do j=jstart,jend
          do i=istart,iend
            w(i, j, k, irhoe) = ovgm1*p(i, j, k) + half*w(i, j, k, irho)&
&             *(w(i, j, k, ivx)**2+w(i, j, k, ivy)**2+w(i, j, k, ivz)**2&
&             )
          end do
        end do
      end do
! second step. correct the energy in case a turbulent kinetic
! energy is present.
      if (correctfork) then
        factk = ovgm1*(five*third-gammaconstant)
        do k=kstart,kend
          do j=jstart,jend
            do i=istart,iend
              w(i, j, k, irhoe) = w(i, j, k, irhoe) - factk*w(i, j, k, &
&               irho)*w(i, j, k, itu1)
            end do
          end do
        end do
      end if
    end select
!
 40 format(1x,i4,i4,i4,e20.6)
  end subroutine computeetotblock
  subroutine etot(rho, u, v, w, p, k, etotal, correctfork)
!
!      ******************************************************************
!      *                                                                *
!      * etotarray computes the total energy from the given density,    *
!      * velocity and presssure.                                        *
!      * first the internal energy per unit mass is computed and after  *
!      * that the kinetic energy is added as well the conversion to     *
!      * energy per unit volume.                                        *
!      *                                                                *
!      ******************************************************************
!
    use constants
    implicit none
!
!      subroutine arguments.
!
    real(kind=realtype), intent(in) :: rho, p, k
    real(kind=realtype), intent(in) :: u, v, w
    real(kind=realtype), intent(out) :: etotal
    logical, intent(in) :: correctfork
!
!      local variables.
!
    integer(kind=inttype) :: i
! compute the internal energy for unit mass.
    call eint(rho, p, k, etotal, correctfork)
    etotal = rho*(etotal+half*(u*u+v*v+w*w))
  end subroutine etot
!      ==================================================================
  subroutine eint(rho, p, k, einternal, correctfork)
!
!      ******************************************************************
!      *                                                                *
!      * eintarray computes the internal energy per unit mass from the  *
!      * given density and pressure (and possibly turbulent energy)     *
!      * for a calorically and thermally perfect gas the well-known     *
!      * expression is used; for only a thermally perfect gas, cp is a  *
!      * function of temperature, curve fits are used and a more        *
!      * complex expression is obtained.                                *
!      *                                                                *
!      ******************************************************************
!
    use constants
    use cpcurvefits
    use flowvarrefstate
    use inputphysics
    implicit none
!
!      subroutine arguments.
!
    real(kind=realtype), intent(in) :: rho, p, k
    real(kind=realtype), intent(out) :: einternal
    logical, intent(in) :: correctfork
!
!      local parameter.
!
    real(kind=realtype), parameter :: twothird=two*third
!
!      local variables.
!
    integer(kind=inttype) :: i, nn, mm, ii, start
    real(kind=realtype) :: ovgm1, factk, pp, t, t2, scale
! determine the cp model used in the computation.
    select case  (cpmodel) 
    case (cpconstant) 
! abbreviate 1/(gamma -1) a bit easier.
      ovgm1 = one/(gammaconstant-one)
! loop over the number of elements of the array and compute
! the total energy.
      einternal = ovgm1*p/rho
! second step. correct the energy in case a turbulent kinetic
! energy is present.
      if (correctfork) then
        factk = ovgm1*(five*third-gammaconstant)
        einternal = einternal - factk*k
      end if
    end select
  end subroutine eint
end module flowutils_fast_b
