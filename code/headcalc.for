! File VersionID:
!   $Id: headcalc.for 201 2011-03-15 14:53:33Z kroes006 $
! ----------------------------------------------------------------------
      subroutine headcalc 
! ----------------------------------------------------------------------
!     date               : April 2005 / Sept 2005
!     purpose            : calculate pressure heads, water contents,
!                          and conductivities for next time step
! ----------------------------------------------------------------------
      use variables
      implicit none

! ----------------------------------------------------------------------
! --- local
      integer   i,j, itry,  MaxIt1, ndr, NN, iBackTr
      real*8    dFdhL(macp), dFdhM(macp), dFdhU(macp), difh(macp), dtold
      real*8    F(macp), factor, Fmax, QMpLatSsSav,qv(macp+1)
      real*8    factmax, sink(macp), sum, sum1, sumold, ratio, deviat
      real*8    hold(macp),nihil
      character messag*200, datetime*19
      logical   flnonconv,flnonconv1(macp), flnonconv2(macp), flnonconv3
      logical   flunsatok(3)       ! Flag indicating the performance of the iteration process
      logical   flwarn,flboth
      integer   iwarn, NStep

! functions
      real*8    watcon, hconduc, moiscap, hcomean, afgen

! criteria
      real*8  CritDevBalCp, CritDevBalTot, Critdz

      data    CritDevBalCp   / 1.0d-6 / 
      data    CritDevBalTot  / 1.0d-5 / 
      data    Critdz         / 1.0d-5 / 
      data    ndr            / 5 / 
      data    nihil          / 1.0d-16 /
 
      real*8  hgrad(macp+1), dkdh(macp)

!  functions
      real*8  dhconduc, dkmean

      integer indx(macp), ierror
      real*8  a(macp,3), a1(macp,1), b(macp), d, q1
      logical flok

!     save values of local variables
      save    flwarn,iwarn


      if (fldaystart) then
         flwarn = .true.
         iwarn = 0
      endif
      call dtdpst 
     &        ('year-month-day,hour:minute:seconds',t1900,datetime)
 
!     summation of sink terms (constant for the current time step)


      iBackTr   = 0
      flunsatok(1) = .false.
      flunsatok(2) = .false.
      flunsatok(3) = .false.
      do i=1,numnod
         sink(i) = evp(i)
         do j=1,ndr
            sink(i) = sink(i) + qdra(j,i)
         end do
      end do
 
!     groundwater level  specified
      if(swbotb.eq.1)then
         fllowgwl = .false.
         if(gwlinp.ge.z(1))then

            q0 = (nraidt+nird+melt)*(1.0d0-ArMpSs) + runon - reva 
            call pondrunoff (swdra,swmacro,FlRunoff,disnod,dt,h,
     &                       gwlinp,k1max,pondm1,pondmx,q0,rsro,rsroexp,
     &                       sttab,wls,swst,QMpLatSs,hsurf,pond,runots,
     &                       swpondmx,pondmxtab,t1900)
            q1 = - q0 + (pond - pondm1)/dt + runots / dt
            theta(1) = watcon(1,gwlinp,cofgen(1,1),
     &                        swsophy,numtab,sptab)
            kmean(1) = hconduc(1,theta(1),cofgen(1,1),
     &                         swfrost,rfcp(1),swsophy,numtab,sptab)
!           in case of static macropores FrArMtrx < 1
            if(swmacro.eq.1) kmean(1) = FrArMtrx(1) * kmean(1)

            qv(1) = q1
            do i=1,numnod
               qv(i+1) = qv(i) +dz(i)*FrArMtrx(i)*(theta(i)-thetm1(i)) 
     &                          / dt+ sink(i) +qrot(i)
            end do
            qbot = qv(numnod+1)
            h(1) = gwlinp + disnod(1)*(qv(1)/kmean(1)+1.0d0)
            do i=2,numnod
               h(i) = h(i-1) + disnod(i)*(qv(i)/kmean(i)+1.0d0)
            end do

            if(SwKimpl.eq.1)then
               do i=1,numnod
                  k(i) = hconduc(i,theta(i),cofgen(1,i),
     &                           swfrost,rfcp(i),swsophy,numtab,sptab)
                  if(swmacro.eq.1)  k(i) = FrArMtrx(i) * k(i)
                  if(i.gt.1)then
                     kmean(i)=hcomean(swkmean,k(i-1),k(i),dz(i-1),dz(i))
                  end if
               end do
               kmean(numnod+1) = k(numnod)                  
            end if
            call calcgwl(logf,swscre,swbotb,flmacropore,numnod,
     &            CritUndSatVol,gwlinp,h,z,dz,pond,t1900,Theta,ThetaS,
     &            gwl,nodgwl,bpegwl,npegwl,pegwl,nodgwlflcpzo,gwlflcpzo)
            return
         else
            NN = 0
            do while (z(NN+1).gt.gwlinp .and. NN.lt.numnod)
               NN = NN + 1
            end do
            if (z(NN+1).lt.(gwlinp+nihil)) then
