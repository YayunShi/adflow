!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module zipperintegrations_d
  implicit none

contains
!  differentiation of flowintegrationzipper in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: localvalues
!   with respect to varying inputs: pointref timeref tref rgas
!                pref rhoref vars localvalues
!   rw status of diff variables: pointref:in timeref:in tref:in
!                rgas:in pref:in rhoref:in vars:in localvalues:in-out
  subroutine flowintegrationzipper_d(isinflow, conn, fams, vars, varsd, &
&   localvalues, localvaluesd, famlist, sps, ptvalid)
! integrate over the trianges for the inflow/outflow conditions.
    use constants
    use blockpointers, only : bctype
    use sorting, only : faminlist
    use flowvarrefstate, only : pref, prefd, pinf, pinfd, rhoref, &
&   rhorefd, pref, prefd, timeref, timerefd, lref, tref, trefd, rgas, &
&   rgasd, uref, urefd, uinf, uinfd, rhoinf, rhoinfd
    use inputphysics, only : pointref, pointrefd, flowtype
    use flowutils_d, only : computeptot, computeptot_d, computettot, &
&   computettot_d
    use surfacefamilies, only : familyexchange, bcfamexchange
    use utils_d, only : mynorm2, mynorm2_d, cross_prod, cross_prod_d
    implicit none
! input/output variables
    logical, intent(in) :: isinflow
    integer(kind=inttype), dimension(:, :), intent(in) :: conn
    integer(kind=inttype), dimension(:), intent(in) :: fams
    real(kind=realtype), dimension(:, :), intent(in) :: vars
    real(kind=realtype), dimension(:, :), intent(in) :: varsd
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvaluesd
    integer(kind=inttype), dimension(:), intent(in) :: famlist
    integer(kind=inttype), intent(in) :: sps
    logical(kind=inttype), dimension(:), optional, intent(in) :: ptvalid
! working variables
    integer(kind=inttype) :: i, j
    real(kind=realtype) :: sf, vmag, vnm, vxm, vym, vzm, fx, fy, fz, u, &
&   v, w, vnmfreestreamref
    real(kind=realtype) :: sfd, vmagd, vnmd, vxmd, vymd, vzmd, fxd, fyd&
&   , fzd, wd
    real(kind=realtype), dimension(3) :: fp, mp, fmom, mmom, refpoint, &
&   ss, x1, x2, x3, norm, sfacecoordref
    real(kind=realtype), dimension(3) :: fpd, mpd, fmomd, mmomd, &
&   refpointd, ssd, x1d, x2d, x3d, normd, sfacecoordrefd
    real(kind=realtype) :: pm, ptot, ttot, rhom, gammam, mnm, &
&   massflowratelocal, am
    real(kind=realtype) :: pmd, ptotd, ttotd, rhomd, gammamd, mnmd, &
&   massflowratelocald, amd
    real(kind=realtype) :: massflowrate, mass_ptot, mass_ttot, mass_ps, &
&   mass_mn, mass_a, mass_rho, mass_vx, mass_vy, mass_vz, mass_nx, &
&   mass_ny, mass_nz
    real(kind=realtype) :: massflowrated, mass_ptotd, mass_ttotd, &
&   mass_psd, mass_mnd, mass_ad, mass_rhod, mass_vxd, mass_vyd, mass_vzd&
&   , mass_nxd, mass_nyd, mass_nzd
    real(kind=realtype) :: area, cellarea, overcellarea
    real(kind=realtype) :: aread, cellaread, overcellaread
    real(kind=realtype) :: mredim
    real(kind=realtype) :: mredimd
    real(kind=realtype) :: internalflowfact, inflowfact, xc, yc, zc, mx&
&   , my, mz
    real(kind=realtype) :: xcd, ycd, zcd, mxd, myd, mzd
    logical :: triisvalid
    intrinsic sqrt
    intrinsic size
    intrinsic present
    real(kind=realtype) :: arg1
    real(kind=realtype) :: arg1d
    real(kind=realtype) :: result1
    real(kind=realtype) :: result1d
    if (pref*rhoref .eq. 0.0_8) then
      mredimd = 0.0_8
    else
      mredimd = (prefd*rhoref+pref*rhorefd)/(2.0*sqrt(pref*rhoref))
    end if
    mredim = sqrt(pref*rhoref)
    fp = zero
    mp = zero
    fmom = zero
    mmom = zero
    massflowrate = zero
    area = zero
    mass_ptot = zero
    mass_ttot = zero
    mass_ps = zero
    mass_mn = zero
    mass_a = zero
    mass_rho = zero
    mass_vx = zero
    mass_vy = zero
    mass_vz = zero
    mass_nx = zero
    mass_ny = zero
    mass_nz = zero
    refpointd = 0.0_8
    refpointd(1) = lref*pointrefd(1)
    refpoint(1) = lref*pointref(1)
    refpointd(2) = lref*pointrefd(2)
    refpoint(2) = lref*pointref(2)
    refpointd(3) = lref*pointrefd(3)
    refpoint(3) = lref*pointref(3)
    internalflowfact = one
    if (flowtype .eq. internalflow) internalflowfact = -one
    inflowfact = one
    if (isinflow) then
      inflowfact = -one
      mass_ptotd = 0.0_8
      aread = 0.0_8
      mmomd = 0.0_8
      mass_vxd = 0.0_8
      mass_vyd = 0.0_8
      mass_ad = 0.0_8
      mass_vzd = 0.0_8
      normd = 0.0_8
      ptotd = 0.0_8
      mass_psd = 0.0_8
      mass_mnd = 0.0_8
      sfacecoordrefd = 0.0_8
      mass_rhod = 0.0_8
      mass_ttotd = 0.0_8
      mass_nxd = 0.0_8
      mass_nyd = 0.0_8
      fpd = 0.0_8
      mass_nzd = 0.0_8
      fmomd = 0.0_8
      ttotd = 0.0_8
      massflowrated = 0.0_8
      mpd = 0.0_8
    else
      mass_ptotd = 0.0_8
      aread = 0.0_8
      mmomd = 0.0_8
      mass_vxd = 0.0_8
      mass_vyd = 0.0_8
      mass_ad = 0.0_8
      mass_vzd = 0.0_8
      normd = 0.0_8
      ptotd = 0.0_8
      mass_psd = 0.0_8
      mass_mnd = 0.0_8
      sfacecoordrefd = 0.0_8
      mass_rhod = 0.0_8
      mass_ttotd = 0.0_8
      mass_nxd = 0.0_8
      mass_nyd = 0.0_8
      fpd = 0.0_8
      mass_nzd = 0.0_8
      fmomd = 0.0_8
      ttotd = 0.0_8
      massflowrated = 0.0_8
      mpd = 0.0_8
    end if
    do i=1,size(conn, 2)
      if (faminlist(fams(i), famlist)) then
