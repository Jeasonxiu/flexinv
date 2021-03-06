      subroutine model(iin,iout,ioeig)
      implicit real*8(a-h,o-z)
      integer*4 ititle(20)
      real*8 lcon,ncon,lspl,nspl
      dimension vpv(1000),vph(1000),vsv(1000),vsh(1000),eta(1000),wrk(10000)
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
c
      common /geout/ depmin,depmax,ioutflag(1000),nlevout
      real*4 depmin,depmax
c
      data bigg,tau/6.6723d-11,1.d3/,rhobar/5515.0D0/
      pi=3.14159265358979d0
      read(iin,100) (ititle(i),i=1,20)
  100 format(20a4)
      read(iin,*) ifanis,tref,ifdeck
      if(ifdeck.eq.0) go to 1000
c*** card deck model ***
      read(iin,*) n,nic,noc,nmoho
      read(iin,105) (r(i),rho(i),vpv(i),vsv(i),
     +     qkappa(i),qshear(i),vph(i),vsh(i),eta(i),i=1,n)

  105 format(f8.0,3f9.2,2f9.1,2f9.2,f9.5)
      go to 2000
c*** polynomial model ***
 1000 read(iin,*) nreg,nic,noc,rx
      rx=rx*tau
      n=0
      knt=0
      jj=5
      if(ifanis.ne.0) jj=8
      do 10 nn=1,nreg
      read(iin,*) nlay,r1,r2
      r1=r1*tau
      r2=r2*tau
      dr=(r2-r1)/float(nlay-1)
      do 15 i=1,nlay
      n=n+1
   15 r(n)=r1+dr*float(i-1)
      do 20 j=1,jj
      read(iin,*) (wrk(i),i=1,5)
      do 20 i=1,nlay
      ind=knt+i
      rt=r(ind)/rx
      val=wrk(1)+rt*(wrk(2)+rt*(wrk(3)+rt*(wrk(4)+rt*wrk(5))))
      if(j.eq.1) rho(ind)=val*tau
      if(j.eq.2) vpv(ind)=val*tau
      if(j.eq.3) vsv(ind)=val*tau
      if(j.eq.4.and.val.ne.0.) qshear(ind)=1.0/val
      if(j.eq.5.and.val.ne.0.) qkappa(ind)=1.0/val
      if(ifanis.eq.0) goto 20
      if(j.eq.6) vph(ind)=val*tau
      if(j.eq.7) vsh(ind)=val*tau
      if(j.eq.8) eta(ind)=val
   20 continue
   10 knt=knt+nlay
 2000 if(ifanis.ne.0) go to 3000
      do 25 i=1,n
      vph(i)=vpv(i)
      vsh(i)=vsv(i)
   25 eta(i)=1.d0
 3000 continue