!             groundwater within soil profile
              if (abs(z(nn) - gwlinp) .lt. 1.d-3) then
!               limit maximum ratio
                ratio = (z(NN)-z(NN+1)) * 1.0d3
              else
                ratio = (z(NN)-z(NN+1))/(z(NN)-gwlinp)
              endif
            else
!             groundwater below soil profile
              fllowgwl = .true.
              hbot = gwlinp - z(numnod) + 0.5*dz(numnod)
            endif
         end if
      else
         NN = numnod
      end if

! --- reset conductivities to time level t
      do i = 1,numnod
         k(i) = hconduc(i,theta(i),cofgen(1,i),swfrost,rfcp(i),
     &                  swsophy,numtab,sptab)
         if(swmacro.eq.1)  k(i) = FrArMtrx(i) * k(i)
         if(i.gt.1)then
            kmean(i) = hcomean(swkmean,k(i-1),k(i),dz(i-1),dz(i))
         end if
      enddo
      kmean(numnod+1) = k(numnod)

      if(SwKimpl.eq.0)then
         do i=2,numnod
            dFdhU(i)   = - kmean(i)  /disnod(i)
            dFdhL(i-1) = dFdhU(i)
         end do
      end if

      do i=2,NN
         hgrad(i) = (h(i-1)-h(i))/disnod(i) + 1.0d0
      end do

      F(1) = (theta(1)-thetm1(1))*FrArMtrx(1)*dz(1)/dt +sink(1) +qrot(1)
     &     + kmean(2) * hgrad(2)

      call boundtop

      if (SwMacro.eq.1) then
         call MACROPORE(2)
      end if

      if (FlRunoff .or. SwMacro.eq.1) call pondrunoff (swdra,swmacro,
     &        FlRunoff,disnod,dt,h,H0max,k1max,pondm1,pondmx,q0,rsro,
     &        rsroexp,sttab,wls,swst,QMpLatSs,hsurf,pond,runots,
     &        swpondmx,pondmxtab,t1900)

      if(ftoph)then
         hgrad(1) = (hsurf-h(1))/disnod(1) + 1.d0
         F(1)     = F(1) - kmean(1) * hgrad(1)
      else
         F(1) = F(1) + qtop
      end if

      do i=2,NN-1
         F(i) = (theta(i)-thetm1(i))*FrArMtrx(i)*dz(i)/dt +sink(i)+
     &          qrot(i) - kmean(i) * hgrad(i) + kmean(i+1) * hgrad(i+1)
      end do

      if(swbotb.eq.1 .and. (.not.fllowgwl))then
         hgrad(NN+1) = ratio * h(NN) / disnod(NN+1)  + 1.0d0
      else if(swbotb.eq.5 .or. (swbotb.eq.1 .and. fllowgwl))then
         hgrad(NN+1) = (h(NN) - hbot) / disnod(NN+1)  + 1.0d0
      else if(swbotb.eq.8 .and. h(NN).gt. Critdz - disnod(NN+1))then
         hgrad(NN+1) = h(NN) / disnod(NN+1)  + 1.0d0
         flboth = .true.
      else
         flboth = .false.
      end if

      if(swbotb.eq.1 .and. (.not.fllowgwl))then
         theta(NN)= watcon(NN,h(NN),cofgen(1,NN),swsophy,numtab,sptab)
         k(NN)    = hconduc(NN,theta(NN),cofgen(1,NN),
     &                       swfrost,rfcp(NN),swsophy,numtab,sptab)