! if the ptvalid list is given, check if we should integrate
! this triangle.
        triisvalid = .true.
        if (present(ptvalid)) then
! check if each of the three nodes are valid
          if (((ptvalid(conn(1, i)) .eqv. .false.) .or. (ptvalid(conn(2&
&             , i)) .eqv. .false.)) .or. (ptvalid(conn(3, i)) .eqv. &
&             .false.)) triisvalid = .false.
        end if
        if (triisvalid) then
! compute the averaged values for this triangle
          vxm = zero
          vym = zero
          vzm = zero
          rhom = zero
          pm = zero
          mnm = zero
          gammam = zero
          sf = zero
          vxmd = 0.0_8
          vymd = 0.0_8
          sfd = 0.0_8
          rhomd = 0.0_8
          gammamd = 0.0_8
          pmd = 0.0_8
          vzmd = 0.0_8
          do j=1,3
            rhomd = rhomd + varsd(conn(j, i), irho)
            rhom = rhom + vars(conn(j, i), irho)
            vxmd = vxmd + varsd(conn(j, i), ivx)
            vxm = vxm + vars(conn(j, i), ivx)
            vymd = vymd + varsd(conn(j, i), ivy)
            vym = vym + vars(conn(j, i), ivy)
            vzmd = vzmd + varsd(conn(j, i), ivz)
            vzm = vzm + vars(conn(j, i), ivz)
            pmd = pmd + varsd(conn(j, i), irhoe)
            pm = pm + vars(conn(j, i), irhoe)
            gammamd = gammamd + varsd(conn(j, i), izippflowgamma)
            gammam = gammam + vars(conn(j, i), izippflowgamma)
            sfd = sfd + varsd(conn(j, i), izippflowsface)
            sf = sf + vars(conn(j, i), izippflowsface)
          end do
! divide by 3 due to the summation above:
          rhomd = third*rhomd
          rhom = third*rhom
          vxmd = third*vxmd
          vxm = third*vxm
          vymd = third*vymd
          vym = third*vym
          vzmd = third*vzmd
          vzm = third*vzm
          pmd = third*pmd
          pm = third*pm
          gammamd = third*gammamd
          gammam = third*gammam
          sfd = third*sfd
          sf = third*sf
! get the nodes of triangle.
          x1d = varsd(conn(1, i), izippflowx:izippflowz)
          x1 = vars(conn(1, i), izippflowx:izippflowz)
          x2d = varsd(conn(2, i), izippflowx:izippflowz)
          x2 = vars(conn(2, i), izippflowx:izippflowz)
          x3d = varsd(conn(3, i), izippflowx:izippflowz)
          x3 = vars(conn(3, i), izippflowx:izippflowz)
          call cross_prod_d(x2 - x1, x2d - x1d, x3 - x1, x3d - x1d, norm&
&                     , normd)
          ssd = half*normd
          ss = half*norm
          call computeptot_d(rhom, rhomd, vxm, vxmd, vym, vymd, vzm, &
&                      vzmd, pm, pmd, ptot, ptotd)
          call computettot_d(rhom, rhomd, vxm, vxmd, vym, vymd, vzm, &
&                      vzmd, pm, pmd, ttot, ttotd)
          vnmd = vxmd*ss(1) + vxm*ssd(1) + vymd*ss(2) + vym*ssd(2) + &
&           vzmd*ss(3) + vzm*ssd(3) - sfd
          vnm = vxm*ss(1) + vym*ss(2) + vzm*ss(3) - sf
          arg1d = 2*vxm*vxmd + 2*vym*vymd + 2*vzm*vzmd
          arg1 = vxm**2 + vym**2 + vzm**2
          if (arg1 .eq. 0.0_8) then
            result1d = 0.0_8
          else
            result1d = arg1d/(2.0*sqrt(arg1))
          end if
          result1 = sqrt(arg1)
          vmagd = result1d - sfd
          vmag = result1 - sf
          arg1d = ((gammamd*pm+gammam*pmd)*rhom-gammam*pm*rhomd)/rhom**2
          arg1 = gammam*pm/rhom
          if (arg1 .eq. 0.0_8) then
            amd = 0.0_8
          else
            amd = arg1d/(2.0*sqrt(arg1))
          end if
          am = sqrt(arg1)
          arg1d = ((gammamd*pm+gammam*pmd)*rhom-gammam*pm*rhomd)/rhom**2
          arg1 = gammam*pm/rhom
          if (arg1 .eq. 0.0_8) then
            result1d = 0.0_8
          else
            result1d = arg1d/(2.0*sqrt(arg1))
          end if
          result1 = sqrt(arg1)
          mnmd = (vmagd*result1-vmag*result1d)/result1**2
          mnm = vmag/result1
          arg1d = 2*ss(1)*ssd(1) + 2*ss(2)*ssd(2) + 2*ss(3)*ssd(3)
          arg1 = ss(1)**2 + ss(2)**2 + ss(3)**2
          if (arg1 .eq. 0.0_8) then
            cellaread = 0.0_8
          else
            cellaread = arg1d/(2.0*sqrt(arg1))
          end if
          cellarea = sqrt(arg1)
          aread = aread + cellaread
          area = area + cellarea
          overcellaread = (-cellaread)/cellarea**2
          overcellarea = 1/cellarea
          massflowratelocald = (rhomd*vnm+rhom*vnmd)*mredim + rhom*vnm*&