c-----------------------------------------------------------------
      do i=1,20
        call bffo(ioeig,1,ititle(i),4,istat,0)
      enddo
      call bffo(ioeig,1,ifanis,4,istat,0)
      call bffo(ioeig,1,sngl(tref),4,istat,0)
      call bffo(ioeig,1,ifdeck,4,istat,0)
      call bffo(ioeig,1,n,4,istat,0)
      call bffo(ioeig,1,nic,4,istat,0)
      call bffo(ioeig,1,noc,4,istat,0)
      call bffo(ioeig,1,nmoho,4,istat,0)
      nlevout=0
      do i=2,n
        if(r(n)-r(i).gt.dble(depmin*1000.-500.).and.r(n)-r(i).lt.dble(depmax*1000.+500.)) then
          ioutflag(i)=1
          ioutflag(i-1)=1
          nlevout=nlevout+1
        endif
      enddo
      if(nlevout.gt.0) nlevout=nlevout+1
      write(6,"('depmin,depmax,nlevout:',2g15.5,i10)") depmin,depmax,nlevout
      do i=1,n
        call bffo(ioeig,1,sngl(r(i)/1.d3),4,iostat,0)
        call bffo(ioeig,1,sngl(rho(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(vpv(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(vph(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(vsv(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(vsh(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(eta(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(qshear(i)),4,iostat,0)
        call bffo(ioeig,1,sngl(qkappa(i)),4,iostat,0)
        call bffo(ioeig,1,ioutflag(i),4,iostat,0)
      enddo
      call bffo(ioeig,1,nlevout,4,iostat,0)
c-----------------------------------------------------------------
      if(iout.lt.0) goto 30
c*** write out model ***
c     write(iout,900) (ititle(k),k=1,20),tref
  900 format(1x,20a4,' ref per =',f6.1,' secs',///,2x,'level',
     1 4x,'radius',8x,'rho',9x,'vpv',9x,'vph',9x,'vsv',
     2 9x,'vsh',9x,'eta',9x,'qmu ',8x,'qkap',/)
c     write(iout,905) (i,r(i),rho(i),vpv(i),vph(i),vsv(i),vsh(i),
c    1 eta(i),qshear(i),qkappa(i),i=1,n)
  905 format(3x,i3,f12.1,5f12.2,f12.5,2f12.2)
c*** normalise and spline ***
  30  rn=r(n)
      gn=pi*bigg*rhobar*rn
      vn2=gn*rn
      vn=dsqrt(vn2)
      wn=vn/rn
      do 45 i=1,n
      r(i)=r(i)/rn
      if(i.gt.1.and.dabs(r(i)-r(i-1)).lt.1.d-7) r(i)=r(i-1)
      if(qshear(i).gt.0.d0) qshear(i)=1.d0/qshear(i)
      if(qkappa(i).gt.0.d0) qkappa(i)=1.d0/qkappa(i)
      rho(i)=rho(i)/rhobar
      acon(i)=rho(i)*vph(i)*vph(i)/vn2
      ccon(i)=rho(i)*vpv(i)*vpv(i)/vn2
      lcon(i)=rho(i)*vsv(i)*vsv(i)/vn2
      ncon(i)=rho(i)*vsh(i)*vsh(i)/vn2
      fcon(i)=eta(i)*(acon(i)-2.d0*lcon(i))
      fmu(i)=(acon(i)+ccon(i)-2.d0*fcon(i)+5.d0*ncon(i)+
     1 6.d0*lcon(i))/15.d0
      flam(i)=(4.d0*(acon(i)+fcon(i)-ncon(i))+ccon(i))/9.d0
     +    -2.d0*fmu(i)/3.d0
      rat=4.d0*fmu(i)/(3.d0*(flam(i)+2.d0*fmu(i)))
      xlam(i)=((1.d0-rat)*qkappa(i)-.5d0*rat*qshear(i))/(1.d0-1.5d0*rat)
   45 xa2(i)=(1.d0-rat)*qkappa(i)+rat*qshear(i)

      call drspln(1,n,r,rho,qro,wrk)

c*** compute g *****
      call grav(g,rho,qro,r,n)

      call drspln(1,n,r,g,qg,wrk)
      call drspln(1,n,r,fcon,fspl,wrk)
      call drspln(1,n,r,lcon,lspl,wrk)
      if(ifanis.eq.0) goto 60
      call drspln(1,n,r,acon,aspl,wrk)
      call drspln(1,n,r,ccon,cspl,wrk)
      call drspln(1,n,r,ncon,nspl,wrk)
   60 nsl=n
      if(vsv(nsl).gt.0.d0) go to 70
   65 nsl=nsl-1
      if(vsv(nsl).le.0.d0) go to 65
   70 nicp1=nic+1
      nocp1=noc+1
      nslp1=nsl+1
      tref=0.5d0*tref/pi
      return
      end
      subroutine detqn(wdim,knt,det,ifeif)
c**** supevises the integration of the equations,it returns the value
c**** of the secular determinant as det and the count of zero crossings.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/a(14,1000),inorm(1000)
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      dimension ass(14),vf(1000),zi(4)
      iback=0
      w=wdim/wn
      wsq=w*w
      iexp=0
      kount=0
      kg=0
      fct=0.d0
      if(tref.gt.0.d0) fct=2.d0*dlog(tref*wdim)/pi
      goto (2,3,1,3),jcom
c========================================================
    1 if(wdim.le.wgrav) kg=1
      nvefm=2+kg*3
      nvesm=5+kg*9
      call sdepth(wdim,ls)
      if(ls.gt.nocp1) goto 25
      if(ls.gt.nicp1) goto 20
      if(ls.gt.2) goto 15
      r10=4.5d-4*(fl+.5d0)/wdim
      if(r10.ge.r(2)) goto 15
      r(1)=r10
      g(1)=rho(1)*r(1)*1.333333333333333d0
      ls=1
   15 call spsm(ls,nvesm,ass)
c*** propagate through inner core ***
      call sprpmn(ls,nic,ass,vf,nvesm,iexp)
      r(1)=0.d0
      g(1)=0.d0
      call sfbm(ass,kg,iback)
   20 is=max0(ls,nicp1)
      if(is.eq.ls) call fpsm(ls,nvefm,ass)
c*** propagate through outer core ***
      call fprpmn(is,noc,ass,vf,nvefm,iexp)
      call fsbm(ass,kg,iback)
   25 is=max0(ls,nocp1)
      if(is.eq.ls) call spsm(ls,nvesm,ass)
c*** propagate through mantle ***
      call sprpmn(is,nsl,ass,vf,nvesm,iexp)
      if(nsl.ne.n) goto 40
      dnorm=a(1,nsl)*a(1,nsl)
      do 26 i=2,nvesm
   26 dnorm=dnorm+a(i,nsl)*a(i,nsl)
      det=a(5,nsl)/dsqrt(dnorm)
      goto 45
   40 call sfbm(ass,kg,iback)
c*** propagate through ocean ***
      call fprpmn(nslp1,n,ass,vf,nvefm,iexp)
      if(kg.eq.0) det=a(2,n)/dsqrt(a(1,n)*a(1,n)+a(2,n)*a(2,n))
      if(kg.ne.0) det=a(5,n)/dsqrt(a(1,n)**2+a(2,n)**2+a(3,n)**2+
     +   a(4,n)**2+a(5,n)**2)
   45 if(ls.gt.noc) det=-det
      if(knsw.ne.1) goto 50
      if(ls.gt.noc) kount=kount-2
      irem=mod(kount,2)
      if(irem.eq.0.and.det.lt.0.d0) kount=kount+1
      if(irem.ne.0.and.det.gt.0.d0) kount=kount+1
      knt=kount
   50 if(ifeif.eq.0) return
c*** this does eigenfunction calculation for spheroidal modes ***
      iback=1
      jexp=0
      nbakf=1+kg*3
      nbaks=4+kg*10
      do 55 i=1,nbaks
   55 ass(i)=0.d0
      if(n.eq.nsl) goto 65
      if(kg.ne.0) goto 75
      ass(1)=dsign(1.d0,a(1,n))
      goto 80
   65 if(kg.eq.0) goto 75
      asi1=a(3,n)*a(3,n)+a(12,n)*a(12,n)
      asi2=a(4,n)*a(4,n)+a(11,n)*a(11,n)
      if(asi2.le.asi1) ass(1)=dsign(1.d0,a(3,n))
      if(asi2.gt.asi1) ass(2)=dsign(1.d0,a(2,n))
      goto 85
   75 asi1=a(3,n)*a(3,n)
      asi2=a(4,n)*a(4,n)
      if(asi2.le.asi1) ass(1)=dsign(1.d0,a(3,n))
      if(asi2.gt.asi1) ass(2)=dsign(1.d0,a(2,n))
      if(n.eq.nsl) goto 85
   80 call fprpmn(n,nslp1,ass,vf,nbakf,jexp)
      call fsbm(ass,kg,iback)
   85 nto=max0(ls,nocp1)
      call sprpmn(nsl,nto,ass,vf,nbaks,jexp)
      if(nto.eq.ls) goto 90
      call sfbm(ass,kg,iback)
      nto=max0(ls,nicp1)
      call fprpmn(noc,nto,ass,vf,nbakf,jexp)
      if(nto.eq.ls) goto 90
      call fsbm(ass,kg,iback)
      nto=max0(ls,2)
      call sprpmn(nic,nto,ass,vf,nbaks,jexp)
   90 if(dabs(det).gt.1.d-4) call remedy(ls)
      call eifout(ls)
      return
c*** radial modes ***
    2 ls=2
      call rps(ls,ass)
      call rprop(ls,n,ass)
      det=a(2,n)/dsqrt(a(1,n)*a(1,n)+a(2,n)*a(2,n))
      knt=kount-1
      if(ifeif.eq.0) return
      a(1,1)=0.d0
      a(2,1)=0.d0
      do 205 i=ls,n
      ff=fcon(i)*(1.d0+xlam(i)*fct)
      cc=ccon(i)*(1.d0+xa2(i)*fct)
  205 a(2,i)=(a(2,i)-2.d0*ff*a(1,i)/r(i))/cc
      zi(1)=0.d0
      zi(2)=0.d0
      zi(3)=0.d0
      do 210 i=ls,n
      im=i-1
  210 if(r(i).ne.r(im)) call gauslv(r(im),r(i),im,zi,3)
      rnrm=1.d0/(w*dsqrt(zi(1)))
      cg=0.d0
      qinv=zi(2)/(wsq*zi(1))
      wray=dsqrt(zi(3)/zi(1))
      do 215 i=2,n
      do 215 j=1,2
  215 a(j,i)=a(j,i)*rnrm
      return
c*** toroidal modes ***
    3 nb=nocp1
      n2=nsl
      ass(1)=1.d0
      ass(2)=0.d0
      if(jcom.eq.2) goto 300
      nb=2
      a(1,1)=0.d0
      a(2,1)=0.d0
      n2=nic
  300 q=0.d0
      ls=nb
      call startl(ls,n2,fmu,ls,q)
      if(ls.ne.nocp1) call tps(ls,ass)
      call tprop(ls,n2,ass)
      det=a(2,n2)/dsqrt(a(1,n2)*a(1,n2)+a(2,n2)*a(2,n2))
      if(ifeif.eq.0) goto 335
      do 305 i=ls,n2
  305 a(2,i)=a(1,i)/r(i)+a(2,i)/(lcon(i)*(1.d0+qshear(i)*fct))
      if(ls.eq.nb) goto 315
      ls1=ls-1
      do 310 i=nb,ls1
      a(1,i)=0.d0
  310 a(2,i)=0.d0
  315 do 320 i=1,4
  320 zi(i)=0.d0
      do 325 i=ls,n2
      im=i-1
  325 if(r(i).ne.r(im)) call gauslv(r(im),r(i),im,zi,4)
      rnrm=1.d0/(w*dsqrt(zi(1)))
      cg=(fl+0.5d0)*zi(2)/(w*zi(1))
      qinv=zi(3)/(wsq*zi(1))
      wray=dsqrt(zi(4)/zi(1))
      do 330 i=ls,n2
      do 330 j=1,2
  330 a(j,i)=a(j,i)*rnrm
      return
  335 if(knsw.ne.1) return
      knt=kount-1
      if(jcom.eq.4.or.l.eq.1) return
      irem=mod(knt,2)
      if(irem.eq.0.and.det.lt.0.d0) return
      if(irem.ne.0.and.det.gt.0.d0) return
      knt=knt+1
      return
      end
      subroutine sprpmn(jf,jl,f,h,nvesm,iexp)
c*** propagate a minor vector in a solid region from level jf to jl ***
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/ar(14,1000),inorm(1000)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,in
      dimension f(1),h(nvesm,1),s(14),fp(14),rne(6)
      data econst/1048576.d0/
      maxo1=maxo-1
      jud=1
      if(jl.lt.jf) jud=-1
      y=r(jf)
      i=jf
      go to 45
   10 x=y
      y=r(i)
      if(y.eq.x) goto 45
      iq=min0(i,i-jud)
      qff=1.d0+xlam(iq)*fct
      qll=1.d0+qshear(iq)*fct
      qaa=1.d0+xa2(iq)*fct
      zs=dmin1(x,y)
      xi=g(i)/y
      vpsq=(flam(i)+2.d0*fmu(i))/rho(i)
      vssq=fmu(i)/rho(i)
      alfsq=(wsq+4.d0*rho(i)+xi)/vpsq
      betasq=wsq/vssq
      delsq=dsqrt((betasq-alfsq)**2+4.d0*fl3*xi*xi/(vssq*vpsq))
      fksq=.5d0*(alfsq+betasq+delsq)-fl3/(x*x)
      qt=dsqrt(dabs(fksq))+dsqrt(dabs(fksq-delsq))+2.d0/zs
      q=(qt+float(kg)*sfl3/x)/stepf
      del=float(jud)*step(maxo)/q
      dxs=0.d0
   15 y=x+del
      if(float(jud)*(y-r(i)).gt.0.d0) y=r(i)
      dx=y-x
      if(dx.ne.dxs) call baylis(q,maxo1)
      dxs=dx
      do 30 j=1,nvesm
   30 s(j)=f(j)
      do 35 ni=1,in
      z=x+c(ni)
      call derms(iq,z,f,h(1,ni),0,qff,qll,qaa)
   35 call rkdot(f,s,h,nvesm,ni)
      if(knsw.ne.1) goto 40
      call derms(iq,y,f,fp,1,qff,qll,qaa)
      call zknt(s,h,f,fp,x,y,1)
   40 x=y
      if(y.ne.r(i)) goto 15
   45 size=dabs(f(1))
      do 50 j=2,nvesm
   50 size=dmax1(size,dabs(f(j)))
   55 if(size.lt.1024.d0) goto 65
      do 60 j=1,nvesm
   60 f(j)=f(j)/econst
      size=size/econst
      iexp=iexp+20
      goto 55
   65 if(iback.eq.0) goto 85
      inorm(i)=inorm(i)+iexp
      if(kg.eq.0) goto 70
      t1=f(4)+f(8)
      t2=t1+f(4)
      t1=t1+f(8)
      t3=f(8)-f(4)
      rne(1)=ar(6,i)*f(10)-ar(14,i)*f(9)+ar(13,i)*t3
     1      -ar(1,i)*f(7)-ar(7,i)*f(6)+ar(8,i)*f(5)
     2      +ar(12,i)*f(3)-ar(2,i)*f(2)+ar(3,i)*f(1)
      rne(2)=ar(6,i)*f(13)+ar(14,i)*t2+ar(13,i)*f(12)
     1      -ar(1,i)*f(11)-ar(9,i)*f(6)-ar(7,i)*f(5)
     2      +ar(11,i)*f(3)-ar(4,i)*f(2)-ar(2,i)*f(1)
      rne(3)=ar(6,i)*f(14)-ar(7,i)*t1-ar(8,i)*f(12)
     1      +ar(13,i)*f(11)-ar(9,i)*f(9)+ar(14,i)*f(7)
     2      +ar(10,i)*f(3)+ar(11,i)*f(2)+ar(12,i)*f(1)
      rne(4)=ar(14,i)*f(14)+ar(7,i)*f(13)+ar(12,i)*f(12)
     1      -ar(2,i)*f(11)-ar(9,i)*f(10)-ar(11,i)*t3
     2      +ar(4,i)*f(7)+ar(10,i)*f(5)+ar(5,i)*f(1)
      rne(5)=ar(13,i)*f(14)+ar(8,i)*f(13)-ar(12,i)*t2
     1      -ar(3,i)*f(11)+ar(7,i)*f(10)-ar(11,i)*f(9)
     2      -ar(2,i)*f(7)+ar(10,i)*f(6)+ar(5,i)*f(2)
      rne(6)=ar(1,i)*f(14)+ar(13,i)*f(13)-ar(2,i)*t1
     1      -ar(3,i)*f(12)+ar(14,i)*f(10)-ar(4,i)*f(9)
     2      -ar(11,i)*f(6)-ar(12,i)*f(5)+ar(5,i)*f(3)
      goto 75
   70 rne(1)=-ar(1,i)*f(3)+ar(2,i)*f(2)-ar(3,i)*f(1)
      rne(2)=-ar(1,i)*f(4)+ar(4,i)*f(2)+ar(2,i)*f(1)
      rne(3)=-ar(2,i)*f(4)+ar(4,i)*f(3)-ar(5,i)*f(1)
      rne(4)=-ar(3,i)*f(4)-ar(2,i)*f(3)-ar(5,i)*f(2)
   75 do 80 jj=1,6
   80 ar(jj,i)=rne(jj)
      goto 95
   85 inorm(i)=iexp
      do 90 j=1,nvesm
   90 ar(j,i)=f(j)
   95 if(i.eq.jl) return
      i=i+jud
      go to 10
      end
      subroutine fprpmn(jf,jl,f,h,nvefm,iexp)
c*** propagate the minor vector in a fluid region from level jf to jl ***
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/ar(14,1000),inorm(1000)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,in
      dimension f(1),h(nvefm,1),s(5),fp(5)
      data econst/1048576.d0/
      if(nvefm.eq.1) goto 85
      maxo1=maxo-1
      jud=1
      if(jl.lt.jf) jud=-1
      y=r(jf)
      i=jf
      go to 45
   10 x=y
      y=r(i)
      if(y.eq.x) goto 45
      iq=min0(i,i-jud)
      qff=1.d0+xlam(iq)*fct
      zs=dmin1(x,y)
      xi=g(i)/y
      alfsq=(wsq+4.d0*rho(i)+xi-fl3*xi*xi/wsq)*rho(i)/flam(i)
      q=(dsqrt(dabs(alfsq-fl3/(x*x)))+1.d0/zs+float(kg)*sfl3/x)/stepf
      del=float(jud)*step(maxo)/q
      dxs=0.d0
   15 y=x+del
      if(float(jud)*(y-r(i)).gt.0.d0) y=r(i)
      dx=y-x
      if(dx.ne.dxs) call baylis(q,maxo1)
      dxs=dx
      do 30 j=1,nvefm
   30 s(j)=f(j)
      do 35 ni=1,in
      z=x+c(ni)
      call dermf(iq,z,f,h(1,ni),0,qff)
   35 call rkdot(f,s,h,nvefm,ni)
      if(knsw.ne.1) goto 40
      call dermf(iq,y,f,fp,1,qff)
      call zknt(s,h,f,fp,x,y,0)
   40 x=y
      if(y.ne.r(i)) go to 15
   45 size=dabs(f(1))
      do 50 j=2,nvefm
   50 size=dmax1(size,dabs(f(j)))
   55 if(size.lt.1024.d0) goto 65
      do 60 j=1,nvefm
   60 f(j)=f(j)/econst
      size=size/econst
      iexp=iexp+20
      goto 55
   65 if(iback.eq.0) goto 70
      inorm(i)=inorm(i)+iexp
      rne2   =-ar(1,i)*f(4)+ar(4,i)*f(2)+ar(2,i)*f(1)
      ar(1,i)=-ar(1,i)*f(3)+ar(2,i)*f(2)-ar(3,i)*f(1)
      rne3   =-ar(2,i)*f(4)+ar(4,i)*f(3)-ar(5,i)*f(1)
      ar(4,i)=-ar(3,i)*f(4)-ar(2,i)*f(3)-ar(5,i)*f(2)
      ar(2,i)=rne2
      ar(3,i)=rne3
      goto 80
   70 inorm(i)=iexp
      do 75 j=1,nvefm
   75 ar(j,i)=f(j)
   80 if(i.eq.jl) return
      i=i+jud
      go to 10
   85 do 90 i=jl,jf
      inorm(i)=inorm(i)+iexp
      do 91 j=1,2
   91 ar(j,i)=ar(j,i)*f(1)
   90 continue
      return
      end
      subroutine derms(iq,z,f,fp,iknt,qff,qll,qaa)
c*** calculates minor vector derivative (fp) in a solid ***
      implicit real*8(a-h,o-z)
      real*8 nn,ll,lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension f(1),fp(1)
      if(iknt.ne.0) goto 19
      t=z-r(iq)
      if(t.ne.0.d0) goto 5
      ro=rho(iq)
      gr=g(iq)
      ff=fcon(iq)*qff
      ll=lcon(iq)*qll
      nn=ncon(iq)*qll
      cc=ccon(iq)*qaa
      aa=acon(iq)*qaa
      goto 15
    5 ro=rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq)))
      gr=g(iq)+t*(qg(1,iq)+t*(qg(2,iq)+t*qg(3,iq)))
      ff=(fcon(iq)+t*(fspl(1,iq)+t*(fspl(2,iq)+t*fspl(3,iq))))*qff
      ll=(lcon(iq)+t*(lspl(1,iq)+t*(lspl(2,iq)+t*lspl(3,iq))))*qll
      if(ifanis.ne.0) goto 10
      nn=ll
      cc=ff+ll+ll
      aa=cc
      goto 15
   10 nn=(ncon(iq)+t*(nspl(1,iq)+t*(nspl(2,iq)+t*nspl(3,iq))))*qll
      cc=(ccon(iq)+t*(cspl(1,iq)+t*(cspl(2,iq)+t*cspl(3,iq))))*qaa
      aa=(acon(iq)+t*(aspl(1,iq)+t*(aspl(2,iq)+t*aspl(3,iq))))*qaa
   15 zr=1.d0/z
      sfl3z=sfl3*zr
      rogr=ro*gr
      c11=1.d0/cc
      c22=1.d0/ll
      dmg=aa-nn-ff*ff*c11
      zdmg=zr*dmg
      t11=-2.d0*ff*zr*c11+zr
      t12=sfl3z*ff*c11
      t21=-sfl3z
      t22=zr+zr
      s22=-ro*wsq
      s11=s22+4.d0*zr*(zdmg-rogr)
      s22=s22+zr*zr*(fl3*(dmg+nn)-nn-nn)
      s12=sfl3z*(rogr-zdmg-zdmg)
      if(kg.ne.0) goto 25
      s11=s11+4.d0*ro*ro
      if(iback.eq.1) goto 20
      b11=t11+t22
      b33=t11-t22
      fp(1)=b11*f(1)+c22*f(3)-c11*f(4)
      fp(2)=s12*f(1)-t21*f(3)+t12*f(4)
   19 if(kg.ne.0) goto 29
      fp(3)=s22*f(1)-2.d0*t12*f(2)+b33*f(3)+c11*f(5)
      fp(4)=-s11*f(1)+2.d0*t21*f(2)-b33*f(4)-c22*f(5)
      fp(5)=-2.d0*s12*f(2)+s11*f(3)-s22*f(4)-b11*f(5)
      return
   20 fp(1)=t22*f(1)-t21*f(2)-c22*f(3)
      fp(2)=-t12*f(1)+t11*f(2)-c11*f(4)
      fp(3)=-s22*f(1)+s12*f(2)-t22*f(3)+t12*f(4)
      fp(4)=s12*f(1)-s11*f(2)+t21*f(3)-t11*f(4)
      return
   25 t31=-4.d0*ro
      t33=-fl*zr
      s13=-fl1*zr*ro
      s23=ro*sfl3z
      if(iback.eq.1) goto 30
      b11=t11+t22-t33
      b33=t11-t22-t33
      b44=t22-t11-t33
      b55=-t11-t22-t33
      b32=-t12-t12
      b42=t21+t21
      b52=-s12-s12
      b313=-s23-s23
      b414=s13+s13
      b914=t31+t31
      fp(1)=b11*f(1)+c22*f(3)-c11*f(4)
      fp(2)=s12*f(1)-t33*f(2)-t21*f(3)+t12*f(4)-s13*f(13)-s23*f(14)
      fp(6)=4.d0*f(1)-b55*f(6)+c22*f(8)-c11*f(9)
      fp(7)=4.d0*f(2)+s12*f(6)+t33*f(7)-t21*f(8)+t12*f(9)-t31*f(13)
      fp(8)=4.d0*f(3)+s22*f(6)+b32*f(7)-b44*f(8)+c11*f(10)
      fp(9)=4.d0*f(4)-s11*f(6)+b42*f(7)-b33*f(9)-c22*f(10)+b914*f(14)
      fp(10)=4.d0*f(5)+b52*f(7)+s11*f(8)-s22*f(9)-b11*f(10)+b914*f(12)
      fp(11)=-t31*f(2)+s13*f(7)+s23*f(9)-t11*f(11)+t21*f(12)
     +      -s11*f(13)+s12*f(14)
      fp(12)=t31*f(3)+s23*f(7)-s13*f(8)+t12*f(11)-t22*f(12)
     +      +s12*f(13)-s22*f(14)
      fp(13)=s23*f(6)-c11*f(11)+t11*f(13)-t12*f(14)
      fp(14)=-t31*f(1)+s13*f(6)-c22*f(12)-t21*f(13)+t22*f(14)
   29 fp(3)=s22*f(1)+b32*f(2)+b33*f(3)+c11*f(5)+b313*f(13)
      fp(4)=-s11*f(1)+b42*f(2)+b44*f(4)-c22*f(5)+b414*f(14)
      fp(5)=b52*f(2)+s11*f(3)-s22*f(4)+b55*f(5)-b313*f(11)+b414*f(12)
      return
   30 b11=t22+t33
      b22=t11+t33
      b33=t11+t22
      b55=t22-t33
      b66=t11-t33
      b99=t11-t22
      t4=f(4)+f(8)
      t5=t4+f(8)
      t4=t4+f(4)
      fp(1)=b11*f(1)-t21*f(2)-t31*f(3)-4.d0*f(5)+c22*f(7)
      fp(2)=-t12*f(1)+b22*f(2)-4.d0*f(6)+c11*f(11)
      fp(3)=b33*f(3)-c22*f(9)+c11*f(12)
      fp(4)=-s23*f(1)+s13*f(2)+t31*f(6)
      fp(5)=s13*f(3)+b55*f(5)-t21*f(6)-c22*f(10)
      fp(6)=s23*f(3)-t12*f(5)+b66*f(6)-c11*f(13)
      fp(7)=s22*f(1)-s12*f(2)-b55*f(7)+t31*f(9)+4.d0*f(10)+t12*f(11)
      fp(8)=s23*f(1)-s12*f(3)-t21*f(9)+t12*f(12)
      fp(9)=s23*f(2)-s22*f(3)-t12*t5+b99*f(9)-c11*f(14)
      fp(10)=s23*(f(4)-f(8))-s22*f(5)+s12*f(6)+s13*f(9)-b11*f(10)
     1      +t12*f(13)
      fp(11)=-s12*f(1)+s11*f(2)-t4*t31+t21*f(7)-b66*f(11)+4.d0*f(13)
      fp(12)=-s13*f(1)+s11*f(3)+t21*t5-t31*f(5)-b99*f(12)+c22*f(14)
      fp(13)=-t4*s13+s12*f(5)-s11*f(6)+t21*f(10)-s23*f(12)-b22*f(13)
      fp(14)=s12*t5-s13*f(7)-s11*f(9)+t31*f(10)-s23*f(11)+s22*f(12)
     1      -b33*f(14)
      return
      end
      subroutine dermf(iq,z,f,fp,iknt,qff)
c*** calculates minor vector derivative (fp) in a fluid ***
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension f(1),fp(1)
      if(iknt.ne.0) goto 14
      t=z-r(iq)
      if(t.ne.0.d0) goto 5
      ro=rho(iq)
      flu=fcon(iq)*qff
      gr=g(iq)
      goto 10
    5 ro=rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq)))
      flu=(fcon(iq)+t*(fspl(1,iq)+t*(fspl(2,iq)+t*fspl(3,iq))))*qff
      gr=g(iq)+t*(qg(1,iq)+t*(qg(2,iq)+t*qg(3,iq)))
   10 t21=-4.d0*ro
      zr=1.d0/z
      t12=fl3*zr*zr/wsq
      t11=gr*t12-zr
      s11=ro*(gr*gr*t12-wsq)+t21*gr*zr
      c11=-t12/ro+1.d0/flu
   14 if(kg.ne.0) goto 15
      fp(1)=t11*f(1)+c11*f(2)
      fp(2)=(s11-t21*ro)*f(1)-t11*f(2)
      return
   15 if(iknt.ne.0) goto 19
      t22=-fl*zr
      s22=ro*t12
      b11=t11+t22
      s12=ro*b11
      if(iback.eq.1) goto 20
      b33=t11-t22
      fp(1)=b11*f(1)+4.d0*f(3)-c11*f(4)
      fp(2)=s12*f(1)-t21*f(3)+t12*f(4)
   19 fp(3)=s22*f(1)-(t12+t12)*f(2)+b33*f(3)+c11*f(5)
      fp(4)=-s11*f(1)+(t21+t21)*f(2)-b33*f(4)-4.d0*f(5)
      fp(5)=-(s12+s12)*f(2)+s11*f(3)-s22*f(4)-b11*f(5)
      return
   20 fp(1)=t22*f(1)-t21*f(2)-4.d0*f(3)
      fp(2)=-t12*f(1)+t11*f(2)-c11*f(4)
      fp(3)=-s22*f(1)+s12*f(2)-t22*f(3)+t12*f(4)
      fp(4)=s12*f(1)-s11*f(2)+t21*f(3)-t11*f(4)
      return
      end
      subroutine eifout(lsmin)
c*** massages spheroidal mode eigenfunctions before output ***
      implicit real*8(a-h,o-z)
      real*8 ll,lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/a(14,1000),inorm(1000)
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      dimension zi(4)
      i1=min0(nic,max0(2,lsmin))
      i2=nic
    5 if(i1.eq.i2) goto 20
      do 10 iq=i1,i2
      ff=fcon(iq)*(1.d0+xlam(iq)*fct)
      ll=lcon(iq)*(1.d0+qshear(iq)*fct)
      zr=1.d0/r(iq)
      sfl3z=sfl3*zr
      d=1.d0/(ccon(iq)*(1.d0+xa2(iq)*fct))
      v=a(2,iq)
      if(kg.ne.0) goto 15
      a(2,iq)=(zr-2.d0*ff*d*zr)*a(1,iq)+sfl3z*ff*d*v+d*a(3,iq)
      a(4,iq)=-sfl3z*a(1,iq)+(zr+zr)*v+a(4,iq)/ll
      a(5,iq)=0.d0
      a(6,iq)=0.d0
      goto 10
   15 a(2,iq)=(zr-2.d0*ff*d*zr)*a(1,iq)+sfl3z*ff*d*v+d*a(4,iq)
      a(4,iq)=-sfl3z*a(1,iq)+(zr+zr)*v+a(5,iq)/ll
      a(5,iq)=a(3,iq)
      a(6,iq)=4.d0*(a(6,iq)-rho(iq)*a(1,iq))-fl*zr*a(5,iq)
   10 a(3,iq)=v
   20 if(i2.eq.nsl) goto 25
      i1=min0(nsl,max0(lsmin,nocp1))
      i2=nsl
      goto 5
   25 i1=min0(noc,max0(lsmin,nicp1))
      i2=noc
   30 if(i1.eq.i2) goto 50
      do 35 iq=i1,i2
      zr=1.d0/r(iq)
      sfl3z=sfl3*zr
      ffi=1.d0/(flam(iq)*(1.d0+xlam(iq)*fct))
      if(kg.ne.0) goto 40
      p=a(2,iq)
      a(5,iq)=0.d0
      a(6,iq)=0.d0
      goto 45
   40 p=a(3,iq)
      a(5,iq)=a(2,iq)
      a(6,iq)=4.d0*(a(4,iq)-rho(iq)*a(1,iq))-fl*zr*a(5,iq)
   45 a(3,iq)=sfl3z*(g(iq)*a(1,iq)-p/rho(iq)+a(5,iq))/wsq
      a(2,iq)=sfl3z*a(3,iq)-a(1,iq)*zr+p*ffi
   35 a(4,iq)=sfl3z*(a(1,iq)+p*(qro(1,iq)/(rho(iq)**2)+g(iq)*ffi)/wsq)
   50 if(n.eq.nsl.or.i2.eq.n) goto 55
      i1=nslp1
      i2=n
      goto 30
   55 imax=0
      do 60 iq=lsmin,n
   60 imax=max0(inorm(iq),imax)
      do 65 iq=lsmin,n
      iexp=inorm(iq)-imax
      al=0.d0
      if(iexp.ge.-80) al=2.d0**iexp
      do 65 j=1,6
   65 a(j,iq)=a(j,iq)*al
      lsm1=max0(1,lsmin-1)
      do 70 i=1,lsm1
      do 70 j=1,6
   70 a(j,i)=0.d0
      if(l.gt.1.or.lsmin.gt.2) goto 75
      a(2,1)=1.5d0*a(1,2)/r(2)-.5d0*a(2,2)
      a(4,1)=1.5d0*a(3,2)/r(2)-.5d0*a(4,2)
   75 do 80 j=1,4
   80 zi(j)=0.d0
      i1=max0(lsmin,2)
      do 85 iq=i1,n
      ip=iq-1
   85 if(r(iq).ne.r(ip)) call gauslv(r(ip),r(iq),ip,zi,4)
      cg=zi(2)/(w*zi(1))
      wray=dsqrt(2.d0*zi(4)/zi(1))
      qinv=2.d0*zi(3)/(wsq*zi(1))
      rnorm=1.d0/(w*dsqrt(zi(1)))
      do 90 iq=i1,n
      zr=1.d0/r(iq)
      a(1,iq)=a(1,iq)*zr
      a(2,iq)=(a(2,iq)-a(1,iq))*zr
      a(3,iq)=a(3,iq)*zr
      a(4,iq)=(a(4,iq)-a(3,iq))*zr
      a(5,iq)=a(5,iq)*zr
      a(6,iq)=(a(6,iq)-a(5,iq))*zr
      a(1,iq)=a(1,iq)*rnorm
      a(2,iq)=a(2,iq)*rnorm
      a(3,iq)=a(3,iq)*rnorm
      a(4,iq)=a(4,iq)*rnorm
      a(5,iq)=a(5,iq)*rnorm
   90 a(6,iq)=a(6,iq)*rnorm
      if(lsmin.gt.2.or.l.gt.2) return
      if(l.eq.2) goto 95
      a(1,1)=a(1,2)-.5d0*a(2,2)*r(2)
      a(2,1)=0.d0
      a(3,1)=a(3,2)-.5d0*a(4,2)*r(2)
      a(4,1)=0.d0
      a(6,1)=1.5d0*a(5,2)/r(2)-.5d0*a(6,2)
      return
   95 a(2,1)=1.5d0*a(1,2)/r(2)-.5d0*a(2,2)
      a(4,1)=1.5d0*a(3,2)/r(2)-.5d0*a(4,2)
      return
      end
      subroutine gauslv(r1,r2,iq,fint,nint)
c*** fifth order gauss-legendre integration ***
      implicit real*8(a-h,o-z)
      dimension fint(1),vals(4),vals1(4),sum(4),w(2),x(2)
      data w,x/.478628670499366d0,.236926885056189d0,
     +         .538469310105683d0,.906179845938664d0/
      y1=.5d0*(r2+r1)
      y2=.5d0*(r2-r1)
      call intgds(y1,iq,vals)
      do 5 j=1,nint
    5 sum(j)=.568888888888889d0*vals(j)
      do 10 i=1,2
      t1=x(i)*y2
      call intgds(y1+t1,iq,vals)
      call intgds(y1-t1,iq,vals1)
      do 10 j=1,nint
   10 sum(j)=sum(j)+w(i)*(vals(j)+vals1(j))
      do 15 j=1,nint
   15 fint(j)=fint(j)+y2*sum(j)
      return
      end
      subroutine sdepth(wdim,ls)
c*** finds starting level,ls, for a given l and w ***
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      data aw,bw,dw/-2.d-3,2.25d-3,1.28d-3/
      q=0.d0
      w=wdim/wn
      wsoc=aw+dw*fl
      if(wdim.gt.wsoc) goto 10
      call startl(nocp1,nsl,fmu,ls,q)
      if(ls.eq.nsl) ls=ls-1
      if(ls.gt.nocp1) return
   10 wsic=aw+bw*fl
      if(wdim.gt.wsic) goto 20
      call startl(nicp1,noc,flam,ls,q)
      if(ls.eq.noc) ls=ls-1
      if(ls.gt.nicp1) return
   20 call startl(2,nic,fmu,ls,q)
      if(ls.eq.nic) ls=ls-1
      return
      end
      subroutine sfbm(ass,kg,iback)
c*** convert minor vector at a solid/fluid boundary ***
      implicit real*8(a-h,o-z)
      dimension ass(14),as(14)
      do 10 j=1,14
      as(j)=ass(j)
   10 ass(j)=0.d0
      if(iback.eq.1) goto 30
      if(kg.ne.0) goto 20
      ass(1)=as(3)
      ass(2)=as(5)
      return
   20 ass(1)=as(8)
      ass(2)=-as(12)
      ass(3)=as(3)
      ass(4)=-as(10)
      ass(5)=as(5)
      return
   30 if(kg.ne.0) goto 40
      ass(1)=-as(3)
      return
   40 ass(1)=as(7)
      ass(2)=-as(9)
      ass(3)=-as(10)
      ass(4)=-as(14)
      return
      end
      subroutine fsbm(ass,kg,iback)
c*** convert minor vector at a fluid/solid boundary ***
      implicit real*8(a-h,o-z)
      dimension ass(14),as(14)
      do 10 j=1,14
      as(j)=ass(j)
   10 ass(j)=0.d0
      if(iback.eq.1) goto 30
      if(kg.ne.0) goto 20
      ass(1)=as(1)
      ass(4)=-as(2)
      return
   20 ass(6)=as(1)
      ass(14)=as(2)
      ass(1)=as(3)
      ass(9)=as(4)
      ass(4)=-as(5)
      return
   30 if(kg.ne.0) goto 40
      ass(1)=-as(1)
      return
   40 ass(1)=-as(1)
      ass(3)=-as(2)
      ass(5)=-as(3)
      ass(12)=as(4)
      return
      end
      subroutine zknt(s,sp,f,fp,x,y,ifsol)
c*** given minor vector and derivs,constructs mode count ***
      implicit real*8(a-h,o-z)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension s(1),sp(1),f(1),fp(1),xs(4),val(4)
      if(ifsol.eq.0.and.kg.eq.0) goto 5
      y1=s(5)
      y2=f(5)
      y1p=sp(5)
      y2p=fp(5)
      t1=s(3)-s(4)
      t2=f(3)-f(4)
      t1p=sp(3)-sp(4)
      t2p=fp(3)-fp(4)
      goto 10
    5 y1=s(2)
      y2=f(2)
      y1p=sp(2)
      y2p=fp(2)
      t1=s(1)
      t2=f(1)
      t1p=sp(1)
      t2p=fp(1)
   10 h=y-x
      ns=0
      if(kount.ne.0) goto 15
      a1=y2-y1
      a2=0.d0
      a3=0.d0
      a22=0.d0
      a33=0.d0
      goto 50
   15 a1=h*y1p
      a2=-h*(2.d0*y1p+y2p)+3.d0*(y2-y1)
      a3=h*(y1p+y2p)-2.d0*(y2-y1)
      a33=3.d0*a3
      a22=2.d0*a2
      if(a3.ne.0.d0) goto 20
      if(a2.eq.0.d0) goto 50
      xs(2)=-a1/a22
      if(xs(2).ge.0.d0.and.xs(2).le.1.d0) ns=1
      goto 50
   20 disc=a2*a2-a1*a33
      if(disc) 50,25,30
   25 xs(2)=-a2/a33
      if(xs(2).ge.0.d0.and.xs(2).le.1.d0) ns=1
      goto 50
   30 disc=dsqrt(disc)
      tr1=(-a2+disc)/a33
      tr2=(-a2-disc)/a33
      if(dabs(a33).gt.dabs(a1)) goto 35
      fac=a1/a33
      tr1=fac/tr1
      tr2=fac/tr2
   35 if(tr1.lt.0.d0.or.tr1.gt.1.d0) goto 40
      xs(2)=tr1
      ns=1
   40 if(tr2.lt.0.d0.or.tr2.gt.1.d0) goto 50
      ns=ns+1
      xs(ns+1)=tr2
      if(ns.lt.2) goto 50
      if(tr2.ge.tr1) goto 50
      xs(2)=tr2
      xs(3)=tr1
   50 val(1)=y1
      xs(1)=0.d0
      ns2=ns+2
      val(ns2)=y2
      xs(ns2)=1.d0
      if(ns.eq.0) goto 60
      ns1=ns+1
      do 55 j=2,ns1
      t=xs(j)
   55 val(j)=y1+t*(a1+t*(a2+t*a3))
   60 ift=0
      do 100 j=2,ns2
      if(val(j-1)*val(j).gt.0.d0) goto 100
      if(val(j-1).ne.0.d0) goto 65
      tes=t1*a1
      goto 90
   65 rt1=0.5d0*(xs(j-1)+xs(j))
      rt=rt1
      do 70 i=1,5
      v=y1+rt*(a1+rt*(a2+rt*a3))
      vp=a1+rt*(a22+rt*a33)
      add=-v/vp
      rt=rt+add
      if(dabs(add).lt.1.d-5) goto 75
      if(dabs(rt-rt1).le..5d0) goto 70
      rt=rt1
      goto 75
   70 continue
   75 if(ift.ne.0) goto 85
      if(kount.ne.0) goto 80
      b1=t2-t1
      b2=0.d0
      b3=0.d0
      goto 85
   80 b1=h*t1p
      b2=-h*(2.d0*t1p+t2p)+3.d0*(t2-t1)
      b3=h*(t1p+t2p)-2.d0*(t2-t1)
      ift=1
   85 tes=t1+rt*(b1+rt*(b2+rt*b3))
      vp=a1+rt*(a22+rt*a33)
      tes=tes*vp
   90 if(tes.lt.0.d0) kount=1+kount
      if(tes.gt.0.d0) kount=kount-1
  100 continue
      return
      end
      subroutine baylis(q,maxo1)
c    baylis returns the coefficients for rks integration.
c    see e. baylis shanks(1966 a. m. s.) and references therein for the
c    coefficients. the eight runge-kutta-shanks formulae are (1-1) (2-2)
c    (3-3) (4-4) (5-5) (6-6) (7-7) (8-10). for orders greater than 4 the
c    formulae are approximate rather than exact so incurring less roundoff.
      implicit real*8(a-h,o-z)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,i
      ds=q*dabs(dx)
      do 10 j=1,maxo1
      if(ds.gt.step(j)) go to 10
      i=j
      go to 15
   10 continue
      i=maxo
   15 c(1)=0.d0
      go to (1,2,3,4,5,6,7,8),i
    1 b(1)=dx
      return
    2 c(2)=dx
      b(1)=dx
      b(2)=.5d0*dx
      b(3)=1.d0
      return
    3 c(2)=.5d0*dx
      c(3)=dx
      b(1)=c(2)
      b(2)=-dx
      b(3)=-2.d0
      b(4)=.16666666666667d0*dx
      b(5)=4.d0
      b(6)=1.d0
      return
    4 c(2)=.01d0*dx
      c(3)=.6d0*dx
      c(4)=dx
      b(1)=c(2)
      b( 2)=-.17461224489790d+02*dx
      b( 3)=-.10343618513324d+01
      b( 4)= .59691275167780d+02*dx
      b( 5)=-.10140620414448d+01
      b( 6)= .30814908546230d-01
      b( 7)=-.25555555555556d+01*dx
      b( 8)=-.11165449632656d+01
      b( 9)=-.22568165070006d+00
      b(10)=-.49077733860351d-01
      return
    5 c( 2)= 1.1111111111111d-04*dx
      c( 3)= 3.0d-01*dx
      c( 4)= 7.5d-01*dx
      c( 5)= dx
      b( 1)=c(2)
      b( 2)=-.40470000000000d+03*dx
      b( 3)=-.10007412898443d+01
      b( 4)= .25301250000000d+04*dx
      b( 5)=-.10004446420631d+01
      b( 6)= .74107010523195d-03
      b( 7)=-.11494333333333d+05*dx
      b( 8)=-.10004929965491d+01
      b( 9)= .52629261224803d-03
      b(10)=-.12029545422812d-03
      b(11)= .92592592592593d-01*dx
      b(12)= .00000000000000d+00
      b(13)= .47619047619048d+01
      b(14)= .42666666666667d+01
      b(15)= .77142857142857d+00
      return
    6 c(2)=3.3333333333333d-03*dx
      c(3)=.2d0*dx
      c(4)=.6d0*dx
      c(5)=9.3333333333333d-01*dx
      c(6)=dx
      b( 1)=c(2)
      b( 2)=-.58000000000000d+01*dx
      b( 3)=-.10344827586207d+01
      b( 4)= .64600000000000d+02*dx
      b( 5)=-.10216718266254d+01
      b( 6)= .30959752321982d-01
      b( 7)=-.62975802469136d+03*dx
      b( 8)=-.10226149961576d+01
      b( 9)= .24906685695466d-01
      b(10)=-.37737402568887d-02
      b(11)=-.54275714285714d+04*dx
      b(12)=-.10225567867765d+01
      b(13)= .25375487829097d-01
      b(14)=-.31321559234596d-02
      b(15)= .12921040478749d-03
      b(16)= .53571428571429d-01*dx
      b(17)= .00000000000000d+00
      b(18)= .61868686868687d+01
      b(19)= .77777777777778d+01
      b(20)= .40909090909091d+01
      b(21)=-.38888888888889d+00
      return
    7 c(2)=5.2083333333333d-03*dx
      c(3)=1.6666666666667d-01*dx
      c(4)=.5d0*dx
      c(5)=dx
      c(6)=8.3333333333333d-01*dx
      c(7)=dx
      b( 1)=c(2)
      b( 2)=-.25000000000000d+01*dx
      b( 3)=-.10666666666667d+01
      b( 4)= .26166666666667d+02*dx
      b( 5)=-.10421204027121d+01
      b( 6)= .61228682966918d-01
      b( 7)=-.64500000000000d+03*dx
      b( 8)=-.10450612653163d+01
      b( 9)= .51262815703925d-01
      b(10)=-.77519379844961d-02
      b(11)=-.93549382716049d+02*dx
      b(12)=-.10450293206756d+01
      b(13)= .48394546673620d-01
      b(14)=-.11877268228307d-01
      b(15)=-.39590894094358d-03
      b(16)= .35111904761905d+03*dx
      b(17)=-.10446476812124d+01
      b(18)= .52479782656724d-01
      b(19)=-.71200922221468d-02
      b(20)=-.61029361904114d-03
      b(21)= .27463212856852d-02
      b(22)= .46666666666667d-01*dx
      b(23)= .57857142857143d+01
      b(24)= .78571428571429d+01
      b(25)= .00000000000000d+00
      b(26)= b(23)
      b(27)= .10000000000000d+01
      return
    8 c(2)=.14814814814815d0*dx
      c(3)=.22222222222222d0*dx
      c(4)=.33333333333333d0*dx
      c(5)= .5d0*dx
      c(6)=.66666666666667d0*dx
      c(7)=.16666666666667d0*dx
      c(8)=dx
      c(9)=.83333333333333d0*dx
      c(10)=dx
      b( 1)=c(2)
      b( 2)= .55555555555556d-01*dx
      b( 3)= .30000000000000d+01
      b( 4)= .83333333333333d-01*dx
      b( 5)= .00000000000000d+00
      b( 6)= .30000000000000d+01
      b( 7)= .12500000000000d+00*dx
      b( 8)= .00000000000000d+00
      b( 9)= .00000000000000d+00
      b(10)= .30000000000000d+01
      b(11)= .24074074074074d+00*dx
      b(12)= .00000000000000d+00
      b(13)=-.20769230769231d+01
      b(14)= .32307692307692d+01
      b(15)= .61538461538461d+00
      b(16)= .90046296296295d-01*dx
      b(17)= .00000000000000d+00
      b(18)=-.13881748071980d+00
      b(19)= .24832904884319d+01
      b(20)=-.21182519280206d+01
      b(21)= .62467866323908d+00
      b(22)=-.11550000000000d+02*dx
      b(23)=-.35064935064935d+00
      b(24)= .50389610389610d+01
      b(25)=-.28398268398268d+01
      b(26)= .52813852813853d+00
      b(27)=-.34632034632035d+01
      b(28)=-.44097222222222d+00*dx
      b(29)=-.14173228346457d+00
      b(30)= .53385826771654d+01
      b(31)=-.35905511811023d+01
      b(32)= .70866141732284d-01
      b(33)=-.45354330708661d+01
      b(34)=-.31496062992126d-01
      b(35)= .18060975609756d+01*dx
      b(36)=-.54692775151925d-01
      b(37)= .47967589466576d+01
      b(38)=-.22795408507765d+01
      b(39)= .48615800135044d-01
      b(40)=-.34031060094530d+01
      b(41)=-.40513166779204d-01
      b(42)= .48615800135044d+00
      b(43)= .48809523809524d-01*dx
      b(44)= .65853658536585d+00
      b(45)= .66341463414634d+01
      b(46)= .52682926829268d+01
      i=10
      return
      end
      subroutine grav(g,rho,qro,r,n)
c*** given rho and spline coeffs,computes gravity ***
      implicit real*8(a-h,o-z)
      dimension g(1),rho(1),qro(3,1),r(1)
      g(1)=0.d0
      do 10 i=2,n
      im1=i-1
      del=r(i)-r(im1)
      rn2=r(im1)*r(im1)
      trn=2.d0*r(im1)
      c1=rho(im1)*rn2
      c2=(qro(1,im1)*rn2+trn*rho(im1))*0.5d0
      c3=(qro(2,im1)*rn2+trn*qro(1,im1)+rho(im1))/3.d0
      c4=(qro(3,im1)*rn2+trn*qro(2,im1)+qro(1,im1))*.25d0
      c5=(trn*qro(3,im1)+qro(2,im1))*0.2d0
   10 g(i)=(g(im1)*rn2+4.d0*del*(c1+del*(c2+del*(c3+del*(c4+del*
     +    (c5+del*qro(3,im1)/6.d0))))))/(r(i)*r(i))
      return
      end
      subroutine startl(jf,jl,v,ls,q)
c*** finds start level between jf and jl using velocityv and ang. ord. l.
c*** upon entry q is the value of the exponent at r(jf) or at the turning
c*** point(q=0) depending on previous calls to startl. upon exit q is the
c*** value of the exponent at the starting level ls.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      dimension rrlog(1000),p(1000),v(1)
      data ifirst/1/
	save vertno
      if(ifirst.ne.1) goto 5
      ifirst=0
      vertno=-dlog(eps)

      do 1 i=3,n
    1 rrlog(i)=.5d0*dlog(r(i)/r(i-1))
    5 do 10 j=jf,jl
      pp=fl3-wsq*r(j)*r(j)*rho(j)/v(j)
      if(pp.le.0.d0) goto 15
   10 p(j)=dsqrt(pp)
   15 p(j)=0.d0
   20 k=j
      j=j-1
      if(j.le.jf) go to 25
      q=q+rrlog(k)*(p(j)+p(k))

      if(q.lt.vertno) go to 20
      ls=j
      return
   25 ls=jf
      return
      end
c============================================================
      subroutine steps(eps)
c*** computes 8 dimensionless step sizes for rks integration
      implicit real*8(a-h,o-z)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,in
      ps=dlog(eps)
      fac=1.d0
      do 2 n=1,8
      fn=n+1
      fac=fac*fn
      x=(dlog(fac)+ps)/fn
      x=dexp (x)
      s=x
      do 1 i=1,n
    1 s=x*dexp(-s/fn)
    2 step(n)=s
      return
      end
      subroutine drspln(i1,i2,x,y,q,f)
      implicit real*8(a-h,o-z)
c   rspln computes cubic spline interpolation coefficients
c   for y(x) between grid points i1 and i2 saving them in q.  the
c   interpolation is continuous with continuous first and second
c   derivitives.  it agrees exactly with y at grid points and with the
c   three point first derivitives at both end points (i1 and i2).
c   x must be monotonic but if two successive values of x are equal
c   a discontinuity is assumed and seperate interpolation is done on
c   each strictly monotonic segment.  the arrays must be dimensioned at
c   least - x(i2), y(i2), q(3,i2), and f(3,i2).  f is working storage
c   for rspln.
c                                                     -rpb
      dimension x(1),y(1),q(3,1),f(3,1),yy(3)
      equivalence (yy(1),y0)
      data yy/3*0.d0/
      j1=i1+1
      y0=0.d0
c   bail out if there are less than two points total.
      if(i2-i1)13,17,8
 8    a0=x(j1-1)
c   search for discontinuities.
      do 3 i=j1,i2
      b0=a0
      a0=x(i)
      if(a0-b0)3,4,3
 3    continue
 17   j1=j1-1
      j2=i2-2
      go to 5
 4    j1=j1-1
      j2=i-3
c   see if there are enough points to interpolate (at least three).
 5    if(j2+1-j1)9,10,11
c   only two points.  use linear interpolation.
 10   j2=j2+2
      y0=(y(j2)-y(j1))/(x(j2)-x(j1))
      do 15 j=1,3
      q(j,j1)=yy(j)
 15   q(j,j2)=yy(j)
      go to 12
c   more than two points.  do spline interpolation.
 11   a0=0.d0
      h=x(j1+1)-x(j1)
      h2=x(j1+2)-x(j1)
      y0=h*h2*(h2-h)
      h=h*h
      h2=h2*h2
c   calculate derivitive at near end.
      b0=(y(j1)*(h-h2)+y(j1+1)*h2-y(j1+2)*h)/y0
      b1=b0
c   explicitly reduce banded matrix to an upper banded matrix.
      do 1 i=j1,j2
      h=x(i+1)-x(i)
      y0=y(i+1)-y(i)
      h2=h*h
      ha=h-a0
      h2a=h-2.d0*a0
      h3a=2.d0*h-3.*a0
      h2b=h2*b0
      q(1,i)=h2/ha
      q(2,i)=-ha/(h2a*h2)
      q(3,i)=-h*h2a/h3a
      f(1,i)=(y0-h*b0)/(h*ha)
      f(2,i)=(h2b-y0*(2.d0*h-a0))/(h*h2*h2a)
      f(3,i)=-(h2b-3.d0*y0*ha)/(h*h3a)
      a0=q(3,i)
 1    b0=f(3,i)
c   take care of last two rows.
      i=j2+1
      h=x(i+1)-x(i)
      y0=y(i+1)-y(i)
      h2=h*h
      ha=h-a0
      h2a=h*ha
      h2b=h2*b0-y0*(2.d0*h-a0)
      q(1,i)=h2/ha
      f(1,i)=(y0-h*b0)/h2a
      ha=x(j2)-x(i+1)
      y0=-h*ha*(ha+h)
      ha=ha*ha
c   calculate derivitive at far end.
      y0=(y(i+1)*(h2-ha)+y(i)*ha-y(j2)*h2)/y0
      q(3,i)=(y0*h2a+h2b)/(h*h2*(h-2.d0*a0))
      q(2,i)=f(1,i)-q(1,i)*q(3,i)
c   solve upper banded matrix by reverse iteration.
      do 2 j=j1,j2
      k=i-1
      q(1,i)=f(3,k)-q(3,k)*q(2,i)
      q(3,k)=f(2,k)-q(2,k)*q(1,i)
      q(2,k)=f(1,k)-q(1,k)*q(3,k)
 2    i=k
      q(1,i)=b1
c   fill in the last point with a linear extrapolation.
 9    j2=j2+2
      do 14 j=1,3
 14   q(j,j2)=yy(j)
c   see if this discontinuity is the last.
 12   if(j2-i2)6,13,13
c   no.  go back for more.
 6    j1=j2+2
      if(j1-i2)8,8,7
c   there is only one point left after the latest discontinuity.
 7    do 16 j=1,3
 16   q(j,i2)=yy(j)
c   fini.
 13   return
      end
      subroutine dsplin(n,x,y,q,f)
      implicit real*8(a-h,o-z)
      dimension x(1),y(1),q(3,1),f(3,1),yy(3)
      equivalence (yy(1),y0)
      data yy/3*0.d0/
      a0=0.d0
      j2=n-2
      h=x(2)-x(1)
      h2=x(3)-x(1)
      y0=h*h2*(h2-h)
      h=h*h
      h2=h2*h2
      b0=(y(1)*(h-h2)+y(2)*h2-y(3)*h)/y0
      b1=b0
      do 5 i=1,j2
      h=x(i+1)-x(i)
      y0=y(i+1)-y(i)
      h2=h*h
      ha=h-a0
      h2a=h-2.d0*a0
      h3a=2.d0*h-3.*a0
      h2b=h2*b0
      q(1,i)=h2/ha
      q(2,i)=-ha/(h2a*h2)
      q(3,i)=-h*h2a/h3a
      f(1,i)=(y0-h*b0)/(h*ha)
      f(2,i)=(h2b-y0*(2.d0*h-a0))/(h*h2*h2a)
      f(3,i)=-(h2b-3.d0*y0*ha)/(h*h3a)
      a0=q(3,i)
    5 b0=f(3,i)
      i=j2+1
      h=x(i+1)-x(i)
      y0=y(i+1)-y(i)
      h2=h*h
      ha=h-a0
      h2a=h*ha
      h2b=h2*b0-y0*(2.d0*h-a0)
      q(1,i)=h2/ha
      f(1,i)=(y0-h*b0)/h2a
      ha=x(j2)-x(i+1)
      y0=-h*ha*(ha+h)
      ha=ha*ha
      y0=(y(i+1)*(h2-ha)+y(i)*ha-y(j2)*h2)/y0
      q(3,i)=(y0*h2a+h2b)/(h*h2*(h-2.d0*a0))
      q(2,i)=f(1,i)-q(1,i)*q(3,i)
      do 10 j=1,j2
      k=i-1
      q(1,i)=f(3,k)-q(3,k)*q(2,i)
      q(3,k)=f(2,k)-q(2,k)*q(1,i)
      q(2,k)=f(1,k)-q(1,k)*q(3,k)
   10 i=k
      q(1,i)=b1
      do 15 j=1,3
   15 q(j,n)=yy(j)
      return
      end
      subroutine trknt(y1,y1p,y2,y2p,x,y)
c*** toroidal and radial mode counter ***
      implicit real*8(a-h,o-z)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension xs(2),val(4)
      ns=0
      if(kount.eq.0) goto 60
      h=y-x
      a1=h*y1p
      a2=-h*(2.d0*y1p+y2p)+3.d0*(y2-y1)
      a3=h*(y1p+y2p)-2.d0*(y2-y1)
      a33=3.d0*a3
      a22=2.d0*a2
      if(a3.ne.0.d0) goto 20
      if(a2.eq.0.d0) goto 50
      xs(1)=-a1/a22
      if(xs(1).ge.0.d0.and.xs(1).le.1.d0) ns=1
      goto 50
   20 disc=a2*a2-a1*a33
      if(disc) 50,25,30
   25 xs(1)=-a2/a33
      if(xs(1).ge.0.d0.and.xs(1).le.1.d0) ns=1
      goto 50
   30 disc=dsqrt(disc)
      tr1=(-a2+disc)/a33
      tr2=(-a2-disc)/a33
      if(dabs(a33).gt.dabs(a1)) goto 35
      fac=a1/a33
      tr1=fac/tr1
      tr2=fac/tr2
   35 if(tr1.lt.0.d0.or.tr1.gt.1.d0) goto 40
      xs(1)=tr1
      ns=1
   40 if(tr2.lt.0.d0.or.tr2.gt.1.d0) goto 50
      ns=ns+1
      xs(ns)=tr2
      if(ns.lt.2) goto 50
      if(tr2.ge.tr1) goto 50
      xs(1)=tr2
      xs(2)=tr1
   50 if(ns.eq.0) goto 60
      ns1=ns+1
      do 55 j=2,ns1
      t=xs(j-1)
   55 val(j)=y1+t*(a1+t*(a2+t*a3))
   60 val(1)=y1
      ns2=ns+2
      val(ns2)=y2
      do 100 j=2,ns2
  100 if(val(j-1)*val(j).le.0.d0) kount=kount+1
      if(val(1).eq.0.d0) kount=kount-1
      return
      end
      subroutine rprop(jf,jl,f)
c*** propagates soln ,f, for radial modes from jf to jl ***
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl,nn,ll
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/a(14,1000),inorm(1000)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,in
      dimension h(2,10),s(2),f(2)
      maxo1=maxo-1
      y=r(jf)
      vy=dsqrt((flam(jf)+2.d0*fmu(jf))/rho(jf))
      i=jf
      go to 50
   10 iq=i
      i=i+1
      x=y
      y=r(i)
      if(y.eq.x) goto 50
      qff=1.d0+xlam(iq)*fct
      qll=1.d0+qshear(iq)*fct
      qaa=1.d0+xa2(iq)*fct
      vx=vy
      vy=dsqrt((flam(i)+2.d0*fmu(i))/rho(i))
      q=dmax1(w/vx+1.d0/x,w/vy+1.d0/y)
      del=step(maxo)/q
      dxs=0.d0
   15 y=x+del
      if(y.gt.r(i)) y=r(i)
      dx=y-x
      if(dx.ne.dxs) call baylis(q,maxo1)
      dxs=dx
      s(1)=f(1)
      s(2)=f(2)
      do 40 ni=1,in
      z=x+c(ni)
      t=z-r(iq)
      ro=rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq)))
      gr=g(iq)+t*(qg(1,iq)+t*(qg(2,iq)+t*qg(3,iq)))
      ff=(fcon(iq)+t*(fspl(1,iq)+t*(fspl(2,iq)+t*fspl(3,iq))))*qff
      if(ifanis.ne.0) goto 30
      nn=(lcon(iq)+t*(lspl(1,iq)+t*(lspl(2,iq)+t*lspl(3,iq))))*qll
      cc=ff+nn+nn
      aa=cc
      goto 35
   30 nn=(ncon(iq)+t*(nspl(1,iq)+t*(nspl(2,iq)+t*nspl(3,iq))))*qll
      cc=(ccon(iq)+t*(cspl(1,iq)+t*(cspl(2,iq)+t*cspl(3,iq))))*qaa
      aa=(acon(iq)+t*(aspl(1,iq)+t*(aspl(2,iq)+t*aspl(3,iq))))*qaa
   35 z=1.d0/z
      a21=-ro*wsq+4.d0*z*(z*(aa-nn-ff*ff/cc)-ro*gr)
      h(1,ni)=(f(2)-2.d0*ff*z*f(1))/cc
      h(2,ni)=a21*f(1)+2.d0*z*f(2)*(ff/cc-1.d0)
   40 call rkdot(f,s,h,2,ni)
      if(knsw.ne.1) goto 45
      fp=a21*f(1)+2.d0*z*f(2)*(ff/cc-1.d0)
      call trknt(s(2),h(2,1),f(2),fp,x,y)
   45 x=y
      if(y.ne.r(i)) go to 15
   50 a(1,i)=f(1)
      a(2,i)=f(2)
      if(i.ne.jl) go to 10
      return
      end
      subroutine tprop(jf,jl,f)
c*** propagates f from jf to jl - toroidal modes ***
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl,nn,ll
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/a(14,1000),inorm(1000)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,in
      dimension h(2,10),s(2),f(2)
      fl3m2=fl3-2.d0
      maxo1=maxo-1
      y=r(jf)
      vy=fmu(jf)/rho(jf)
      i=jf
      go to 50
   10 iq=i
      i=i+1
      x=y
      y=r(i)
      if(y.eq.x) goto 50
      qll=1.d0+qshear(iq)*fct
      vx=vy
      vy=fmu(i)/rho(i)
      qx=1.d0/x+dsqrt(dabs(wsq/(vx)-fl3/(x*x)))
      qy=1.d0/y+dsqrt(dabs(wsq/(vy)-fl3/(y*y)))
      q=dmax1(qx,qy)
      del=step(maxo)/q
      dxs=0.d0
   15 y=x+del
      if(y.gt.r(i)) y=r(i)
      dx=y-x
      if(dx.ne.dxs) call baylis(q,maxo1)
      dxs=dx
      s(1)=f(1)
      s(2)=f(2)
      do 40 ni=1,in
      z=x+c(ni)
      t=z-r(iq)
      ro=rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq)))
      ll=(lcon(iq)+t*(lspl(1,iq)+t*(lspl(2,iq)+t*lspl(3,iq))))*qll
      nn=ll
      if(ifanis.ne.0) nn=(ncon(iq)+
     +    t*(nspl(1,iq)+t*(nspl(2,iq)+t*nspl(3,iq))))*qll
      z=1.d0/z
      h(1,ni)=z*f(1)+f(2)/ll
      h(2,ni)=(nn*fl3m2*z*z-ro*wsq)*f(1)-3.d0*z*f(2)
   40 call rkdot(f,s,h,2,ni)
      if(knsw.ne.1) goto 45
      fp=(nn*fl3m2*z*z-ro*wsq)*f(1)-3.d0*z*f(2)
      call trknt(s(2),h(2,1),f(2),fp,x,y)
   45 x=y
      if(y.ne.r(i)) goto 15
   50 a(1,i)=f(1)
      a(2,i)=f(2)
      if(i.ne.jl) go to 10
      return
      end
      subroutine rkdot(f,s,h,nvec,ni)