!        in case of static macropores FrArMtrx < 1
         if(swmacro.eq.1) k(NN) = FrArMtrx(NN) * k(NN)
         kmean(NN+1) = hcomean(swkmean,k(NN),cofgen(3,(NN+1)),
     &                        dz(NN),dz(NN+1))
         F(NN) = (theta(NN) - thetm1(NN))*FrArMtrx(NN)*dz(NN)/dt +
     &           sink(NN)+qrot(NN)-kmean(NN)*hgrad(NN) +kmean(NN+1)*
     &           hgrad(NN+1)
      else

         F(NN) = (theta(NN) - thetm1(NN))*FrArMtrx(NN)*dz(NN)/dt
     &         - kmean(NN) * hgrad(NN) + sink(NN) + qrot(NN) 

         if(swbotb.eq.3.and.swbotb3Impl.eq.1)then ! Cauchy-relation, implemented as head boundary
            if (SwBotb3ResVert.eq.0) then
               qbot = - (h(NN)+z(NN)-deepgw) / 
     &                                 (disnod(NN+1)/kmean(NN+1)+rimlay)
            elseif (SwBotb3ResVert.eq.1) then
               qbot = - (h(NN)+z(NN)-deepgw) / rimlay
            endif
! ---       extra groundwater flux might be added
            if (sw4 .eq. 1) qbot = qbot + afgen(qbotab,mabbc*2,t1900+dt)
            F(NN) = F(NN) - qbot     
         else if(swbotb.eq.5 .or. (swbotb.eq.1 .and. fllowgwl))then ! pressure head at lower boundary specified
            F(NN) = F(NN) + kmean(NN+1) * hgrad(NN+1)
         else if(swbotb.eq.7 .or. swbotb .eq. -2)then ! free drainage option
            kmean(numnod+1) = hconduc(numnod,theta(numnod),
     &       cofgen(1,numnod),swfrost,rfcp(numnod),swsophy,numtab,sptab)
            if(swmacro.eq.1) then 
                kmean(numnod+1) = FrArMtrx(numnod) * kmean(numnod+1)
            endif
            qbot = -1.0d0 * kmean(numnod+1)
            F(NN) = F(NN) - qbot
! lysimeter option
         else if(swbotb.eq.8)then                                  
            if (flboth) then
               hbot = 0.0d0
               F(NN) = F(NN) + kmean(NN+1) * hgrad(NN+1)
            else
               qbot = 0.0d0
            end if
! flux bottom boundary
         else
            F(NN) = F(NN) - qbot
         end if

      end if

      if (SwMacro.eq.1) then
         do i= 1, NN
            F(i) = F(i) - QExcMpMtx(i)
         enddo
      endif

!     initial estimate of F inner product
      sumold    = 0.0d0
      do i=1,NN
         sumold = sumold + F(i)*F(i)
      end do
      sumold = 0.5d0 * sumold

!     start iteration loop, MaxIt specified in the input

      if(fldtmin)then
         MaxIt1 = 2*MaxIt
      else
         MaxIt1 = MaxIt
      end if

      sum= 0.d0   ! For Forcheck
      Do numbit = 1,MaxIt1


         do i = 1, NN

!     save values of h

            hold(i)   = h(i)

!        derivative of theta to h (differential moisture capacity), 
!        as part of main diagonal

            dimoca(i) = moiscap(i,h(i),cofgen(1,i),dt,
     &                          swsophy,numtab,sptab)


         enddo

         if(SwKimpl.eq.1)then
            do i = 1, NN
               dkdh(i) = dhconduc(i,theta(i),dimoca(i),cofgen(1,i),
     &                            swfrost,rfcp(i),swsophy,numtab,sptab)
               if(swmacro.eq.1) dkdh(i) = FrArMtrx(i) * dkdh(i)
            enddo
            do i=2,NN
               dFdhU(i)   = - kmean(i)  /disnod(i)
               dFdhL(i-1) = dFdhU(i)
            end do
         end if

!>>>>>>> J a c o b i a n 

         dFdhM(1) = dimoca(1)*FrArMtrx(1)*dz(1)/dt - dFdhL(1) 
