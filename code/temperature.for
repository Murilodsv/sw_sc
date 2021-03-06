! File VersionID:
!   $Id: temperature.for 176 2010-03-13 11:36:14Z kroes006 $
! ----------------------------------------------------------------------
      subroutine temperature(task)
! ----------------------------------------------------------------------
!     date               : november 2004
!     purpose            : calculate soil temperatures
! ----------------------------------------------------------------------
      use variables
      implicit none 

! --- global
      integer task
! --- local
      integer i,lay, ierror
      real*8  tmpold(macp),tab(mabbc*2),dummy,afgen,gmineral
      real*8  thoma(macp),thomb(macp),thomc(macp),thomf(macp)
      real*8  theave(macp),heacap(macp),heacnd(macp),heacon(macp)
      real*8  heaconbot,qhbot
      real*8  apar, dzsnw, heaconsnw, Rosnw

      character messag*200

      save
! ----------------------------------------------------------------------

      goto (1000,2000) task

1000  continue

! === initialization ===================================================

! --- determine initial temperature profile

      if (swcalt.eq.1) then
! ---   analytical solution ---
        do i = 1,numnod
          tsoil(i) = tmean + tampli*(sin(0.0172d0*(daynr-timref+91.0d0)+
     &              z(i)/ddamp)) / exp(-z(i)/ddamp)
        enddo
      else
! ---   numerical solution, use specified soil temperatures ---
        if (swinco.ne.3) then
          do i = 1, nheat
            tab(i*2) = tsoil(i)
            tab(i*2-1) = abs(zh(i))
          end do
          do i = 1, numnod
            tsoil(i) = afgen(tab,macp*2,abs(z(i)))
          end do
        end if
      endif

      if (swcalt.eq.2) then
! ---   initialize dry bulk density and volume fractions sand, clay and organic matter
        do i = 1, numnod
          lay = layer(i)
          dummy = orgmat(lay)/(1.0d0 - orgmat(lay))
          gmineral = (1.0d0 - thetas(i)) / (0.370d0 + 0.714d0*dummy)
          fquartz(i) = (psand(lay) + psilt(lay))*gmineral/2.7d0
          fclay(i) = pclay(lay)*gmineral/2.7d0
          forg(i) = dummy*gmineral/1.4d0
        end do

      endif

      return

2000  continue

! === soil temperature rate and state variables ========================

      if (swcalt .eq. 2) then
!   - numerical solution

! ---   use specified soil surface temperatures as top boundary condition
        if (swtopbhea .eq. 2) then
! ---   use specified soil surface temperatures as top boundary condition
           TeTop = afgen (temtoptab,2*mabbc,t1900+dt)
        elseif (abs(ssnow).gt.1.0d-10) then
! --- air temperature can not be used with a snow layer, calculate 
! --- temperature on soil- snow interface
           Rosnw = 170.0d0
           heaconsnw = 2.86d-6 * 864.0d0 * Rosnw**2.d0
           dzsnw = ssnow / 0.170d0
           if (heacon(1).lt.1.d-10) heacon(1) = 100.0d0
           apar = (0.5d0*heaconsnw*dz(1)) / (heacon(1)*dzsnw)
           TeTop = (Tsoil(1) + apar*Tav) / (1.d0+apar)
        else
           TeTop = Tav
        endif
!
        if (SwBotbHea.eq.1) then
! ---   no heat flow through bottom of profile assumed
           TeBot = Tsoil(Numnod)
        elseif (SwBotbHea.eq.2) then
! ---   bottom temperature is prescribed
           TeBot = afgen (tembtab,2*mabbc,t1900+dt)
        endif

! --- save old temperature profile
        do i = 1,numnod
          tmpold(i) = tsoil(i)
        enddo

! --- compute heat conductivity and capacity ---------------------------

        do i = 1,numnod
          theave(i) = 0.5d0 * (theta(i) + thetm1(i))
        enddo