c*** performs dot product with rks coefficients ***
      implicit real*8(a-h,o-z)
      common/shanks/b(46),c(10),dx,step(8),stepf,maxo,in
      dimension s(1),f(1),h(nvec,1)
      goto (1,2,3,4,5,6,7,8,9,10),ni
    1 do 21 j=1,nvec
   21 f(j)=s(j)+b(1)*h(j,1)
      return
    2 do 22 j=1,nvec
   22 f(j)=s(j)+b(2)*(h(j,1)+b(3)*h(j,2))
      return
    3 do 23 j=1,nvec
   23 f(j)=s(j)+b(4)*(h(j,1)+b(5)*h(j,2)+b(6)*h(j,3))
      return
    4 do 24 j=1,nvec
   24 f(j)=s(j)+b(7)*(h(j,1)+b(8)*h(j,2)+b(9)*h(j,3)+b(10)*h(j,4))
      return
    5 do 25 j=1,nvec
   25 f(j)=s(j)+b(11)*(h(j,1)+b(12)*h(j,2)+b(13)*h(j,3)+b(14)*h(j,4)+
     +b(15)*h(j,5))
      return
    6 do 26 j=1,nvec
   26 f(j)=s(j)+b(16)*(h(j,1)+b(17)*h(j,2)+b(18)*h(j,3)+b(19)*h(j,4)+
     +b(20)*h(j,5)+b(21)*h(j,6))
      return
    7 do 27 j=1,nvec
   27 f(j)=s(j)+b(22)*(h(j,1)+b(23)*h(j,3)+b(24)*h(j,4)+b(25)*h(j,5)+
     +b(26)*h(j,6)+b(27)*h(j,7))
      return
    8 do 28 j=1,nvec
   28 f(j)=s(j)+b(28)*(h(j,1)+b(29)*h(j,3)+b(30)*h(j,4)+b(31)*h(j,5)+
     +b(32)*h(j,6)+b(33)*h(j,7)+b(34)*h(j,8))
      return
    9 do 29 j=1,nvec
   29 f(j)=s(j)+b(35)*(h(j,1)+b(36)*h(j,3)+b(37)*h(j,4)+b(38)*h(j,5)+
     +b(39)*h(j,6)+b(40)*h(j,7)+b(41)*h(j,8)+b(42)*h(j,9))
      return
   10 do 30 j=1,nvec
   30 f(j)=s(j)+b(43)*(h(j,1)+h(j,10)+b(44)*(h(j,4)+h(j,6))+
     +b(45)*h(j,5)+b(46)*(h(j,7)+h(j,9)))
      return
      end
      subroutine intgds(rr,iq,vals)