!        if the head boundary condition applies: add the k1/(0.5*dz1) term
!        to the first element of the main diagonal 
         if(ftoph) dFdhM(1) = dFdhM(1) + kmean(1)/disnod(1)  

         do i=2,NN-1
            dFdhM(i) = dimoca(i)*FrArMtrx(i)*dz(i)/dt - dFdhU(i) 
     &                                                - dFdhL(i) 
         end do

         dFdhM(NN) = dimoca(NN)*FrArMtrx(NN)*dz(NN)/dt - dFdhU(NN) 
         if(swbotb.eq.1 .and. (.not.fllowgwl))then
            dFdhM(NN) = dFdhM(NN) + ratio*kmean(NN+1)/disnod(NN+1) 
         else if(swbotb.eq.3.and.swbotb3Impl.eq.1)then ! Cauchy
            if (SwBotb3ResVert.eq.0) then
               dFdhM(NN) = dFdhM(NN) + 1.0d0 /
     &                              (disnod(NN+1)/kmean(NN+1)+rimlay)   
            elseif (SwBotb3ResVert.eq.1) then
               dFdhM(NN) = dFdhM(NN) + 1.0d0 / rimlay
            endif
         else if(swbotb.eq.5 .or. (swbotb.eq.1 .and. fllowgwl))then
            dFdhM(NN) = dFdhM(NN) + kmean(NN+1)/disnod(NN+1)         
         else if(swbotb.eq.7 .or. swbotb .eq. -2)then ! implicitly: kmean(NN+1)
            dFdhM(NN) = dFdhM(NN) + dkdh(NN) * 0.5d0
         else if(swbotb.eq.8 .and. flboth)then
            dFdhM(NN) = dFdhM(NN) + kmean(NN+1)/disnod(NN+1)
         end if

         if(SwKimpl.eq.1)then
            dFdhM(1) = dFdhM(1) + dkdh(1) * hgrad(2) *
     &                 dkmean(swkmean,k(1),k(2),dz(1),dz(2))
            if(ftoph) dFdhM(1) = dFdhM(1) - dkdh(1) * hgrad(1) * 0.5d0
            dFdhL(1) = dFdhL(1) + dkdh(2) * hgrad(2) *
     &                 dkmean(swkmean,k(2),k(1),dz(2),dz(1)) 
            do i=2,NN-1
               dFdhU(i) = dFdhU(i) - dkdh(i-1) * hgrad(i) * 
     &                    dkmean(swkmean,k(i-1),k(i),dz(i-1),dz(i)) 
               dFdhM(i) = dFdhM(i) - dkdh(i) * hgrad(i) * 
     &                    dkmean(swkmean,k(i),k(i-1),dz(i),dz(i-1))
     &                             + dkdh(i) * hgrad(i+1) *
     &                    dkmean(swkmean,k(i),k(i+1),dz(i),dz(i+1))
               dFdhL(i) = dFdhL(i) + dkdh(i+1) * hgrad(i+1) *
     &                    dkmean(swkmean,k(i+1),k(i),dz(i+1),dz(i)) 
            end do
            dFdhU(NN) = dFdhU(NN) - dkdh(NN-1) * hgrad(NN) * 
     &                  dkmean(swkmean,k(NN-1),k(NN),dz(NN-1),dz(NN)) 
            dFdhM(NN) = dFdhM(NN) - dkdh(NN) * hgrad(NN) * 
     &                  dkmean(swkmean,k(NN),k(NN-1),dz(NN),dz(NN-1))

            if(swbotb.eq.1 .or. swbotb.eq.5 .or. swbotb.eq.8 
     &         .and. flboth)then
               dFdhM(NN) = dFdhM(NN) + 0.5d0 * dkdh(NN) * hgrad(NN+1)
            end if
         end if

         if (SwMacro.eq.1 .and. .not.flunsatok(3)) then
            call MACROPORE(3)

            do i= 1, nn
               dFdhM(i) = dFdhM(i) - dFdhMp(i)
            enddo

         endif


!<<<<<<< J a c o b i a n 



! --- solve the tridiagonal matrix

         call tridag(NN, dFdhU, dFdhM, dFdhL, F, difh, ierror)

         if(ierror.ne.0)then
            call dtdpst ('day-monthst-year',t1900+1.001d0,date)
            messag = ' Tri-band matrix in HeadCalc appeared to be'//
     &               ' singular at '//date//
     &               '   Alternative SOLVER chosen'
            call warn ('Headcalc',messag,logf,swscre)
            do i=1,NN
               a(i,1) = dFdhU(i)
               a(i,2) = dFdhM(i)
               a(i,3) = dFdhL(i)
            end do
            call bandec(a,nn,1,1,macp,3,a1,1,indx,d)
            do i=1,NN
               b(i) = F(i)
            end do
            call banbks(a,nn,1,1,macp,3,a1,1,indx,b)
            do i=1,NN
               difh(i) = b(i)
            end do
         end if

         factor  = 1.0d0
         do itry = 1,MaxBackTr
            iBackTr = iBackTr + 1