&           mredimd
          massflowratelocal = rhom*vnm*mredim
          massflowrated = massflowrated + massflowratelocald
          massflowrate = massflowrate + massflowratelocal
          pmd = pmd*pref + pm*prefd
          pm = pm*pref
          mass_ptotd = mass_ptotd + (ptotd*massflowratelocal+ptot*&
&           massflowratelocald)*pref + ptot*massflowratelocal*prefd
          mass_ptot = mass_ptot + ptot*massflowratelocal*pref
          mass_ttotd = mass_ttotd + (ttotd*massflowratelocal+ttot*&
&           massflowratelocald)*tref + ttot*massflowratelocal*trefd
          mass_ttot = mass_ttot + ttot*massflowratelocal*tref
          mass_rhod = mass_rhod + (rhomd*massflowratelocal+rhom*&
&           massflowratelocald)*rhoref + rhom*massflowratelocal*rhorefd
          mass_rho = mass_rho + rhom*massflowratelocal*rhoref
          mass_ad = mass_ad + uref*(amd*massflowratelocal+am*&
&           massflowratelocald)
          mass_a = mass_a + am*massflowratelocal*uref
          mass_psd = mass_psd + pmd*massflowratelocal + pm*&
&           massflowratelocald
          mass_ps = mass_ps + pm*massflowratelocal
          mass_mnd = mass_mnd + mnmd*massflowratelocal + mnm*&
&           massflowratelocald
          mass_mn = mass_mn + mnm*massflowratelocal
          sfacecoordrefd(1) = (sfd*overcellarea+sf*overcellaread)*ss(1) &
&           + sf*overcellarea*ssd(1)
          sfacecoordref(1) = sf*ss(1)*overcellarea
          sfacecoordrefd(2) = (sfd*overcellarea+sf*overcellaread)*ss(2) &
&           + sf*overcellarea*ssd(2)
          sfacecoordref(2) = sf*ss(2)*overcellarea
          sfacecoordrefd(3) = (sfd*overcellarea+sf*overcellaread)*ss(3) &
&           + sf*overcellarea*ssd(3)
          sfacecoordref(3) = sf*ss(3)*overcellarea
          mass_vxd = mass_vxd + (uref*vxmd-sfacecoordrefd(1))*&
&           massflowratelocal + (vxm*uref-sfacecoordref(1))*&
&           massflowratelocald
          mass_vx = mass_vx + (vxm*uref-sfacecoordref(1))*&
&           massflowratelocal
          mass_vyd = mass_vyd + (uref*vymd-sfacecoordrefd(2))*&
&           massflowratelocal + (vym*uref-sfacecoordref(2))*&
&           massflowratelocald
          mass_vy = mass_vy + (vym*uref-sfacecoordref(2))*&
&           massflowratelocal
          mass_vzd = mass_vzd + (uref*vzmd-sfacecoordrefd(3))*&
&           massflowratelocal + (vzm*uref-sfacecoordref(3))*&
&           massflowratelocald
          mass_vz = mass_vz + (vzm*uref-sfacecoordref(3))*&
&           massflowratelocal
          mass_nxd = mass_nxd + ssd(1)*overcellarea*massflowratelocal + &
&           ss(1)*(overcellaread*massflowratelocal+overcellarea*&
&           massflowratelocald)
          mass_nx = mass_nx + ss(1)*overcellarea*massflowratelocal
          mass_nyd = mass_nyd + ssd(2)*overcellarea*massflowratelocal + &
&           ss(2)*(overcellaread*massflowratelocal+overcellarea*&
&           massflowratelocald)
          mass_ny = mass_ny + ss(2)*overcellarea*massflowratelocal
          mass_nzd = mass_nzd + ssd(3)*overcellarea*massflowratelocal + &
&           ss(3)*(overcellaread*massflowratelocal+overcellarea*&
&           massflowratelocald)
          mass_nz = mass_nz + ss(3)*overcellarea*massflowratelocal
! compute the average cell center.
          xc = zero
          yc = zero
          zc = zero
          xcd = 0.0_8
          ycd = 0.0_8
          zcd = 0.0_8
          do j=1,3
            xcd = xcd + varsd(conn(1, i), izippflowx)
            xc = xc + vars(conn(1, i), izippflowx)
            ycd = ycd + varsd(conn(2, i), izippflowy)
            yc = yc + vars(conn(2, i), izippflowy)
            zcd = zcd + varsd(conn(3, i), izippflowz)
            zc = zc + vars(conn(3, i), izippflowz)
          end do
! finish average for cell center
          xcd = third*xcd
          xc = third*xc
          ycd = third*ycd
          yc = third*yc
          zcd = third*zcd
          zc = third*zc
          xcd = xcd - refpointd(1)
          xc = xc - refpoint(1)
          ycd = ycd - refpointd(2)
          yc = yc - refpoint(2)
          zcd = zcd - refpointd(3)
          zc = zc - refpoint(3)
          pmd = -(pmd-pinf*prefd)
          pm = -(pm-pinf*pref)
          fxd = pmd*ss(1) + pm*ssd(1)
          fx = pm*ss(1)
          fyd = pmd*ss(2) + pm*ssd(2)
          fy = pm*ss(2)
          fzd = pmd*ss(3) + pm*ssd(3)
          fz = pm*ss(3)