c*** interpolates integrands for normalisation,cg,q etc..for use with gauslv.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl,nn,ll
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/ar(14,1000),inorm(1000)
      dimension q(3),qp(3),vals(1)
      data d1,d2,d3,d4,d5,d6,d7/.111111111111111d0,
     + 0.066666666666667d0,0.666666666666667d0,1.333333333333333d0,
     + 2.666666666666667d0,3.333333333333333d0,5.333333333333333d0/
      t=rr-r(iq)
      hn=1.d0/(r(iq+1)-r(iq))
      hsq=hn*hn
      qff=1.d0+xlam(iq)*fct
      qll=1.d0+qshear(iq)*fct
      iq1=iq+1
      ifun=3
      if(jcom.ne.3) ifun=1
      do 10 i=1,ifun
      i2=2*i
      i1=i2-1
      a=((ar(i2,iq)+ar(i2,iq1))+2.d0*hn*(ar(i1,iq)-ar(i1,iq1)))*hsq
      b=-(2.d0*ar(i2,iq)+ar(i2,iq1))*hn-3.d0*(ar(i1,iq)-ar(i1,iq1))*hsq
      q(i)=(ar(i1,iq)+t*(ar(i2,iq)+t*(b+t*a)))/rr
   10 qp(i)=ar(i2,iq)+t*(2.d0*b+t*3.d0*a)
      rro=(rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq))))*rr
      gr=g(iq)+t*(qg(1,iq)+t*(qg(2,iq)+t*qg(3,iq)))
      ff=(fcon(iq)+t*(fspl(1,iq)+t*(fspl(2,iq)+t*fspl(3,iq))))*qff
      ll=(lcon(iq)+t*(lspl(1,iq)+t*(lspl(2,iq)+t*lspl(3,iq))))*qll
      if(ifanis.ne.0) goto 15
      nn=ll
      cc=ff+ll+ll
      aa=cc
      goto 20
   15 qaa=1.d0+xa2(iq)*fct
      nn=(ncon(iq)+t*(nspl(1,iq)+t*(nspl(2,iq)+t*nspl(3,iq))))*qll
      cc=(ccon(iq)+t*(cspl(1,iq)+t*(cspl(2,iq)+t*cspl(3,iq))))*qaa
      aa=(acon(iq)+t*(aspl(1,iq)+t*(aspl(2,iq)+t*aspl(3,iq))))*qaa
   20 qrka=d1*(4.d0*(aa+ff-nn)+cc)
     1     *(qkappa(iq)+t*hn*(qkappa(iq1)-qkappa(iq)))
      qrmu=d2*(aa+cc-2.d0*ff+5.d0*nn+6.d0*ll)
     1     *(qshear(iq)+t*hn*(qshear(iq1)-qshear(iq)))
      if(jcom.ne.3) goto 25
      q1sq=q(1)*q(1)
      q2sq=q(2)*q(2)
      vals(1)=rr*rro*(q1sq+q2sq)
      fac=(fl+.5d0)/sfl3
      vals(2)=(sfl3*(ll*q1sq+aa*q2sq)+q(2)*((rro*gr+2.d0*(nn-aa-ll)+ff)
     +   *q(1)+rro*q(3)-ff*qp(1))+ll*qp(2)*q(1))*fac
     +   +.25d0*q(3)*(qp(3)+fl*q(3))
      t2=qrka+d7*qrmu
      t3=qrka+d4*qrmu
      t4=qrka+d6*qrmu
      t5=qrka-d5*qrmu
      t6=qrka-d3*qrmu
      vals(3)=.5d0*((fl3*qrmu+t2)*q1sq+(2.d0*qrmu+fl3*t3)*q2sq)
     1 -q(1)*sfl3*t4*q(2)+q(1)*(t5*qp(1)+sfl3*qrmu*qp(2))+q(2)*(-2.d0*
     2 qrmu*qp(2)-sfl3*t6*qp(1))+.5d0*(t3*qp(1)*qp(1)+qrmu*qp(2)*qp(2))
      vals(4)=.5d0*((fl3*ll+4.d0*(rro*(rro-gr)+aa-nn-ff)+cc)*q1sq+
     +(4.d0*ll-nn-nn+fl3*aa)*q2sq +fl*fl*.25d0*q(3)*q(3)+cc*qp(1)*qp(1)+
     +ll*qp(2)*qp(2)+.25d0*qp(3)*qp(3))+q(3)*(rro*sfl3*q(2)+fl*.25d0*qp
     +(3))+q(1)*(sfl3*(rro*gr+2.d0*(nn-aa-ll)+ff)*q(2)+rro*(qp(3)-q(3))+
     +(ff+ff-cc)*qp(1)+sfl3*ll*qp(2))-q(2)*(sfl3*ff*qp(1)+(ll+ll)*qp(2))
      return
   25 q(1)=q(1)*rr
      vals(1)=rr*rro*q(1)*q(1)
      if(jcom.eq.1) goto 30
      vals(2)=nn*q(1)*q(1)
      t1=(rr*qp(1)-q(1))**2
      t2=(fl3-2.d0)*q(1)*q(1)
      vals(3)=(t1+t2)*qrmu
      vals(4)=t1*ll+t2*nn
      return
   30 t1=(rr*qp(1)+2.d0*q(1))**2
      t2=d4*(rr*qp(1)-q(1))**2
      vals(2)=t1*qrka+t2*qrmu
      vals(3)=rr*qp(1)*(cc*rr*qp(1)+4.d0*ff*q(1))+4.d0*q(1)*q(1)
     +    *(aa-nn-rro*gr)
      return
      end
      subroutine fpsm(ls,nvefm,ass)