!           factor reduces the change of h (difh) calculated as a full 
!           Newton Raphson step

            if(fldtmin .and. numbit.gt.MaxIt)then              
               factmax = 0.0d0
               do i = 1,NN
                  if(dabs( hold(i) ) .lt. 1.0d0 )then
                     factmax = max( factmax, dabs( difh(i) ) ) 
                  else
                     factmax = max( factmax, dabs( difh(i) / hold(i) ) )
                  end if
               end do
               do i = 1,NN
                  h(i) = hold(i) - difh(i) * min(1.0d0, 1.0d0 / factmax)
               end do
            else
               do i = 1,NN
                  h(i) = hold(i) - factor * difh(i)
               end do
            end if
            do i = 1,NN
              theta(i) = watcon(i,h(i),cofgen(1,i),swsophy,numtab,sptab)
            enddo
            do i=2,NN
               hgrad(i) = (h(i-1)-h(i))/disnod(i) + 1.0d0
            end do
            if(SwKimpl.eq.1)then
               call Rootextraction
               do i = 1,NN
                  k(i) = hconduc(i,theta(i),cofgen(1,i),
     &                           swfrost,rfcp(i),swsophy,numtab,sptab)
!                 in case of static macropores FrArMtrx < 1
                  if(swmacro.eq.1)  k(i) = FrArMtrx(i) * k(i)
                  if(i.gt.1)then
                     kmean(i)=hcomean(swkmean,k(i-1),k(i),dz(i-1),dz(i))
                  end if
               end do
               kmean(NN+1) = k(NN)
            end if

! calculate F-function         

            F(1) = (theta(1) - thetm1(1))*FrArMtrx(1)*dz(1)/dt + sink(1) 
     &           + qrot(1) + kmean(2) * hgrad(2)

            if (SwMacro.eq.1) QMpLatSsSav = QMpLatSs

            call boundtop

            if (SwMacro.eq.1) then
               if (.not.flunsatok(3)) then
                  call MACROPORE(2)
               else
                  QMpLatSs = QMpLatSsSav
               endif
            endif

!
            if (FlRunoff .or. SwMacro.eq.1) call pondrunoff (swdra,
     &          SwMacro,FlRunoff,disnod,dt,h,H0max,k1max,pondm1,pondmx,
     &          q0,rsro,rsroexp,sttab,wls,swst,QMpLatSs,hsurf,pond,
     &          runots,swpondmx,pondmxtab,t1900)


            if(ftoph)then
               hgrad(1) = (hsurf-h(1))/disnod(1) + 1.d0
               F(1) = F(1) - kmean(1) * hgrad(1)
            else
               F(1) = F(1) + qtop
            end if

            do i=2,NN-1
               F(i) = (theta(i)-thetm1(i))*FrArMtrx(i)*dz(i)/dt +sink(i) 
     &              + qrot(i) - kmean(i)*hgrad(i)+kmean(i+1)*hgrad(i+1)
            end do

            if(swbotb.eq.1 .and. (.not.fllowgwl))then
               hgrad(NN+1) = ratio * h(NN) / disnod(NN+1)  + 1.0d0
            else if(swbotb.eq.5 .or. (swbotb.eq.1 .and. fllowgwl))then
               hgrad(NN+1) = (h(NN) - hbot) / disnod(NN+1)  + 1.0d0
            else if(swbotb.eq.8 .and. flboth)then
               hgrad(NN+1) = h(NN) / disnod(NN+1)  + 1.0d0
            end if

            if(swbotb.eq.1 .and. (.not.fllowgwl))then
               theta(NN) = watcon(NN,h(NN),cofgen(1,NN),
     &                                             swsophy,numtab,sptab)
               k(NN)     = hconduc(NN,theta(NN),cofgen(1,NN),
     &                            swfrost,rfcp(NN),swsophy,numtab,sptab)