! update the pressure force and moment coefficients.
          fpd(1) = fpd(1) + fxd
          fp(1) = fp(1) + fx
          fpd(2) = fpd(2) + fyd
          fp(2) = fp(2) + fy
          fpd(3) = fpd(3) + fzd
          fp(3) = fp(3) + fz
          mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
          mx = yc*fz - zc*fy
          myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
          my = zc*fx - xc*fz
          mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
          mz = xc*fy - yc*fx
          mpd(1) = mpd(1) + mxd
          mp(1) = mp(1) + mx
          mpd(2) = mpd(2) + myd
          mp(2) = mp(2) + my
          mpd(3) = mpd(3) + mzd
          mp(3) = mp(3) + mz
! momentum forces
! get unit normal vector.
          ssd = (ssd*cellarea-ss*cellaread)/cellarea**2
          ss = ss/cellarea
          massflowratelocald = internalflowfact*inflowfact*(&
&           massflowratelocald*timeref-massflowratelocal*timerefd)/&
&           timeref**2
          massflowratelocal = massflowratelocal/timeref*internalflowfact&
&           *inflowfact
          fxd = (massflowratelocald*vxm+massflowratelocal*vxmd)*ss(1) + &
&           massflowratelocal*vxm*ssd(1)
          fx = massflowratelocal*ss(1)*vxm
          fyd = (massflowratelocald*vym+massflowratelocal*vymd)*ss(2) + &
&           massflowratelocal*vym*ssd(2)
          fy = massflowratelocal*ss(2)*vym
          fzd = (massflowratelocald*vzm+massflowratelocal*vzmd)*ss(3) + &
&           massflowratelocal*vzm*ssd(3)
          fz = massflowratelocal*ss(3)*vzm
          fmomd(1) = fmomd(1) - fxd
          fmom(1) = fmom(1) - fx
          fmomd(2) = fmomd(2) - fyd
          fmom(2) = fmom(2) - fy
          fmomd(3) = fmomd(3) - fzd
          fmom(3) = fmom(3) - fz
          mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
          mx = yc*fz - zc*fy
          myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
          my = zc*fx - xc*fz
          mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
          mz = xc*fy - yc*fx
          mmomd(1) = mmomd(1) + mxd
          mmom(1) = mmom(1) + mx
          mmomd(2) = mmomd(2) + myd
          mmom(2) = mmom(2) + my
          mmomd(3) = mmomd(3) + mzd
          mmom(3) = mmom(3) + mz
        end if
      end if
    end do
! increment the local values array with what we computed here
    localvaluesd(imassflow) = localvaluesd(imassflow) + massflowrated
    localvalues(imassflow) = localvalues(imassflow) + massflowrate
    localvaluesd(iarea) = localvaluesd(iarea) + aread
    localvalues(iarea) = localvalues(iarea) + area
    localvaluesd(imassrho) = localvaluesd(imassrho) + mass_rhod
    localvalues(imassrho) = localvalues(imassrho) + mass_rho
    localvaluesd(imassa) = localvaluesd(imassa) + mass_ad
    localvalues(imassa) = localvalues(imassa) + mass_a
    localvaluesd(imassptot) = localvaluesd(imassptot) + mass_ptotd
    localvalues(imassptot) = localvalues(imassptot) + mass_ptot
    localvaluesd(imassttot) = localvaluesd(imassttot) + mass_ttotd
    localvalues(imassttot) = localvalues(imassttot) + mass_ttot
    localvaluesd(imassps) = localvaluesd(imassps) + mass_psd
    localvalues(imassps) = localvalues(imassps) + mass_ps
    localvaluesd(imassmn) = localvaluesd(imassmn) + mass_mnd
    localvalues(imassmn) = localvalues(imassmn) + mass_mn
    localvaluesd(ifp:ifp+2) = localvaluesd(ifp:ifp+2) + fpd
    localvalues(ifp:ifp+2) = localvalues(ifp:ifp+2) + fp
    localvaluesd(iflowfm:iflowfm+2) = localvaluesd(iflowfm:iflowfm+2) + &
&     fmomd
    localvalues(iflowfm:iflowfm+2) = localvalues(iflowfm:iflowfm+2) + &
&     fmom
    localvaluesd(iflowmp:iflowmp+2) = localvaluesd(iflowmp:iflowmp+2) + &
&     mpd
    localvalues(iflowmp:iflowmp+2) = localvalues(iflowmp:iflowmp+2) + mp
    localvaluesd(iflowmm:iflowmm+2) = localvaluesd(iflowmm:iflowmm+2) + &
&     mmomd
    localvalues(iflowmm:iflowmm+2) = localvalues(iflowmm:iflowmm+2) + &
&     mmom
    localvaluesd(imassvx) = localvaluesd(imassvx) + mass_vxd
    localvalues(imassvx) = localvalues(imassvx) + mass_vx
    localvaluesd(imassvy) = localvaluesd(imassvy) + mass_vyd
    localvalues(imassvy) = localvalues(imassvy) + mass_vy
    localvaluesd(imassvz) = localvaluesd(imassvz) + mass_vzd
    localvalues(imassvz) = localvalues(imassvz) + mass_vz
    localvaluesd(imassnx) = localvaluesd(imassnx) + mass_nxd
    localvalues(imassnx) = localvalues(imassnx) + mass_nx
    localvaluesd(imassny) = localvaluesd(imassny) + mass_nyd
    localvalues(imassny) = localvalues(imassny) + mass_ny
    localvaluesd(imassnz) = localvaluesd(imassnz) + mass_nzd
    localvalues(imassnz) = localvalues(imassnz) + mass_nz
  end subroutine flowintegrationzipper_d
  subroutine flowintegrationzipper(isinflow, conn, fams, vars, &
&   localvalues, famlist, sps, ptvalid)
! integrate over the trianges for the inflow/outflow conditions.
    use constants
    use blockpointers, only : bctype
    use sorting, only : faminlist
    use flowvarrefstate, only : pref, pinf, rhoref, pref, timeref, &