c*** spheroidal mode start solution in a fluid region using sph. bessel fns.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension ass(1)
      x=r(ls)
      fla=flam(ls)*(1.d0+xlam(ls)*fct)
      vpsq=fla/rho(ls)
      xi=g(ls)/x
      qsq=(wsq+float(kg)*4.d0*rho(ls)+xi-fl3*xi*xi/wsq)/vpsq
      zsq=qsq*x*x
      call bfs(l,zsq,eps,fp)
      if(kg.eq.0) goto 20
      u=(fl-fp)/qsq
      c1=fl*g(ls)-wsq*x
      c2=fl2*c1*0.25d0/x-rho(ls)*fl
      ass(1)=-x*fl*vpsq-c1*u
      ass(2)=-x*fl*fla
      ass(3)=-fl*fl2*vpsq*0.25d0-u*c2
      ass(4)=x*fla*c1
      ass(5)=-x*fla*c2
      goto 25
   20 ass(1)=-(fl3*xi/wsq+fp)/qsq
      ass(2)=x*fla
   25 sum=ass(1)*ass(1)
      do 30 i=2,nvefm
   30 sum=sum+ass(i)*ass(i)
      sum=1.d0/dsqrt(sum)
      if(ass(nvefm).lt.0.d0) sum=-sum
      do 35 i=1,nvefm
   35 ass(i)=ass(i)*sum
      return
      end
      subroutine spsm(ls,nvesm,ass)