!              in case of static macropores FrArMtrx < 1
               if(swmacro.eq.1)  k(NN) = FrArMtrx(NN) * k(NN)
               kmean(NN+1) = hcomean(swkmean,k(NN),cofgen(3,(NN+1))
     &                       ,dz(NN),dz(NN+1))
               F(NN) = (theta(NN) - thetm1(NN))*FrArMtrx(NN)*dz(NN)/dt
     &            - kmean(NN) * hgrad(NN) + kmean(NN+1) * hgrad(NN+1)
     &            + sink(NN) +qrot(NN)
            else
               F(NN) = (theta(NN) - thetm1(NN))*FrArMtrx(NN)*dz(NN)/dt
     &               - kmean(NN) * hgrad(NN)
     &               + sink(NN)+qrot(NN)
               if(swbotb.eq.3.and.swbotb3Impl.eq.1)then ! Cauchy
                  if (SwBotb3ResVert.eq.0) then
                     qbot = - (h(NN)+z(NN)-deepgw) / 
     &                                 (disnod(NN+1)/kmean(NN+1)+rimlay)
                  elseif (SwBotb3ResVert.eq.1) then
                     qbot = - (h(NN)+z(NN)-deepgw) / rimlay
                  endif
! ---             extra groundwater flux might be added
                  if (sw4 .eq. 1) then
                     qbot = qbot + afgen(qbotab,mabbc*2,t1900+dt)
                  end if
                  F(NN) = F(NN) - qbot     
               else if(swbotb.eq.5 .or.(swbotb.eq.1 .and. fllowgwl))then 
!                 pressure head at lower boundary specified  
                  F(NN) = F(NN) + kmean(NN+1) * hgrad(NN+1)
               else if(swbotb.eq.7.or. swbotb .eq. -2)then ! free drainage option
                  kmean(numnod+1) = hconduc(numnod,theta(numnod),
     &                            cofgen(1,numnod),swfrost,rfcp(numnod),
     &                            swsophy,numtab,sptab)
                  if(swmacro.eq.1) then
                     kmean(numnod+1) = FrArMtrx(numnod)*kmean(numnod+1)
                  endif
                  qbot = -1.0d0 * kmean(numnod+1)
                  F(NN) = F(NN) - qbot
! lysimeter option
               else if(swbotb.eq.8)then                                  
                  if (flboth) then
                     hbot = 0.0d0
                       F(NN) = F(NN) + kmean(NN+1) * hgrad(NN+1)
                  else
                     qbot = 0.0d0
                  end if
! flux bottom boundary
               else
                  F(NN) = F(NN) - qbot
               end if

            end if

            if (SwMacro.eq.1) then
               do i= 1, nn
                  F(i) = F(i) - QExcMpMtx(i)
               enddo
            endif

!           calculate maximum deviation per compartment and new inner product
            Fmax   = 0.0d0
            sum    = 0.0d0
            sum1   = 0.0d0
            do i=1,NN
               if(dabs(F(i)).gt.Fmax) Fmax = dabs(F(i))
               sum = sum + F(i)*F(i)
               sum1=sum1 + F(i)  ! in cm/d
            end do
            sum = 0.5d0 * sum

!           test for iteration progress, if Newton-step is too large: 
!           reduce dh by multiplication factor

            if(sum.lt.sumold .or. Fmax.lt.CritDevBalCp) goto 1000

            factor = factor / 3.0d0


         end do
 1000    continue


! --- check on convergence of solution


!        initialize flags

!        main flag for testing the convergence
         flnonconv = .false.

!        flags introduced for debugging purposes
         do i = 1,numnod
            flnonconv1(i) = .false.
            flnonconv2(i) = .false.
         end do
         flnonconv3 = .false.
         flnonconv1(1) = flnonconv1(1) ! for Forcheck

!        apply performance criteria per compartment

         do i = 1,NN

!           test for water balance deviation of soil compartments
               if( dabs(F(i)).gt. CritDevBalCp)then
                  flnonconv1(i) = .true. ; flnonconv   = .true.
               end if
!           test for change of pressure head
            if( dabs(hold(i)) .lt. 1.0d0)then
               if(abs( h(i)-hold(i) ) .gt. CritDevh2Cp)then
                  flnonconv2(i) = .true. ; flnonconv   = .true.
               endif
            else
               if(abs( h(i)-hold(i) )/abs(hold(i)) .gt. CritDevh1Cp)then
                  flnonconv2(i) = .true. ; flnonconv   = .true.
               endif
            end if
            flnonconv2(1) = flnonconv2(1) ! for Forcheck
       
         enddo