&   lref, tref, rgas, uref, uinf, rhoinf
    use inputphysics, only : pointref, flowtype
    use flowutils_d, only : computeptot, computettot
    use surfacefamilies, only : familyexchange, bcfamexchange
    use utils_d, only : mynorm2, cross_prod
    implicit none
! input/output variables
    logical, intent(in) :: isinflow
    integer(kind=inttype), dimension(:, :), intent(in) :: conn
    integer(kind=inttype), dimension(:), intent(in) :: fams
    real(kind=realtype), dimension(:, :), intent(in) :: vars
    real(kind=realtype), dimension(nlocalvalues), intent(inout) :: &
&   localvalues
    integer(kind=inttype), dimension(:), intent(in) :: famlist
    integer(kind=inttype), intent(in) :: sps
    logical(kind=inttype), dimension(:), optional, intent(in) :: ptvalid
! working variables
    integer(kind=inttype) :: i, j
    real(kind=realtype) :: sf, vmag, vnm, vxm, vym, vzm, fx, fy, fz, u, &
&   v, w, vnmfreestreamref
    real(kind=realtype), dimension(3) :: fp, mp, fmom, mmom, refpoint, &
&   ss, x1, x2, x3, norm, sfacecoordref
    real(kind=realtype) :: pm, ptot, ttot, rhom, gammam, mnm, &
&   massflowratelocal, am
    real(kind=realtype) :: massflowrate, mass_ptot, mass_ttot, mass_ps, &
&   mass_mn, mass_a, mass_rho, mass_vx, mass_vy, mass_vz, mass_nx, &
&   mass_ny, mass_nz
    real(kind=realtype) :: area, cellarea, overcellarea
    real(kind=realtype) :: mredim
    real(kind=realtype) :: internalflowfact, inflowfact, xc, yc, zc, mx&
&   , my, mz
    logical :: triisvalid
    intrinsic sqrt
    intrinsic size
    intrinsic present
    real(kind=realtype) :: arg1
    real(kind=realtype) :: result1
    mredim = sqrt(pref*rhoref)
    fp = zero
    mp = zero
    fmom = zero
    mmom = zero
    massflowrate = zero
    area = zero
    mass_ptot = zero
    mass_ttot = zero
    mass_ps = zero
    mass_mn = zero
    mass_a = zero
    mass_rho = zero
    mass_vx = zero
    mass_vy = zero
    mass_vz = zero
    mass_nx = zero
    mass_ny = zero
    mass_nz = zero
    refpoint(1) = lref*pointref(1)
    refpoint(2) = lref*pointref(2)
    refpoint(3) = lref*pointref(3)
    internalflowfact = one
    if (flowtype .eq. internalflow) internalflowfact = -one
    inflowfact = one
    if (isinflow) inflowfact = -one
    do i=1,size(conn, 2)
      if (faminlist(fams(i), famlist)) then
! if the ptvalid list is given, check if we should integrate
! this triangle.
        triisvalid = .true.
        if (present(ptvalid)) then
! check if each of the three nodes are valid
          if (((ptvalid(conn(1, i)) .eqv. .false.) .or. (ptvalid(conn(2&
&             , i)) .eqv. .false.)) .or. (ptvalid(conn(3, i)) .eqv. &
&             .false.)) triisvalid = .false.
        end if
        if (triisvalid) then
! compute the averaged values for this triangle
          vxm = zero
          vym = zero
          vzm = zero
          rhom = zero
          pm = zero
          mnm = zero
          gammam = zero
          sf = zero
          do j=1,3
            rhom = rhom + vars(conn(j, i), irho)
            vxm = vxm + vars(conn(j, i), ivx)
            vym = vym + vars(conn(j, i), ivy)
            vzm = vzm + vars(conn(j, i), ivz)
            pm = pm + vars(conn(j, i), irhoe)
            gammam = gammam + vars(conn(j, i), izippflowgamma)
            sf = sf + vars(conn(j, i), izippflowsface)
          end do
! divide by 3 due to the summation above:
          rhom = third*rhom
          vxm = third*vxm
          vym = third*vym
          vzm = third*vzm
          pm = third*pm
          gammam = third*gammam
          sf = third*sf
! get the nodes of triangle.
          x1 = vars(conn(1, i), izippflowx:izippflowz)
          x2 = vars(conn(2, i), izippflowx:izippflowz)
          x3 = vars(conn(3, i), izippflowx:izippflowz)
          call cross_prod(x2 - x1, x3 - x1, norm)
          ss = half*norm
          call computeptot(rhom, vxm, vym, vzm, pm, ptot)
          call computettot(rhom, vxm, vym, vzm, pm, ttot)
          vnm = vxm*ss(1) + vym*ss(2) + vzm*ss(3) - sf
          arg1 = vxm**2 + vym**2 + vzm**2
          result1 = sqrt(arg1)
          vmag = result1 - sf
          arg1 = gammam*pm/rhom
          am = sqrt(arg1)
          arg1 = gammam*pm/rhom
          result1 = sqrt(arg1)
          mnm = vmag/result1
          arg1 = ss(1)**2 + ss(2)**2 + ss(3)**2
          cellarea = sqrt(arg1)
          area = area + cellarea
          overcellarea = 1/cellarea
          massflowratelocal = rhom*vnm*mredim
          massflowrate = massflowrate + massflowratelocal
          pm = pm*pref
          mass_ptot = mass_ptot + ptot*massflowratelocal*pref
          mass_ttot = mass_ttot + ttot*massflowratelocal*tref
          mass_rho = mass_rho + rhom*massflowratelocal*rhoref
          mass_a = mass_a + am*massflowratelocal*uref
          mass_ps = mass_ps + pm*massflowratelocal
          mass_mn = mass_mn + mnm*massflowratelocal
          sfacecoordref(1) = sf*ss(1)*overcellarea
          sfacecoordref(2) = sf*ss(2)*overcellarea
          sfacecoordref(3) = sf*ss(3)*overcellarea
          mass_vx = mass_vx + (vxm*uref-sfacecoordref(1))*&