c*** spheroidal mode start solution in a solid region using sph. bessel fns.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension a(6,2),e(15),ass(1)
      x=r(ls)
      ro=rho(ls)
      fu=fmu(ls)*(1.d0+qshear(ls)*fct)
      flu=flam(ls)*(1.d0+xlam(ls)*fct)+2.d0*fu
      vssq=fu/ro
      vpsq=flu/ro
      zeta=4.d0*ro
      xi=g(ls)/x
      alfsq=(wsq+float(kg)*zeta+xi)/vpsq
      betasq=wsq/vssq
      delsq=dsqrt((betasq-alfsq)**2+4.d0*fl3*xi*xi/(vpsq*vssq))
      fksq=.5d0*(alfsq+betasq+delsq)
      qsq=fksq-delsq
      zsq=qsq*x*x
      b=xi/(vssq*(betasq-qsq))
      k=1
    5 call bfs(l,zsq,eps,fp)
      a(1,k)=fl3*b+fp
      a(2,k)=1.d0+b+b*fp
      a(3,k)=-zsq
      a(4,k)=b*a(3,k)
      a(5,k)=1.d0
      a(6,k)=fl1-fl3*b
      if(k.eq.2) goto 10
      zsq=fksq*x*x
      b=-flu/(fu*fl3*b)
      k=2
      goto 5
   10 jj=3+2*kg
      kk=jj+1
      ll=0
      do 15 i=1,jj
      i1=i+1
      do 15 j=i1,kk
      ll=ll+1
   15 e(ll)=a(i,1)*a(j,2)-a(j,1)*a(i,2)
      if(kg.ne.0) goto 20
      ass(1)=x*x*e(1)
      ass(2)=fu*x*sfl3*(2.d0*e(1)-e(5))
      ass(3)=fu*x*(e(3)-2.d0*e(1))
      ass(4)=x*(flu*e(4)+4.d0*fu*e(1))
      ass(5)=fu*(flu*(e(6)+2.d0*e(4))+4.d0*fu*(fl3*(e(5)-e(1))
     +     -e(3)+2.d0*e(1)))
      goto 25
   20 c0=wsq-xi*fl
      c1=ro*fl+0.25d0*fl2*c0
      c2=2.d0*fu/x
      c3=c2*(fl-1.d0)
      ass(6)=x*x*(c0*e(1)-zeta*(fl*e(8)-e(4)))
      ass(14)=flu*(fl*e(6)-e(2))
      ass(13)=fu*sfl3*(fl*e(7)-e(3))
      ass(1)=x*(c1*e(1)-ro*(fl*e(9)-e(5)))
      ass(7)=x*flu*(c0*e(2)-zeta*fl*e(11))/sfl3+c2*sfl3*ass(6)
      ass(8)=x*fu*(c0*e(3)-zeta*fl*e(13))-c2*ass(6)
      ass(12)=(flu*fl*e(10)+2.d0*(ass(14)+sfl3*ass(13)))*fu/x
      ass(2)=flu*(c1*e(2)-ro*fl*e(12))/sfl3+c2*sfl3*ass(1)
      ass(3)=fu*(c1*e(3)-ro*fl*e(14))-c2*ass(1)
      ass(9)=(x*c0*ass(14)+sfl3*ass(7)-c3*fl*ass(6))/fl
      ass(11)=(sfl3*ass(12)+c3*(sfl3*ass(14)-fl*ass(13)))/fl
      ass(4)=(c1*ass(14)+sfl3*ass(2)-c3*fl*ass(1))/fl
      ass(10)=(x*c0*ass(11)-c3*(sfl3*ass(9)+fl*ass(7)))/sfl3
      ass(5)=(c1*ass(11)-c3*(sfl3*ass(4)+fl*ass(2)))/sfl3
   25 sum=ass(1)*ass(1)
      do 30 i=2,nvesm
   30 sum=sum+ass(i)*ass(i)
      sum=1.d0/dsqrt(sum)
      if(ass(5).lt.0.d0) sum=-sum
      do 35 i=1,nvesm
   35 ass(i)=ass(i)*sum
      return
      end
      subroutine rps(i,a)
c*** radial mode start soln using sph bessel fns.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension a(2)
      fla=flam(i)*(1.d0+xlam(i)*fct)
      sig=fla+2.d0*fmu(i)*(1.d0+qshear(i)*fct)
      zsq=r(i)*r(i)*rho(i)*(wsq+4.d0*g(i)/r(i))/sig
      call bfs(1,zsq,eps,fp)
      a(1)=r(i)
      a(2)=sig*fp+2.d0*fla
      return
      end
      subroutine tps(i,a)
c*** toroidal mode start soln using sph bessel fns.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      dimension a(2)
      fu=fmu(i)*(1.d0+qshear(i)*fct)
      zsq=r(i)*r(i)*wsq*rho(i)/fu
      call bfs(l,zsq,eps,fp)
      a(1)=r(i)
      a(2)=fu*(fp-1.d0)
      return
      end
      subroutine bfs(l,xsq,eps,fp)