! --- calculate nodal heat capacity and thermal conductivity 
        call devries(numnod,theave,thetas,heacap,heacnd,fquartz,
     &        fclay,forg)
        heacon(1) = heacnd(1)
        do i = 2,numnod
          heacon(i) = 0.5d0 * (heacnd(i) + heacnd(i-1))
        enddo

! ---   calculate new temperature profile --------------------------------

! ---   calculation of coefficients for node = 1
        i = 1
! ---   temperature fixed at soil surface
        thoma(i) = - dt * heacon(i) / (dz(i) * disnod(i))
        thomc(i) = - dt * heacon(i+1) / (dz(i) * disnod(i+1))
        thomb(i) = heacap(i) - thoma(i) - thomc(i)
        thomf(i) = heacap(i) * tmpold(i) - thoma(i) * TeTop

! ---   calculation of coefficients for 2 < node < numnod
        do i = 2,numnod-1 
          thoma(i) = - dt * heacon(i) / (dz(i) * disnod(i))
          thomc(i) = - dt * heacon(i+1) / (dz(i) * disnod(i+1))
          thomb(i) = heacap(i) - thoma(i) - thomc(i)
          thomf(i) = heacap(i) * tmpold(i)
        enddo

! ---   calculation of coefficients for node = numnod
        i = numnod
        if (SwBotbHea.eq.1) then
! ---   no heat flow through bottom of profile assumed
           qhbot = 0.0d0
           thoma(i) = - dt * heacon(i) / (dz(i) * disnod(i))
           thomb(i) = heacap(i) - thoma(i)
           thomf(i) = heacap(i) * tmpold(i) - (qhbot * dt)/dz(i)
        elseif (SwBotbHea.eq.2) then
! ---   bottom temperature is prescribed
           heaconBot = heacnd(i)
           thoma(i)  = - dt * heacon(i) / (dz(i) * disnod(i))
           thomc(i)  = - dt * heaconBot / (dz(i) * 0.5d0 * dz(i))
           thomb(i)  = heacap(i) - thoma(i) - thomc(i)
           thomf(i)  = heacap(i) * tmpold(i) - thomc(i) * TeBot
        endif

! ---   solve for vector tsoil a tridiagonal linear set
        call tridag (numnod, thoma, thomb, thomc, thomf, tsoil,ierror)
        if(ierror.ne.0)then
           messag = 
     &       'During a call from Temperature an error occured in TriDag'
           call fatalerr ('Temperature',messag)
        end if
      else

! ---   analytical solution temperature profile ---
        do i = 1,numnod
          tsoil(i) = tmean + tampli*(sin(0.0172d0*(daynr-timref+91.0d0)+
     &              z(i)/ddamp)) / exp(-z(i)/ddamp)
        enddo

      endif
      
      return
      end

!***********************************************************************
      Subroutine Devries (NumNod,theta,THETAS,HeaCap,HeaCon,FQUARTZ,
     &           FCLAY,FORG)
!***********************************************************************
!* Purpose:    Calculate soil heat capacity and conductivity for each  *
!*             compartment by full de Vries model                      *     
!* References:                                                         *
!* Description:                                                        *
!* de Vries model for soil heat capcity and thermal conductivity.      * 
!* Heat capacity is calculated as average of heat capacities for each  *
!* soil component. Thermal conductivity is calculated as weighted      *
!* average of conductivities for each component. If theta > 0.05 liquid*
!* water is assumed to be the main transport medium in calculating the *
!* weights. If theta < 0.02 air is assumed to be the main transport    *
!* medium (there is also an empirical adjustment to the conductivity). *
!* For 0.02 < theta < 0.05 conductivity is interpolated.               *
!* See: Heat and water transfer at the bare soil surface, H.F.M Ten    *
!* Berge (pp 48-54 and Appendix 2)                                     *
!***********************************************************************
!* Input:                                                              *
!* NumNod - number of compartments (-)                                 *
!* theta/THETAS - volumetric soil moisture/ saturated vol. s. moist (-)*
!* Fquartz, Fclay and Forg - volume fractions of sand, clay and org.ma.*
!* Output:                                                             *
!* HeaCap - heat capacity (J/m3/K)                                     *
!* HeaCon - thermal conductivity (W/m/K)                               *
!***********************************************************************
      Implicit None
      Include 'arrays.fi'
  