&           massflowratelocal
          mass_vy = mass_vy + (vym*uref-sfacecoordref(2))*&
&           massflowratelocal
          mass_vz = mass_vz + (vzm*uref-sfacecoordref(3))*&
&           massflowratelocal
          mass_nx = mass_nx + ss(1)*overcellarea*massflowratelocal
          mass_ny = mass_ny + ss(2)*overcellarea*massflowratelocal
          mass_nz = mass_nz + ss(3)*overcellarea*massflowratelocal
! compute the average cell center.
          xc = zero
          yc = zero
          zc = zero
          do j=1,3
            xc = xc + vars(conn(1, i), izippflowx)
            yc = yc + vars(conn(2, i), izippflowy)
            zc = zc + vars(conn(3, i), izippflowz)
          end do
! finish average for cell center
          xc = third*xc
          yc = third*yc
          zc = third*zc
          xc = xc - refpoint(1)
          yc = yc - refpoint(2)
          zc = zc - refpoint(3)
          pm = -(pm-pinf*pref)
          fx = pm*ss(1)
          fy = pm*ss(2)
          fz = pm*ss(3)
! update the pressure force and moment coefficients.
          fp(1) = fp(1) + fx
          fp(2) = fp(2) + fy
          fp(3) = fp(3) + fz
          mx = yc*fz - zc*fy
          my = zc*fx - xc*fz
          mz = xc*fy - yc*fx
          mp(1) = mp(1) + mx
          mp(2) = mp(2) + my
          mp(3) = mp(3) + mz
! momentum forces
! get unit normal vector.
          ss = ss/cellarea
          massflowratelocal = massflowratelocal/timeref*internalflowfact&
&           *inflowfact
          fx = massflowratelocal*ss(1)*vxm
          fy = massflowratelocal*ss(2)*vym
          fz = massflowratelocal*ss(3)*vzm
          fmom(1) = fmom(1) - fx
          fmom(2) = fmom(2) - fy
          fmom(3) = fmom(3) - fz
          mx = yc*fz - zc*fy
          my = zc*fx - xc*fz
          mz = xc*fy - yc*fx
          mmom(1) = mmom(1) + mx
          mmom(2) = mmom(2) + my
          mmom(3) = mmom(3) + mz
        end if
      end if
    end do
! increment the local values array with what we computed here
    localvalues(imassflow) = localvalues(imassflow) + massflowrate
    localvalues(iarea) = localvalues(iarea) + area
    localvalues(imassrho) = localvalues(imassrho) + mass_rho
    localvalues(imassa) = localvalues(imassa) + mass_a
    localvalues(imassptot) = localvalues(imassptot) + mass_ptot
    localvalues(imassttot) = localvalues(imassttot) + mass_ttot
    localvalues(imassps) = localvalues(imassps) + mass_ps
    localvalues(imassmn) = localvalues(imassmn) + mass_mn
    localvalues(ifp:ifp+2) = localvalues(ifp:ifp+2) + fp
    localvalues(iflowfm:iflowfm+2) = localvalues(iflowfm:iflowfm+2) + &
&     fmom
    localvalues(iflowmp:iflowmp+2) = localvalues(iflowmp:iflowmp+2) + mp
    localvalues(iflowmm:iflowmm+2) = localvalues(iflowmm:iflowmm+2) + &
&     mmom
    localvalues(imassvx) = localvalues(imassvx) + mass_vx
    localvalues(imassvy) = localvalues(imassvy) + mass_vy
    localvalues(imassvz) = localvalues(imassvz) + mass_vz
    localvalues(imassnx) = localvalues(imassnx) + mass_nx
    localvalues(imassny) = localvalues(imassny) + mass_ny
    localvalues(imassnz) = localvalues(imassnz) + mass_nz
  end subroutine flowintegrationzipper
!  differentiation of wallintegrationzipper in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: localvalues
!   with respect to varying inputs: pointref vars localvalues
!   rw status of diff variables: pointref:in vars:in localvalues:in-out
  subroutine wallintegrationzipper_d(conn, fams, vars, varsd, &
&   localvalues, localvaluesd, famlist, sps)
    use constants
    use sorting, only : faminlist
    use flowvarrefstate, only : lref
    use inputphysics, only : pointref, pointrefd
    use utils_d, only : mynorm2, mynorm2_d, cross_prod, cross_prod_d
    implicit none
! input/output
    integer(kind=inttype), dimension(:, :), intent(in) :: conn
    integer(kind=inttype), dimension(:), intent(in) :: fams
    real(kind=realtype), dimension(:, :), intent(in) :: vars
    real(kind=realtype), dimension(:, :), intent(in) :: varsd
    real(kind=realtype), intent(inout) :: localvalues(nlocalvalues)
    real(kind=realtype), intent(inout) :: localvaluesd(nlocalvalues)
    integer(kind=inttype), dimension(:), intent(in) :: famlist
    integer(kind=inttype), intent(in) :: sps
! working
    real(kind=realtype), dimension(3) :: fp, fv, mp, mv
    real(kind=realtype), dimension(3) :: fpd, fvd, mpd, mvd
    integer(kind=inttype) :: i, j
    real(kind=realtype), dimension(3) :: ss, norm, refpoint
    real(kind=realtype), dimension(3) :: ssd, normd, refpointd
    real(kind=realtype), dimension(3) :: p1, p2, p3, v1, v2, v3, x1, x2&