!        test for waterbalance of ponding layer

         if (ftoph) then
            qtop = -kmean(1)*((hsurf - h(1))/disnod(1)+1.0d0)
            if(.not.flnonconv .and. SWMacro.ne.1) then
               deviat = pond - pondm1 + reva*dt - (nraidt+nird+Melt)*dt 
     &                - runon*dt  +  runots  - qtop * dt
               if( abs(deviat) .gt. CritDevPondDt) then
                  flnonconv3 = .true. ; flnonconv   = .true.
                  flnonconv3 = flnonconv3 ! for Forcheck
               end if
            end if
         end if

         if(SWMacro.eq.1)then
            deviat = pond - pondm1 + reva*dt - (nraidt+nird+Melt)*dt 
     &             - runon*dt  +  runots  - qtop * dt 
     &             + ArMpSs * (nraidt+nird+Melt)*dt + QMpLatSs
            if( abs(deviat) .gt. CritDevPondDt) then
               flnonconv3 = .true. ; flnonconv   = .true.
               flnonconv3 = flnonconv3 ! for Forcheck
            end if
         end if


!  Implemented to improve iteration performance in case of macropores
       if(dt.lt. 0.01d0 .and. SwMacro.eq.1 .and. .not.flnonconv3)then 
            flok = .true.
            if (dt.gt.10.d0*dtmin) then
               do i=1,nodgwl
                  if(h(i).gt.0.0d0.and.flnonconv1(i).and.flnonconv2(i))
     &            then
                     flok = .false.
                  end if
               end do
            else
               continue
            endif
            if(flok)then
               if(.not.flunsatok(1))then
                  flunsatok(1) = .true.
               else if(.not. flunsatok(2))then
                  flunsatok(2) = .true.
               else
                  flunsatok(3) = .true.                 
               end if
            else
               flunsatok(1) = .false.
               flunsatok(2) = .false.
               flunsatok(3) = .false.
            end if
         end if

         if(dabs(sum1).gt.CritDevBalTot) flnonconv   = .true.


!        save sum voor next iteration
         sumold = sum

         if(.not.flnonconv )then !  convergence has been reached
        
            if (Swmacro.eq.1) then
               FlDecMpRat = .false.
               if (IDecMpRat.gt.0) then
                  if (NStep.lt.10) then
                     NStep = NStep + 1
                  endif
                  if (dt.gt.dtold .or. NStep.gt.10) then
                     dtold = dt
                     NStep = 0
                     IDecMpRat = IDecMpRat - 1
                  endif
               endif
            endif

            if(swbotb.eq.1 .and. (.not.fllowgwl))then
!           derive vertical flux profile in order to find qbot as a 
!           lower boundary condition for the saturated part of the soil 
!           system
               qv(1) = qtop
               do i=1,numnod
                 qv(i+1) = qv(i) +dz(i)*FrArMtrx(i)*(theta(i)-thetm1(i)) 
     &                          / dt+ sink(i) +qrot(i)
               end do
               qbot = qv(numnod+1)

               do i=NN+1,numnod
                  h(i) = h(i-1) + disnod(i)*(qv(i)/kmean(i)+1.0d0)
               end do

            end if
   
!           calculate new groundwater level
            call calcgwl(logf,swscre,swbotb,flmacropore,numnod,
     &            CritUndSatVol,gwlinp,h,z,dz,pond,t1900,Theta,ThetaS,
     &            gwl,nodgwl,bpegwl,npegwl,pegwl,nodgwlflcpzo,gwlflcpzo)

            if(swbotb.ne.1.and.abs(gwl-gwlm1).ge.gwlconv .AND. 
     &         abs(gwl-999d0).gt.1.d0.and.abs(gwlm1-999d0).gt.1.d0) then
               call dtdpst ('day-monthst-year',t1900+1.001d0,date)
                 messag = ' Change of groundwater level exceeds'//
     &           ' criterion at '//date//'. Consider reduction of dtMin'
               call warn ('Headcalc',messag,logf,swscre)
            endif