!     (i) Global declarations                                          
!     (i.i) Input                                                      
      Integer NumNod
      real*8 theta(1:MACP),THETAS(1:MACP)
!     (i.ii)
      real*8 HeaCap(MACP), HeaCon(MACP)
!     (ii) Local declarations                                          
      Integer Node
      real*8 kqa,kca,kwa,koa,kaa,kqw,kcw,kww,kow,kaw
      Parameter (kaa = 1.0d0, kww = 1.0d0)
      real*8 fAir(MACP),fClay(MACP),fQuartz(MACP),fOrg(MACP)
      real*8 HeaConDry,HeaConWet
!     (iii) Parameter declarations                                     
!     (iii.i) Physical constants                                       
!     Specific heats (J/kg/K)                                          
      real*8  cQuartz,cClay,cWat,cAir,cOrg
      Parameter (cQuartz = 800.0d0, cClay = 900.0d0, cWat = 4180.0d0,
     &           cAir = 1010.0d0, cOrg = 1920.0d0)
!     Density (kg/m3)
      real*8 dQuartz, dClay, dWat, dAir, dOrg
      Parameter (dQuartz = 2660.0d0, dClay = 2650.0d0, dWat = 1000.0d0,
     &           dAir = 1.2d0, dOrg = 1300.0d0)
!     Thermal conductivities (W/m/K)                                   
      real*8  kQuartz,kClay,kWat,kAir,kOrg
      Parameter (kQuartz = 8.8d0, kClay = 2.92d0, kWat = 0.57d0,
     &           kAir = 0.025d0, kOrg = 0.25d0)
!     
      real*8  GQuartz,GClay,GWat,GAir,GOrg
      Parameter (GQuartz = 0.14d0, GClay = 0.0d0 , GWat = 0.14d0, 
     &           GAir = 0.2d0, GOrg = 0.5d0)
!     (iii.ii) theta 0.02, 0.05 and 1.00                               
      real*8thetaDry,thetaWet
      Parameter (thetaDry = 0.02d0, thetaWet = 0.05d0)    
! ----------------------------------------------------------------------
!     (0) Weights for each component in conductivity calculations      
!     (Calculate these but define as parameters in later version)     
      kaw = 0.66d0 / (1.0d0 + ((kAir/kWat) - 1.0d0) * GAir) + 0.33d0 /
     &    (1.0d0 + ((kAir/kWat) - 1.0d0) * (1.0d0 - 2.0d0 * GAir)) 
      kqw = 0.66d0 / (1.0d0 + ((kQuartz/kWat)-1.0d0) * GQuartz)+0.33d0 /
     &    (1.0d0 + ((kQuartz/kWat) - 1.0d0) * (1.0d0 - 2.0d0 * GQuartz)) 
      kcw = 0.66d0 / (1.0d0 + ((kClay/kWat) - 1.0d0) * GClay) + 0.33d0 /
     &    (1.0d0 + ((kClay/kWat) - 1.0d0) * (1.0d0 - 2.0d0 * GClay)) 
      kow = 0.66d0 / (1.0d0 + ((kOrg/kWat) - 1.0d0) * GOrg) + 0.33d0 /
     &    (1.0d0 + ((kOrg/kWat) - 1.0d0) * (1.0d0 - 2.0d0 * GOrg)) 
      kwa = 0.66d0 / (1.0d0 + ((kWat/kAir) - 1.0d0) * GWat) + 0.33d0 /
     &    (1.0d0 + ((kWat/kAir) - 1.0d0) * (1.0d0 - 2.0d0 * GWat)) 
      kqa = 0.66d0 / (1.0d0 + ((kQuartz/kAir)-1.0d0) * GQuartz)+0.33d0 /
     &    (1.0d0 + ((kQuartz/kAir) - 1.0d0) * (1.0d0 - 2.0d0 * GQuartz)) 
      kca = 0.66d0 / (1.0d0 + ((kClay/kAir) - 1.0d0) * GClay) + 0.33d0 /
     &    (1.0d0 + ((kClay/kAir) - 1.0d0) * (1.0d0 - 2.0d0 * GClay)) 
      koa = 0.66d0 / (1.0d0 + ((kOrg/kAir) - 1.0d0) * GOrg) + 0.33d0 /
     &    (1.0d0 + ((kOrg/kAir) - 1.0d0) * (1.0d0 - 2.0d0 * GOrg)) 

      Do Node = 1,NumNod