c  this routine calculates spherical bessel function of the ist kind.
c  fp is equivalent to (r*dj/dr)/j
c  where r is radius and j is the sbf of order l and argument x=k*r
c  the technique employs the continued fraction approach
c  described in w. lentz's article in applied qptics, vol.15, #3, 1976
      implicit real*8(a-h,o-z)
      real*8 numer,nu
      if(xsq.le.0.d0) goto 10
      x=dsqrt(xsq)
      lp1=l+1
      rx=2.0d0/x
      nu=lp1-0.5d0
      rj=nu*rx
      rx=-rx
      denom=(nu+1.d0)*rx
      numer=denom+1.0d0/rj
      rj=rj*numer/denom
      nm1=1
    2 nm1=nm1+1
      rx=-rx
      a3=(nu+nm1)*rx
      denom=a3+1.d0/denom
      numer=a3+1.d0/numer
      ratio=numer/denom
      rj=rj*ratio
      if(dabs(dabs(ratio)-1.d0).gt.eps) goto 2
      fp=rj*x-lp1
      return
c  series solution
   10 f=1.d0
      fp=l
      a=1.d0
      b=l+l+1.d0
      c=2.d0
      d=l+2.d0
   15 a=-a*xsq/(c*(b+c))
      f=f+a
      fp=fp+a*d
      if(dabs(a*d).lt.eps) goto 20
      c=c+2.d0
      d=d+2.d0
      goto 15
   20 fp=fp/f
      return
      end
      subroutine remedy(ls)
c    obtains the eigenfunction of an awkward spheroidal mode by
c    integrating to the icb or the mcb.
      implicit real*8(a-h,o-z)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/ar(14,1000),inorm(1000)
      common/arem/a(6,3,1000)
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      dimension af(4,2),as(6,3),afr(4)
      print 900,ls
  900 format('in remedy with start level : ',i4)
      if(ls.gt.noc) return
      iexp=0
      do 10 k=1,2
      do 10 j=1,4
   10 af(j,k)=0.d0
      af(1,1)=1.d0
      if(kg.eq.1) af(2,2)=1.d0
      if(nsl.eq.n) goto 5
      do 6 i=nslp1,n
      do 6 k=1,3
      do 6 j=1,6
    6 a(j,k,i)=0.d0
      call fprop(n,nslp1,af,iexp)
    5 call fsbdry(af,as,kg)
      do 7 k=1,3
      do 7 j=1,6
    7 a(j,k,nsl)=as(j,k)
      if(n.ne.nsl) call ortho(n,nsl,as,kg)
      call sprop(n,nsl,nocp1,as,iexp)
      call sfbdry(n,nocp1,as,af,kg)
      imtch=noc
      do 11 i=1,4
   11 afr(i)=ar(i,noc)
      if(ls.gt.nic) goto 15
      icomp=0
      call match(n,noc,kg,af,afr,icomp)
      if(icomp.eq.0) return
      call fprop(noc,nicp1,af,iexp)
      imtch=nic
      do 12 i=1,4
   12 afr(i)=ar(i,nicp1)
   15 icomp=-1
      call match(n,imtch,kg,af,afr,icomp)
      return
      end
      subroutine fprop(jf,jl,f,iexp)
c    fprop propagates the fundamental matrix f from jf to jl (a fluid region)
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/ar(14,1000),inorm(1000)
      common/arem/a(6,3,1000)
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      common/shanks/b(46),c(10),dx,step(8),sdum,idum,in
      dimension f(4,2),s(4,2),h(4,2,10)
      data econst/1048576.d0/
      kk=kg+1
      jj=2*kk
      jud=1
      if(jl.lt.jf) jud=-1
      y=r(jf)
      i=jf
      go to 80
   10 x=y
      y=r(i)
      if(y.eq.x) goto 80
      iq=min0(i,i-jud)
      qff=1.d0+xlam(iq)*fct
      zs=dmin1(x,y)
      xi=g(i)/y
      alfsq=(wsq+4.d0*rho(i)+xi-fl3*xi*xi/wsq)*rho(i)/flam(i)
      q=dmax1(sfl3/x,dsqrt(dabs(alfsq-fl3/(x*x)))+1.d0/zs)
      del=jud*step(8)/q
      dxs=0.d0
   15 y=x+del
      if(float(jud)*(y-r(i)).gt.0.d0) y=r(i)
      dx=y-x
      if(dx.ne.dxs) call baylis(q,7)
      dxs=dx
      do 20 k=1,kk
      do 20 j=1,jj
   20 s(j,k)=f(j,k)
      d=fl3/wsq
      do 40 ni=1,in
      z=x+c(ni)
      t=z-zs
      zr=1.d0/z
      ro=rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq)))
      flu=(fcon(iq)+t*(fspl(1,iq)+t*(fspl(2,iq)+t*fspl(3,iq))))*qff
      gr=(g(iq)+t*(qg(1,iq)+t*(qg(2,iq)+t*qg(3,iq))))*zr
      t21=-4.d0*ro
      t12=d*zr*zr
      t11=(gr*d-1.d0)*zr
      s11=-ro*(wsq+4.d0*gr-gr*gr*d)
      c11=-t12/ro+1.d0/flu
      if(kg.eq.0) s11=s11-t21*ro
      if(kg.eq.0) goto 25
      t22=-fl*zr
      s22=ro*t12
      s12=ro*(t11+t22)
   25 do 70 k=1,kk
      if(kg.ne.0) goto 30
      h(1,k,ni)=t11*f(1,k)+c11*f(2,k)
      h(2,k,ni)=s11*f(1,k)-t11*f(2,k)
      goto 35
   30 h(1,k,ni)=t11*f(1,k)+t12*f(2,k)+c11*f(3,k)
      h(2,k,ni)=t21*f(1,k)+t22*f(2,k)+4.d0*f(4,k)
      h(3,k,ni)=s11*f(1,k)+s12*f(2,k)-t11*f(3,k)-t21*f(4,k)
      h(4,k,ni)=s12*f(1,k)+s22*f(2,k)-t12*f(3,k)-t22*f(4,k)
   35 do 70 j=1,jj
      go to (701,702,703,704,705,706,707,708,709,710),ni
  701 f(j,k)=s(j,k)+b(1)*h(j,k,1)
      go to 70
  702 f(j,k)=s(j,k)+b(2)*(h(j,k,1)+b(3)*h(j,k,2))
      go to 70
  703 f(j,k)=s(j,k)+b(4)*(h(j,k,1)+b(5)*h(j,k,2)+b(6)*h(j,k,3))
      go to 70
  704 f(j,k)=s(j,k)+b(7)*(h(j,k,1)+b(8)*h(j,k,2)+b(9)*h(j,k,3)+
     +b(10)*h(j,k,4))
      go to 70
  705 f(j,k)=s(j,k)+b(11)*(h(j,k,1)+b(12)*h(j,k,2)+b(13)*h(j,k,3)+
     +b(14)*h(j,k,4)+b(15)*h(j,k,5))
      go to 70
  706 f(j,k)=s(j,k)+b(16)*(h(j,k,1)+b(17)*h(j,k,2)+b(18)*h(j,k,3)+
     +b(19)*h(j,k,4)+b(20)*h(j,k,5)+b(21)*h(j,k,6))
      go to 70
  707 f(j,k)=s(j,k)+b(22)*(h(j,k,1)+b(23)*h(j,k,3)+b(24)*h(j,k,4)+
     +b(25)*h(j,k,5)+b(26)*h(j,k,6)+b(27)*h(j,k,7))
      go to 70
  708 f(j,k)=s(j,k)+b(28)*(h(j,k,1)+b(29)*h(j,k,3)+b(30)*h(j,k,4)+
     +b(31)*h(j,k,5)+b(32)*h(j,k,6)+b(33)*h(j,k,7)+b(34)*h(j,k,8))
      go to 70
  709 f(j,k)=s(j,k)+b(35)*(h(j,k,1)+b(36)*h(j,k,3)+b(37)*h(j,k,4)+
     +b(38)*h(j,k,5)+b(39)*h(j,k,6)+b(40)*h(j,k,7)+b(41)*h(j,k,8)+
     +b(42)*h(j,k,9))
      go to 70
  710 f(j,k)=s(j,k)+b(43)*(h(j,k,1)+h(j,k,10)+b(45)*h(j,k,5)+
     +b(44)*(h(j,k,4)+h(j,k,6))+b(46)*(h(j,k,7)+h(j,k,9)))
   70 continue
   40 continue
      x=y
      if(y.ne.r(i)) go to 15
   80 size=0.d0
      do 81 k=1,kk
      do 81 j=1,jj
   81 size=dmax1(size,dabs(f(j,k)))
   82 if(size.lt.1024.d0) goto 84
      do 83 k=1,kk
      do 83 j=1,jj
   83 f(j,k)=f(j,k)/econst
      size=size/econst
      iexp=iexp+20
      goto 82
   84 inorm(i)=iexp
      do 85 k=1,kk
      do 85 j=1,jj
   85 a(j,k,i)=f(j,k)
      if(i.eq.jl) return
      i=i+jud
      go to 10
      end
      subroutine sprop(li,jf,jl,f,iexp)
c    sprop propagates the fundamental matrix f from jf to jl (a solid region)
c    if iorth=1 the columns of f are orthogonalized at each level
c    except in regions of oscillatory p and s.
      implicit real*8(a-h,o-z)
      real*8 lcon,ncon,lspl,nspl,nn,ll
      common/mod$$/r(1000),fmu(1000),flam(1000),qshear(1000),qkappa(1000),
     + xa2(1000),xlam(1000),rho(1000),qro(3,1000),g(1000),qg(3,1000),
     + fcon(1000),fspl(3,1000),lcon(1000),lspl(3,1000),ncon(1000),
     + nspl(3,1000),ccon(1000),cspl(3,1000),acon(1000),aspl(3,1000)
      common/bits/pi,rn,vn,wn,w,wsq,wray,qinv,cg,wgrav,tref,fct,eps,fl,
     +  fl1,fl2,fl3,sfl3,jcom,nord,l,kg,kount,knsw,ifanis,iback
      common/eifx/ar(14,1000),inorm(1000)
      common/arem/a(6,3,1000)
      common/rindx/nic,noc,nsl,nicp1,nocp1,nslp1,n
      common/shanks/b(46),c(10),dx,step(8),sdum,idum,in
      dimension f(6,3),s(6,3),h(6,3,10)
      data econst/1048576.d0/
      kk=kg+2
      jj=2*kk
      jud=1
      if(jl.lt.jf) jud=-1
      y=r(jf)
      i=jf
      go to 80
   10 x=y
      y=r(i)
      if(x.eq.y) goto 80
      iq=min0(i,i-jud)
      qff=1.d0+xlam(iq)*fct
      qll=1.d0+qshear(iq)*fct
      qaa=1.d0+xa2(iq)*fct
      zs=dmin1(x,y)
      xi=g(i)/y
      vpsq=(flam(i)+2.d0*fmu(i))/rho(i)
      vssq=fmu(i)/rho(i)
      alfsq=(wsq+4.d0*rho(i)+xi)/vpsq
      betasq=wsq/vssq
      delsq=dsqrt((betasq-alfsq)**2+4.d0*fl3*xi*xi/(vssq*vpsq))
      fksq=.5d0*(alfsq+betasq+delsq)
      al=fl3/(x*x)
      jorth=1
      aq=fksq-delsq-al
      if(aq.gt.0.d0) jorth=0
      qs=dsqrt(dabs(fksq-al))+1.d0/zs
      qf=dsqrt(dabs(aq))+1.d0/zs
      q=dmax1(sfl3/x,qs,qf)
      del=jud*step(8)/q
      dxs=0.d0
   15 y=x+del
      if(float(jud)*(y-r(i)).gt.0.d0) y=r(i)
      dx=y-x
      if(dx.ne.dxs) call baylis(q,7)
      dxs=dx
      do 20 k=1,kk
      do 20 j=1,jj
   20 s(j,k)=f(j,k)
      do 50 ni=1,in
      z=x+c(ni)
      t=z-zs
      ro=rho(iq)+t*(qro(1,iq)+t*(qro(2,iq)+t*qro(3,iq)))
      gr=g(iq)+t*(qg(1,iq)+t*(qg(2,iq)+t*qg(3,iq)))
      ff=(fcon(iq)+t*(fspl(1,iq)+t*(fspl(2,iq)+t*fspl(3,iq))))*qff
      ll=(lcon(iq)+t*(lspl(1,iq)+t*(lspl(2,iq)+t*lspl(3,iq))))*qll
      if(ifanis.ne.0) goto 25
      nn=ll
      cc=ff+ll+ll
      aa=cc
      goto 30
   25 nn=(ncon(iq)+t*(nspl(1,iq)+t*(nspl(2,iq)+t*nspl(3,iq))))*qll
      cc=(ccon(iq)+t*(cspl(1,iq)+t*(cspl(2,iq)+t*cspl(3,iq))))*qaa
      aa=(acon(iq)+t*(aspl(1,iq)+t*(aspl(2,iq)+t*aspl(3,iq))))*qaa
   30 zr=1.d0/z
      sfl3z=sfl3*zr
      rogr=ro*gr
      c11=1.d0/cc
      c22=1.d0/ll
      dmg=aa-nn-ff*ff*c11
      zdmg=zr*dmg
      t11=-2.d0*ff*zr*c11+zr
      t12=sfl3z*ff*c11
      t21=-sfl3z
      t22=zr+zr
      s22=-ro*wsq
      s11=s22+4.d0*zr*(zdmg-rogr)
      s22=s22+zr*zr*(fl3*(dmg+nn)-nn-nn)
      s12=sfl3z*(rogr-zdmg-zdmg)
      if(kg.eq.0) s11=s11+4.d0*ro*ro
      if(kg.eq.0) goto 35
      t31=-4.d0*ro
      t33=-fl*zr
      s13=-fl1*zr*ro
      s23=ro*sfl3z
   35 do 70 k=1,kk
      if(kg.eq.1) goto 40
      h(1,k,ni)=t11*f(1,k)+t12*f(2,k)+c11*f(3,k)
      h(2,k,ni)=t21*f(1,k)+t22*f(2,k)+c22*f(4,k)
      h(3,k,ni)=s11*f(1,k)+s12*f(2,k)-t11*f(3,k)-t21*f(4,k)
      h(4,k,ni)=s12*f(1,k)+s22*f(2,k)-t12*f(3,k)-t22*f(4,k)
      goto 45
   40 h(1,k,ni)=t11*f(1,k)+t12*f(2,k)+c11*f(4,k)
      h(2,k,ni)=t21*f(1,k)+t22*f(2,k)+c22*f(5,k)
      h(3,k,ni)=t31*f(1,k)+t33*f(3,k)+4.d0*f(6,k)
      h(4,k,ni)=s11*f(1,k)+s12*f(2,k)+s13*f(3,k)-t11*f(4,k)-t21*f(5,k)
     +    -t31*f(6,k)
      h(5,k,ni)=s12*f(1,k)+s22*f(2,k)+s23*f(3,k)-t12*f(4,k)-t22*f(5,k)
      h(6,k,ni)=s13*f(1,k)+s23*f(2,k)-t33*f(6,k)
   45 do 70 j=1,jj
      go to (701,702,703,704,705,706,707,708,709,710),ni
  701 f(j,k)=s(j,k)+b(1)*h(j,k,1)
      go to 70
  702 f(j,k)=s(j,k)+b(2)*(h(j,k,1)+b(3)*h(j,k,2))
      go to 70
  703 f(j,k)=s(j,k)+b(4)*(h(j,k,1)+b(5)*h(j,k,2)+b(6)*h(j,k,3))
      go to 70
  704 f(j,k)=s(j,k)+b(7)*(h(j,k,1)+b(8)*h(j,k,2)+b(9)*h(j,k,3)+
     +b(10)*h(j,k,4))
      go to 70
  705 f(j,k)=s(j,k)+b(11)*(h(j,k,1)+b(12)*h(j,k,2)+b(13)*h(j,k,3)+
     +b(14)*h(j,k,4)+b(15)*h(j,k,5))
      go to 70
  706 f(j,k)=s(j,k)+b(16)*(h(j,k,1)+b(17)*h(j,k,2)+b(18)*h(j,k,3)+
     +b(19)*h(j,k,4)+b(20)*h(j,k,5)+b(21)*h(j,k,6))
      go to 70
  707 f(j,k)=s(j,k)+b(22)*(h(j,k,1)+b(23)*h(j,k,3)+b(24)*h(j,k,4)+
     +b(25)*h(j,k,5)+b(26)*h(j,k,6)+b(27)*h(j,k,7))
      go to 70
  708 f(j,k)=s(j,k)+b(28)*(h(j,k,1)+b(29)*h(j,k,3)+b(30)*h(j,k,4)+
     +b(31)*h(j,k,5)+b(32)*h(j,k,6)+b(33)*h(j,k,7)+b(34)*h(j,k,8))
      go to 70
  709 f(j,k)=s(j,k)+b(35)*(h(j,k,1)+b(36)*h(j,k,3)+b(37)*h(j,k,4)+
     +b(38)*h(j,k,5)+b(39)*h(j,k,6)+b(40)*h(j,k,7)+b(41)*h(j,k,8)+
     +b(42)*h(j,k,9))
      go to 70
  710 f(j,k)=s(j,k)+b(43)*(h(j,k,1)+h(j,k,10)+b(45)*h(j,k,5)+
     +b(44)*(h(j,k,4)+h(j,k,6))+b(46)*(h(j,k,7)+h(j,k,9)))
   70 continue
   50 continue
      x=y
      if(y.ne.r(i)) go to 15
   80 size=0.d0
      do 81 k=1,kk
      do 81 j=1,jj
   81 size=dmax1(size,dabs(f(j,k)))
   82 if(size.lt.1024.d0) goto 84
      do 83 k=1,kk
      do 83 j=1,jj
   83 f(j,k)=f(j,k)/econst
      size=size/econst
      iexp=iexp+20
      goto 82
   84 inorm(i)=iexp
      do 85 k=1,kk
      do 85 j=1,jj
   85 a(j,k,i)=f(j,k)
      if(jorth.eq.1) call ortho(li,i,f,kg)
      if(i.eq.jl) return
      i=i+jud
      go to 10
      end
      subroutine sfbdry(jf,jl,as,af,kg)