!           recording of number of iteration steps needed
            itnumb(min(100,numbit),1)=itnumb(min(100,numbit),1)+1 
            itnumb(min(100,numbit),2)=itnumb(min(100,numbit),2)+iBackTr 

            return
            
         end if
      End Do


!     Convergence could not been reached

      if (.not.fldtmin ) then

! ---         reset soil state variables
         do j = 1,numnod
            h(j) = hm1(j)
            theta(j) = thetm1(j)
         enddo
         kmean(numnod+1) = k(numnod)
         gwl    = gwlm1
         pond   = pondm1

! ---         reset and continue iteration with smaller timestep!
         fldecdt = .true.

         return  

! ---         in case of macropores, retry with reduction of exchange fluxes with matrix
      elseif (SwMacro.eq.1 .and. IDecMpRat .lt. 3) then

! ---         reset soil state variables
         IDecMpRat  = IDecMpRat + 1
         FlDecMpRat = .true.
         dtold = dt

!         write(104,'(f10.6,i5)') t, IDecMpRat

         return         

      else
! ---         write warning to screen and log file
         if (flwarn .and. iwarn.lt.5) then
            iwarn = iwarn + 1
            call dtdpst 
     &        ('year-month-day,hour:minute:seconds',t1900,datetime)
            messag = ' No convergence was reached of Richards'//
     &        ' equation at '//datetime//
     &        ' no more than 4 warnings per date - SWAP did continue !'
            call warn ('Headcalc',messag,logf,swscre)
            if (iwarn.gt.4) then
              flwarn = .false.  
            endif
         endif

         if(fldumpconvcrit) then
           write(logf,'(a,a19)')   'Datetime = ',datetime
           write(logf,'(a,f14.6)') 't1900    = ', t1900
           write(logf,'(a,f10.6)') 'dtmin = ', dtmin
           write(logf,'(a,f10.6)') 'dt    = ', dt
           write(logf,'(a,i3)')    'ftoph  = ', ftoph
           write(logf,'(a,f10.6)') 'CritDevBalCp  = ', CritDevBalCp
           write(logf,'(a,f10.6)') 'CritDevBalTot = ', CritDevBalTot
           write(logf,'(a,f10.6)') 'CritDz        = ', CritDz
           write(logf,'(a,f10.6)') 'CritDevh1Cp   = ', CritDevh1Cp
           write(logf,'(a,f10.6)') 'CritDevh2Cp   = ', CritDevh2Cp
           write(logf,'(a,i3)') 'flnonconv  = ', flnonconv
           write(logf,'(a,i3)') 'flnonconv3 = ', flnonconv3
           write(logf,'(a,i3)') 'flunsatok(1) = ', flunsatok(1)
           write(logf,'(a,i3)') 'flunsatok(2) = ', flunsatok(2)
           write(logf,'(a,i3)') 'flunsatok(3) = ', flunsatok(3)

           write(logf,'(a,f10.6)') 'pondm1 = ', pondm1
           write(logf,'(a,f10.6)') 'pond   = ', pond
           write(logf,'(a,f10.6)') 'gwlm1 = ', gwlm1
           write(logf,'(a,f10.6)') 'gwl   = ', gwl
           write(logf,'(a)')
     &      'node,flnonconv1_F, F, flnonconv2_h, hm1,     h,'//
     &      '    thetm1,    theta'
           do j = 1,numnod
              write(logf,'(2(i4,a),f10.6,a,i3,5(a,f10.6))') 
     &            j,',',flnonconv1(j),',',F(j),',',flnonconv2(j),',', 
     &            h(j),',',hm1(j),',', theta(j),',',thetm1(j)
           enddo

         endif

! ---         continue without convergence !!!
         return

      endif

      end

      real*8 function dkmean(swkmean,kmain,ksub,dzmain,dzsub)
      integer swkmean
      real*8  kmain, ksub, dzmain, dzsub, a
      if(swkmean.eq.1)then
         dkmean = 0.5d0
      else if(swkmean.eq.2)then
         dkmean = dzmain/(dzmain+dzsub)
      else if(swkmean.eq.3)then
         dkmean = 0.5d0 * dsqrt(ksub / kmain)
      else if(swkmean.eq.4)then
         a = dzmain/(dzmain+dzsub)
         dkmean = a * (ksub / kmain) ** (1.0d0 - a)
      end if
      return
      end 