&   , x3
    real(kind=realtype), dimension(3) :: p1d, p2d, p3d, v1d, v2d, v3d, &
&   x1d, x2d, x3d
    real(kind=realtype) :: fact, triarea, fx, fy, fz, mx, my, mz, xc, yc&
&   , zc
    real(kind=realtype) :: triaread, fxd, fyd, fzd, mxd, myd, mzd, xcd, &
&   ycd, zcd
    intrinsic size
    real(kind=realtype) :: result1
    real(kind=realtype) :: result1d
! determine the reference point for the moment computation in
! meters.
    refpointd = 0.0_8
    refpointd(1) = lref*pointrefd(1)
    refpoint(1) = lref*pointref(1)
    refpointd(2) = lref*pointrefd(2)
    refpoint(2) = lref*pointref(2)
    refpointd(3) = lref*pointrefd(3)
    refpoint(3) = lref*pointref(3)
    fp = zero
    fv = zero
    mp = zero
    mv = zero
    normd = 0.0_8
    fpd = 0.0_8
    fvd = 0.0_8
    mpd = 0.0_8
    mvd = 0.0_8
    do i=1,size(conn, 2)
      if (faminlist(fams(i), famlist)) then
! get the nodes of triangle.
        x1d = varsd(conn(1, i), izippwallx:izippwallz)
        x1 = vars(conn(1, i), izippwallx:izippwallz)
        x2d = varsd(conn(2, i), izippwallx:izippwallz)
        x2 = vars(conn(2, i), izippwallx:izippwallz)
        x3d = varsd(conn(3, i), izippwallx:izippwallz)
        x3 = vars(conn(3, i), izippwallx:izippwallz)
        call cross_prod_d(x2 - x1, x2d - x1d, x3 - x1, x3d - x1d, norm, &
&                   normd)
        ssd = half*normd
        ss = half*norm
! the third here is to account for the summation of p1, p2
! and p3
        result1d = mynorm2_d(ss, ssd, result1)
        triaread = third*result1d
        triarea = result1*third
! compute the average cell center.
        xcd = third*(x1d(1)+x2d(1)+x3d(1))
        xc = third*(x1(1)+x2(1)+x3(1))
        ycd = third*(x1d(2)+x2d(2)+x3d(2))
        yc = third*(x1(2)+x2(2)+x3(2))
        zcd = third*(x1d(3)+x2d(3)+x3d(3))
        zc = third*(x1(3)+x2(3)+x3(3))
        xcd = xcd - refpointd(1)
        xc = xc - refpoint(1)
        ycd = ycd - refpointd(2)
        yc = yc - refpoint(2)
        zcd = zcd - refpointd(3)
        zc = zc - refpoint(3)
! update the pressure force and moment coefficients.
        p1d = varsd(conn(1, i), izippwalltpx:izippwalltpz)
        p1 = vars(conn(1, i), izippwalltpx:izippwalltpz)
        p2d = varsd(conn(2, i), izippwalltpx:izippwalltpz)
        p2 = vars(conn(2, i), izippwalltpx:izippwalltpz)
        p3d = varsd(conn(3, i), izippwalltpx:izippwalltpz)
        p3 = vars(conn(3, i), izippwalltpx:izippwalltpz)
        fxd = (p1d(1)+p2d(1)+p3d(1))*triarea + (p1(1)+p2(1)+p3(1))*&
&         triaread
        fx = (p1(1)+p2(1)+p3(1))*triarea
        fyd = (p1d(2)+p2d(2)+p3d(2))*triarea + (p1(2)+p2(2)+p3(2))*&
&         triaread
        fy = (p1(2)+p2(2)+p3(2))*triarea
        fzd = (p1d(3)+p2d(3)+p3d(3))*triarea + (p1(3)+p2(3)+p3(3))*&
&         triaread
        fz = (p1(3)+p2(3)+p3(3))*triarea
        fpd(1) = fpd(1) + fxd
        fp(1) = fp(1) + fx
        fpd(2) = fpd(2) + fyd
        fp(2) = fp(2) + fy
        fpd(3) = fpd(3) + fzd
        fp(3) = fp(3) + fz
        mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
        mx = yc*fz - zc*fy
        myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
        my = zc*fx - xc*fz
        mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
        mz = xc*fy - yc*fx
        mpd(1) = mpd(1) + mxd
        mp(1) = mp(1) + mx
        mpd(2) = mpd(2) + myd
        mp(2) = mp(2) + my
        mpd(3) = mpd(3) + mzd
        mp(3) = mp(3) + mz
! update the viscous force and moment coefficients
        v1d = varsd(conn(1, i), izippwalltvx:izippwalltvz)
        v1 = vars(conn(1, i), izippwalltvx:izippwalltvz)
        v2d = varsd(conn(2, i), izippwalltvx:izippwalltvz)
        v2 = vars(conn(2, i), izippwalltvx:izippwalltvz)
        v3d = varsd(conn(3, i), izippwalltvx:izippwalltvz)
        v3 = vars(conn(3, i), izippwalltvx:izippwalltvz)
        fxd = (v1d(1)+v2d(1)+v3d(1))*triarea + (v1(1)+v2(1)+v3(1))*&
&         triaread
        fx = (v1(1)+v2(1)+v3(1))*triarea
        fyd = (v1d(2)+v2d(2)+v3d(2))*triarea + (v1(2)+v2(2)+v3(2))*&
&         triaread
        fy = (v1(2)+v2(2)+v3(2))*triarea
        fzd = (v1d(3)+v2d(3)+v3d(3))*triarea + (v1(3)+v2(3)+v3(3))*&
&         triaread
        fz = (v1(3)+v2(3)+v3(3))*triarea