c*** the tangential traction scalar is forced to vanish at the solid
c*** side of a s/f boundary(level jl).a(j,3,i) is elliminated for
c*** i=jf...jl and af is loaded from a at level jl.
      implicit real*8(a-h,o-z)
      common/arem/a(6,3,1000)
      dimension as(6,1),af(4,1)
      n1=min0(jf,jl)
      n2=max0(jf,jl)
      if(kg.ne.0) goto 25
      i1=1
      i2=2
      if(dabs(as(4,2)).gt.dabs(as(4,1))) goto 10
      i1=2
      i2=1
   10 rat=-as(4,i1)/as(4,i2)
      do 15 i=n1,n2
      do 15 j=1,4
   15 a(j,1,i)=a(j,i1,i)+rat*a(j,i2,i)
      af(1,1)=a(1,1,jl)
      af(2,1)=a(3,1,jl)
      return
   25 ab53=dabs(as(5,3))
      do 30 k=1,2
      i1=k
      i2=3
      if(ab53.gt.dabs(as(5,k))) goto 35
      i1=3
      i2=k
   35 rat=-as(5,i1)/as(5,i2)
      do 40 i=n1,n2
      do 40 j=1,6
   40 a(j,k,i)=a(j,i1,i)+rat*a(j,i2,i)
      af(1,k)=a(1,k,jl)
      af(2,k)=a(3,k,jl)
      af(3,k)=a(4,k,jl)
   30 af(4,k)=a(6,k,jl)
      return
      end
      subroutine fsbdry(af,as,kg)
c    fsbdry creates solid fundamental matrix as from fluid fundamental matrix
c    af.it is presumed that fsbdry is used to cross a f/s boundary.
      implicit real*8(a-h,o-z)
      dimension af(4,1),as(6,1)
      do 10 i=1,3
      do 10 j=1,6
   10 as(j,i)=0.d0
      if(kg.ne.0) goto 20
      as(1,1)=af(1,1)
      as(3,1)=af(2,1)
      as(2,2)=1.d0
      return
   20 do 25 k=1,2
      as(1,k)=af(1,k)
      as(3,k)=af(2,k)
      as(4,k)=af(3,k)
   25 as(6,k)=af(4,k)
      as(2,3)=1.d0
      return
      end
      subroutine match(n,j,kg,af,afr,icomp)
      implicit real*8(a-h,o-z)
      common/eifx/ar(14,1000),inorm(1000)
      common/arem/a(6,3,1000)
      dimension af(4,1),afr(1),afi(4)
      k=j+2
      rms=0.d0
      fnor=0.d0
      if(kg.eq.1) go to 20
      c=(af(1,1)*afr(1)+af(2,1)*afr(2))/(af(1,1)**2+af(2,1)**2)
      do 5 i=1,2
      afi(i)=af(i,1)*c
      rms=rms+(afi(i)-afr(i))**2
    5 fnor=fnor+afr(i)*afr(i)
      rms=dsqrt(rms/fnor)
      if(icomp.lt.0) goto 6
      if(rms.lt.1.d-3) goto 6
      icomp=1
      return
    6 idiff=inorm(j)-inorm(j+1)
      inorm(j+1)=inorm(j)
  999 format(4g20.10)
      do 10 i=k,n
      inorm(i)=inorm(i)+idiff
      do 10 jj=1,4
   10 ar(jj,i)=c*a(jj,1,i)
      return
   20 a2=(af(3,1)*afr(1)-af(1,1)*afr(3))/(af(1,2)*af(3,1)-af(1,1)
     +   *af(3,2))
      a1=(af(3,2)*afr(1)-af(1,2)*afr(3))/(af(1,1)*af(3,2)-af(3,1)
     +   *af(1,2))
      do 21 i=1,4
      afi(i)=a1*af(i,1)+a2*af(i,2)
      rms=rms+(afi(i)-afr(i))**2
   21 fnor=fnor+afr(i)*afr(i)
      rms=dsqrt(rms/fnor)
      print 999,rms
      if(icomp.lt.0) goto 22
      if(rms.lt.1.d-3) goto 22
      icomp=1
      return
   22 idiff=inorm(j)-inorm(j+1)
      inorm(j+1)=inorm(j)
      do 25 i=k,n
      inorm(i)=inorm(i)+idiff
      do 25 jj=1,6
   25 ar(jj,i)=a1*a(jj,1,i)+a2*a(jj,2,i)
      return
      end
      subroutine ortho(li,lc,b,kg)
c    finds the orthogonal matrix v such that the columns of b*v are orthogonal
c   the array a is replaced by a*v for levels li - lc. array b is replaced
c   by b*v and is then ready fo entry to sprop at level lc.this is intended
c   to diminish the onset of degeneracy caused by rapid exponential growth
c    in the mantle for modes with deeply turning s and shallowly turning p.
      implicit real*8(a-h,o-z)
      common/arem/a(6,3,1000)
      dimension b(6,1),as(6,3)
      i1=min0(lc,li)
      i2=max0(lc,li)
      nc=kg+2
      nr=2*nc
      call svd(b,nr,nc)
      do 25 i=i1,i2
      do 20 j=1,nc
      do 20 k=1,nr
      as(k,j)=0.d0
      do 20 l=1,nc
   20 as(k,j)=as(k,j)+a(k,l,i)*b(l,j)
      do 25 j=1,nc
      do 25 k=1,nr
   25 a(k,j,i)=as(k,j)
      do 35 j=1,nc
      do 35 k=1,nr
   35 b(k,j)=a(k,j,lc)
      return
      end
      subroutine svd(a,mrow,ncol)
c    section i chapter 10 wilkenson and reinsch (1971 ,springer).
c    the matrix a is overwritten with v(ncol,ncol), the right side orthogonal
c    matrix in the svd decomposition. for use only in eos subs as ,to reduce
c    branching points, i have used the fact that ncol is lt mrow.
      implicit real*8(a-h,o-z)
      dimension a(6,1),e(3),q(3)
      eps=1.5d-14
      tol=1.d-293
      g=0.d0
      x=0.d0
      do 60 i=1,ncol
      l=i+1
      e(i)=g
      s=0.d0
      do 10 j=i,mrow
   10 s=s+a(j,i)*a(j,i)
      if(s.gt.tol) go to 15
      q(i)=0.d0
      if(l.gt.ncol) goto 60
      go to 30
   15 q(i)=dsign(dsqrt(s),-a(i,i))
      h=a(i,i)*q(i)-s
      a(i,i)=a(i,i)-q(i)
      if(l.gt.ncol) go to 60
      do 25 j=l,ncol
      s=0.d0
      do 20 k=i,mrow
   20 s=s+a(k,i)*a(k,j)
      f=s/h
      do 25 k=i,mrow
   25 a(k,j)=a(k,j)+f*a(k,i)
   30 s=0.d0
      do 35 j=l,ncol
   35 s=s+a(i,j)*a(i,j)
      if(s.ge.tol)go to 40
      g=0.d0
      go to 60
   40 g=dsign(dsqrt(s),-a(i,l))
      h=a(i,l)*g-s
      a(i,l)=a(i,l)-g
      do 45 j=l,ncol
   45 e(j)=a(i,j)/h
      do 55 j=l,mrow
      s=0.d0
      do 50 k=l,ncol
   50 s=s+a(j,k)*a(i,k)
      do 55 k=l,ncol
   55 a(j,k)=a(j,k)+s*e(k)
   60 x=dmax1(dabs(q(i))+dabs(e(i)),x)
      goto 100
   75 if(g.eq.0.d0)go to 91
      h=a(i,l)*g
      do 80 j=l,ncol
   80 a(j,i)=a(i,j)/h
      do 90 j=l,ncol
      s=0.d0
      do 85 k=l,ncol
   85 s=s+a(i,k)*a(k,j)
      do 90 k=l,ncol
   90 a(k,j)=a(k,j)+s*a(k,i)
   91 do 95 j=l,ncol
      a(i,j)=0.d0
   95 a(j,i)=0.d0
  100 a(i,i)=1.d0
      g=e(i)
      l=i
      i=i-1
      if(i.ge.1)go to 75
      ep=eps*x
      k=ncol
  105 l=k
  110 if(dabs(e(l)).le.ep)go to 125
      if(dabs(q(l-1)).le.ep) go to 115
      l=l-1
      if(l.ge.1)go to 110
  115 c=0.d0
      s=1.d0
      do 120 i=l,k
      f=s*e(i)
      e(i)=c*e(i)
      if(dabs(f).le.ep)go to 125
      g=q(i)
      h=dsqrt(f*f+g*g)
      c=g/h
      s=-f/h
  120 q(i)=h
  125 z=q(k)
      if(l.eq.k)go to 145
      x=q(l)
      y=q(k-1)
      g=e(k-1)
      h=e(k)
      f=((y-z)*(y+z)+(g-h)*(g+h))/(2.d0*h*y)
      g=dsqrt(f*f+1.d0)
      f=((x-z)*(x+z)+h*(y/(f+dsign(g,f))-h))/x
      c=1.d0
      s=1.d0
      lp1=l+1
      do 140 i=lp1,k
      g=e(i)
      y=q(i)
      h=s*g
      g=c*g
      z=dsqrt(f*f+h*h)
      im1=i-1
      e(im1)=z
      c=f/z
      s=h/z
      f=s*g+c*x
      g=c*g-s*x
      h=s*y
      y=c*y
      do 130 j=1,ncol
      x=a(j,im1)
      z=a(j,i)
      a(j,im1)=c*x+s*z
  130 a(j,i)=c*z-s*x
      z=dsqrt(f*f+h*h)
      q(im1)=z
      c=f/z
      s=h/z
      f=s*y+c*g
  140 x=c*y-s*g
      e(l)=0.d0
      e(k)=f
      q(k)=x
      go to 105
  145 if(z.ge.0.d0)go to 155
      q(k)=-z
      do 150 j=1,ncol
  150 a(j,k)=-a(j,k)
  155 k=k-1
      if(k.ge.1)go to 105
      return
      end