!        (1) Air fraction
         fAir(Node) = THETAS(Node) - theta(Node)

!        (2) Heat capacity (W/m3/K) is average of heat capacities for  
!        all components (multiplied by density for correct units)      
         HeaCap(Node) = fQuartz(Node)*dQuartz*cQuartz + fClay(Node)*
     &                  dClay*cClay + theta(Node)*dWat*cWat + 
     &                  fAir(Node)*dAir*cAir +
     &                  fOrg(Node)*dOrg*cOrg

!        (3) Thermal conductivity (W/m/K) is weighted average of       
!        conductivities of all components                              
!        (3.1) Dry conditions (include empirical correction) (eq. 3.44)
         If (theta(Node).LE.thetaDry) Then
            HeaCon(Node) = 1.25d0 * (kqa*fQuartz(Node)*kQuartz + 
     &                      kca*fClay(Node)*kClay +
     &                      kaa*fAir(Node)*kAir +
     &                      koa*fOrg(Node)*kOrg +
     &                      kwa*theta(Node)*kWat) /
     &   (kqa * fQuartz(Node) + kca * fClay(Node) + kaa * fAir(Node) +
     &    koa * fOrg(Node) + kwa * theta(Node))

!        (3.2) Wet conditions  (eq. 3.43)                              
         Else If (theta(Node).GE.thetaWet) Then
            HeaCon(Node) = (kqw*fQuartz(Node)*kQuartz + 
     &                      kcw*fClay(Node)*kClay +
     &                      kaw*fAir(Node)*kAir +
     &                      kow*fOrg(Node)*kOrg +
     &                      kww*theta(Node)*kWat) /
     &   (kqw * fQuartz(Node) + kcw * fClay(Node) + kaw * fAir(Node) +
     &    kow * fOrg(Node) + kww * theta(Node))

!        (3.3) dry < theta < wet (interpolate)
         Else
!           (3.3.1) Conductivity for theta = 0.02                      
            HeaConDry = 1.25d0 * (kqa*fQuartz(Node)*kQuartz + 
     &                      kca*fClay(Node)*kClay +
     &                      kaa*fAir(Node)*kAir +
     &                      koa*fOrg(Node)*kOrg +
     &                      kwa*thetaDry*kWat) /
     &   (kqa * fQuartz(Node) + kca * fClay(Node) + kaa * fAir(Node) +
     &    koa * fOrg(Node) + kwa * thetaDry)
!           (3.3.1) Conductivity for theta = 0.05                      
            HeaConWet = (kqw*fQuartz(Node)*kQuartz + 
     &                      kcw*fClay(Node)*kClay +
     &                      kaw*fAir(Node)*kAir +
     &                      kow*fOrg(Node)*kOrg +
     &                      kww*thetaWet*kWat) /
     &   (kqw * fQuartz(Node) + kcw * fClay(Node) + kaw * fAir(Node) +
     &    kow * fOrg(Node) + kww * thetaWet)
!         (3.3.3) Interpolate                                          
          HeaCon(Node) = HeaConDry + (theta(Node)-thetaDry) * 
     &                   (HeaConWet - HeaConDry) 
     &                 / (thetaWet - thetaDry)      
         End If

! ---    conversion of capacity from J/m3/K to J/cm3/K
         HEACAP(NODE) = HEACAP(NODE)*1.0d-6

! ---    conversion of conductivity from W/m/K to J/cm/K/d
         HEACON(NODE) = HEACON(NODE)*864.0d0

      End Do

      Return
      End 