! note: momentum forces have opposite sign to pressure forces
        fvd(1) = fvd(1) + fxd
        fv(1) = fv(1) + fx
        fvd(2) = fvd(2) + fyd
        fv(2) = fv(2) + fy
        fvd(3) = fvd(3) + fzd
        fv(3) = fv(3) + fz
        mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
        mx = yc*fz - zc*fy
        myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
        my = zc*fx - xc*fz
        mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
        mz = xc*fy - yc*fx
        mvd(1) = mvd(1) + mxd
        mv(1) = mv(1) + mx
        mvd(2) = mvd(2) + myd
        mv(2) = mv(2) + my
        mvd(3) = mvd(3) + mzd
        mv(3) = mv(3) + mz
      end if
    end do
! increment into the local vector
    localvaluesd(ifp:ifp+2) = localvaluesd(ifp:ifp+2) + fpd
    localvalues(ifp:ifp+2) = localvalues(ifp:ifp+2) + fp
    localvaluesd(ifv:ifv+2) = localvaluesd(ifv:ifv+2) + fvd
    localvalues(ifv:ifv+2) = localvalues(ifv:ifv+2) + fv
    localvaluesd(imp:imp+2) = localvaluesd(imp:imp+2) + mpd
    localvalues(imp:imp+2) = localvalues(imp:imp+2) + mp
    localvaluesd(imv:imv+2) = localvaluesd(imv:imv+2) + mvd
    localvalues(imv:imv+2) = localvalues(imv:imv+2) + mv
  end subroutine wallintegrationzipper_d
  subroutine wallintegrationzipper(conn, fams, vars, localvalues, &
&   famlist, sps)
    use constants
    use sorting, only : faminlist
    use flowvarrefstate, only : lref
    use inputphysics, only : pointref
    use utils_d, only : mynorm2, cross_prod
    implicit none
! input/output
    integer(kind=inttype), dimension(:, :), intent(in) :: conn
    integer(kind=inttype), dimension(:), intent(in) :: fams
    real(kind=realtype), dimension(:, :), intent(in) :: vars
    real(kind=realtype), intent(inout) :: localvalues(nlocalvalues)
    integer(kind=inttype), dimension(:), intent(in) :: famlist
    integer(kind=inttype), intent(in) :: sps
! working
    real(kind=realtype), dimension(3) :: fp, fv, mp, mv
    integer(kind=inttype) :: i, j
    real(kind=realtype), dimension(3) :: ss, norm, refpoint
    real(kind=realtype), dimension(3) :: p1, p2, p3, v1, v2, v3, x1, x2&
&   , x3
    real(kind=realtype) :: fact, triarea, fx, fy, fz, mx, my, mz, xc, yc&
&   , zc
    intrinsic size
    real(kind=realtype) :: result1
! determine the reference point for the moment computation in
! meters.
    refpoint(1) = lref*pointref(1)
    refpoint(2) = lref*pointref(2)
    refpoint(3) = lref*pointref(3)
    fp = zero
    fv = zero
    mp = zero
    mv = zero
    do i=1,size(conn, 2)
      if (faminlist(fams(i), famlist)) then
! get the nodes of triangle.
        x1 = vars(conn(1, i), izippwallx:izippwallz)
        x2 = vars(conn(2, i), izippwallx:izippwallz)
        x3 = vars(conn(3, i), izippwallx:izippwallz)
        call cross_prod(x2 - x1, x3 - x1, norm)
        ss = half*norm
! the third here is to account for the summation of p1, p2
! and p3
        result1 = mynorm2(ss)
        triarea = result1*third
! compute the average cell center.
        xc = third*(x1(1)+x2(1)+x3(1))
        yc = third*(x1(2)+x2(2)+x3(2))
        zc = third*(x1(3)+x2(3)+x3(3))
        xc = xc - refpoint(1)
        yc = yc - refpoint(2)
        zc = zc - refpoint(3)
! update the pressure force and moment coefficients.
        p1 = vars(conn(1, i), izippwalltpx:izippwalltpz)
        p2 = vars(conn(2, i), izippwalltpx:izippwalltpz)
        p3 = vars(conn(3, i), izippwalltpx:izippwalltpz)
        fx = (p1(1)+p2(1)+p3(1))*triarea
        fy = (p1(2)+p2(2)+p3(2))*triarea
        fz = (p1(3)+p2(3)+p3(3))*triarea
        fp(1) = fp(1) + fx
        fp(2) = fp(2) + fy
        fp(3) = fp(3) + fz
        mx = yc*fz - zc*fy
        my = zc*fx - xc*fz
        mz = xc*fy - yc*fx
        mp(1) = mp(1) + mx
        mp(2) = mp(2) + my
        mp(3) = mp(3) + mz
! update the viscous force and moment coefficients
        v1 = vars(conn(1, i), izippwalltvx:izippwalltvz)
        v2 = vars(conn(2, i), izippwalltvx:izippwalltvz)
        v3 = vars(conn(3, i), izippwalltvx:izippwalltvz)
        fx = (v1(1)+v2(1)+v3(1))*triarea
        fy = (v1(2)+v2(2)+v3(2))*triarea
        fz = (v1(3)+v2(3)+v3(3))*triarea
! note: momentum forces have opposite sign to pressure forces
        fv(1) = fv(1) + fx
        fv(2) = fv(2) + fy
        fv(3) = fv(3) + fz
        mx = yc*fz - zc*fy
        my = zc*fx - xc*fz
        mz = xc*fy - yc*fx
        mv(1) = mv(1) + mx
        mv(2) = mv(2) + my
        mv(3) = mv(3) + mz
      end if
    end do
! increment into the local vector
    localvalues(ifp:ifp+2) = localvalues(ifp:ifp+2) + fp
    localvalues(ifv:ifv+2) = localvalues(ifv:ifv+2) + fv
    localvalues(imp:imp+2) = localvalues(imp:imp+2) + mp
    localvalues(imv:imv+2) = localvalues(imv:imv+2) + mv
  end subroutine wallintegrationzipper
end module zipperintegrations_d
