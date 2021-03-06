/* Updated for Solaris 2.4, SPARCompiler 3.0.1; October 19, 1995, 
   Erik Larson */

/* Ported to Linux by Stefan Heimers <stefan@heimers.ch> */

#include <sys/types.h>
/* #include <rmt.h> */  /* omit this line if remote tape access library not installed*/
#include <sys/stat.h>
#include <sys/times.h>
#include <sys/ioctl.h>
#include <sys/mtio.h>
#include <sys/file.h>

// changed by sheimers
#ifdef SOLARIS
#include <sys/filio.h> 
#else
#include <termios.h>
//#include <termio.h>  /* for struct termio */
#include <sgtty.h>
#endif

#include <sys/fcntl.h>
#include <dirent.h>

// changed by sheimers
#ifdef SOLARIS
#include <sys/ttold.h>
#endif

#include <stdio.h>
#include <stdlib.h> /* as per TWB's suggestion */
#include <unistd.h>
#include <errno.h>

// changed by sheimers
#ifdef SOLARIS
struct sgttyb   pack;
#else
struct termios termios_p;
#endif

struct stat     buf;

clockf_(ichan,iopt,isize,ires,ierrno)
	long *ichan, *iopt, *isize, *ires, *ierrno;
{	extern int errno, lockf();
	int kopt;
	kopt = (int) (*iopt);
	
	switch (kopt) {
	case 0:
		kopt = F_ULOCK;
		break;
	case 1:
		kopt = F_LOCK;
		break;
	case 2:
		kopt = F_TLOCK;
		break;
	case 3:
		kopt = F_TEST;
		break;
	default:
	  fprintf(stderr, "lockf: unknown option %d", (int)*iopt);
		exit(2);
		break;
	}


	errno=0;
	*ires = (long) lockf((int)(*ichan), kopt, *isize);
	*ierrno = (long) errno;
}

cermes_(ierrno,mess,lmess)
	char *mess;
	long *ierrno, *lmess;
{	extern int sys_nerr;

// changed by sheimers
#ifdef SOLARIS
	extern char *sys_errlist[];
#else
	extern __const char *__const sys_errlist[];
#endif

	char *cp, *mp;
	int lm;
	if(*ierrno >= 0 & *ierrno < sys_nerr)
	  {for (lm=0, mp=mess, cp=sys_errlist[*ierrno];*cp;mp++, cp++)
	     {*mp=*cp;lm++;}
	   *lmess=(long)lm;
	  }


	else
	  *lmess=-1;
}
	

copendir_(name,ichan)
	char *name;
	long *ichan;
{	extern DIR *opendir();
	*ichan=(long) opendir(name);
}

cclosedir_(ichan)
	long *ichan;
{	closedir( (DIR *)(*ichan) );
}


creaddir_(ichan,name,lname,idno)
	char  *name;
	long  *ichan, *lname, *idno;
{
	short i, l;
	struct dirent *dptr;
	char *nn;
	if(dptr = readdir((DIR *)(*ichan))) 
	  {l=dptr->d_reclen;
	   *lname= (long) l;
	   *idno=(long) dptr->d_ino;
           for (i=0, nn=name; i < l; i++, nn++)
             *nn=dptr->d_name[i];
	  }
        else
          {*lname=0;
           *idno=-1;
          }
}

creadlink_(path, pbuf, pnbyt, ires, ierrno)
	char           *pbuf, *path;
	long           *pnbyt, *ires, *ierrno;
{
	extern int      errno;
	errno = 0;
	*ires = (long) readlink(path , pbuf, (size_t) (*pnbyt));
	*ierrno = (long) errno;
}

cgterr_(ierrno)
	long *ierrno;
{	extern int errno;
	*ierrno=(long)errno;
}

cmkdir_(pname,mode,ires,ierrno)
        long *ires,*ierrno,*mode;
        char *pname;
{

        extern int errno, mkdir();
        errno=0;
        *ires=(long) mkdir(pname,(int)(*mode));
        *ierrno=(long)errno;
}
 
cutimes_(pname, times, ires, ierrno)
        long *ires, *ierrno;
        long *times;
        char *pname;
{
        extern int errno, utimes();
        errno=0;
        *ires= (long) utimes( pname,times);
        *ierrno=(long)errno;
}



cflush_(ichan, inout, ires, ierrno)
	long    *ichan, *inout, *ires, *ierrno;
{
	extern int errno;
	int arg;
        errno=0;
	arg=(int)(*inout);

// changed by sheimers
#ifdef SOLARIS
        *ires=(long) ioctl((int)(*ichan),TIOCFLUSH,&arg);
#else
	*ires=(long) ioctl((int)(*ichan),TCFLSH,&arg);
#endif
        *ierrno=(long) errno;
}


cstdtr_(ichan, ires, ierrno)
	long    *ichan, *ires, *ierrno;
{
	extern int errno;
        errno=0;

// changed by sheimers
/* set data terminal ready */
#ifdef SOLARIS
        *ires=(long) ioctl((int)(*ichan),TIOCSDTR,0);
#else
	*ires=(long) ioctl((int)(*ichan),TIOCMBIS,TIOCM_DTR);
#endif
        *ierrno=(long) errno;
}


ccldtr_(ichan, ires, ierrno)
	long    *ichan, *ires, *ierrno;
{
	extern int errno;
        errno=0;
// changed by sheimers
#ifdef SOLARIS
        *ires=(long) ioctl((int)(*ichan),TIOCCDTR,0);
#else
        *ires=(long) ioctl((int)(*ichan),TIOCMBIC,TIOCM_DTR);

#endif
        *ierrno=(long) errno;
}



cgtlmw_(ichan, iword, ires, ierrno)
	long    *ichan, *iword, *ires, *ierrno;
{
	extern int errno;
	int word;
        errno=0;

	// changed by sheimers
#ifdef SOLARIS
        *ires=(long) ioctl((int)(*ichan),TIOCLGET,&word);
	*iword=(long) word;
#else
	*ires=(long) tcgetattr((int)(*ichan),&termios_p); 
	*iword=(long) termios_p.c_lflag;
 
#endif
        *ierrno=(long) errno;
}


cstlmw_(ichan, iword, ires, ierrno)
	long    *ichan, *iword, *ires, *ierrno;
{
	extern int errno;
	int word;
        errno=0;
// changed by sheimers
#ifdef SOLARIS
        word=*iword;
        *ires=(long) ioctl((int)(*ichan),TIOCLSET,&word);
#else
	tcgetattr((int)(*ichan),&termios_p);
	termios_p.c_lflag = *iword;
	*ires=(long) tcsetattr((int)(*ichan),TCSANOW,&termios_p);
#endif
        *ierrno=(long) errno;
}


cgtflag_(ichan, iflag, ires, ierrno)
	long           *ichan, *iflag, *ires, *ierrno;
{
	extern int      errno;
	errno = 0;

// changed by sheimers
#ifdef SOLARIS
	*ires = (long) ioctl((int) (*ichan), TIOCGETP, &pack);
	*iflag = (long) pack.sg_flags;

#else
	//	*ires = (long) ioctl((int) (*ichan), TCGETA, &termio_pack);
	*ires = (long)	tcgetattr((int)(*ichan),&termios_p);
	// I am not sure if c_iflags and sg_flags do the same thing, be careful!
	*iflag = (long) termios_p.c_iflag;

#endif
	*ierrno = (long) errno;
}

cstflag_(ichan, iflag, speed, ires, ierrno)
	long           *ichan, *iflag, *speed, *ires, *ierrno;
{
	extern int      errno;
	errno = 0;

	// changed by sheimers
#ifdef SOLARIS
	pack.sg_flags = (int) (*iflag);
        pack.sg_ispeed=(char) (*speed);
        pack.sg_ospeed=(char) (*speed);
	*ires = (long) ioctl((int) (*ichan), TIOCSETP, &pack);
#else
	*ires=(long) tcgetattr((int)(*ichan),&termios_p); 
	// I am not sure if c_iflags and sg_flags do the same thing, be careful!
	termios_p.c_iflag = *iflag;
	termios_p.c_ispeed = *speed;
	termios_p.c_ospeed = *speed;
	*ires=(long) tcsetattr((int)(*ichan),TCSANOW,&termios_p);
#endif
	*ierrno = (long) errno;
}

cstexc_(ichan, ires, ierrno)
	long           *ichan, *ires, *ierrno;
{
	extern int      errno;
	char           *dummy;
	errno = 0;
	*ires = (long) ioctl((int) (*ichan), TIOCEXCL, dummy);
	*ierrno = (long) errno;
}

cnoblock_(ichan, iopt, ires, ierrno)
	long           *ichan, *iopt, *ires, *ierrno;
{
	extern int      errno;
	int             tiopt;
	tiopt = (int) (*iopt);
	errno = 0;
	*ires = (long) ioctl((int) (*ichan), FIONBIO, &tiopt);
	*ierrno = (long) errno;
}


copen_(pname, ichan, iopt, ierrno, inew, mode)
	char           *pname;
	long           *ichan, *iopt, *ierrno, *inew, *mode;
{
	extern int      errno;
	//	extern int      open();
	int             kopt, knew;
	kopt = (int) (*iopt);
	knew = (int) (*inew);
	switch (kopt) {
	case 0:
		kopt = O_RDONLY;
		break;
	case 1:
		kopt = O_WRONLY;
		break;
	case 2:
		kopt = O_RDWR;
		break;
	case 8:
		kopt = O_APPEND;
		break;
	default:
		fprintf(stderr, "copen: unknown option %d", *iopt);
		exit(2);
		break;
	}
	switch (knew) {
	case 0:
		break;
	case 1:
		kopt = kopt | O_EXCL | O_CREAT;
		break;
	case 2:
		kopt = kopt | O_TRUNC | O_CREAT;
		break;
	default:
		fprintf(stderr, "copen: unknown status %d", *inew);
		exit(2);
		break;
	}
	errno = 0;
	*ichan = (long) open(pname, kopt);
	*ierrno = (long) errno;
}

cclose_(ichan, ires, ierrno)
	long           *ichan, *ires, *ierrno;
{
	extern int      errno;
	extern int      close();
	errno = 0;
	*ires = (long) close((int) (*ichan));
	*ierrno = (long) errno;
}

cread_(ichan, pbuf, pnbyt, ires, ierrno)
	char           *pbuf;
	long           *ichan, *pnbyt, *ires, *ierrno;
{
	errno = 0;
	*ires = (long) read((int) (*ichan), pbuf, (size_t) (*pnbyt));
	*ierrno = (long) errno;
}

cwrite_(ichan, pbuf, pnbyt, ires, ierrno)
	char           *pbuf;
	long           *ichan, *pnbyt, *ires, *ierrno;
{
  extern int      errno;
	errno = 0;
	/* *ires = (long) write((int) (*ichan), pbuf, (int) (*pnbyt)); twb 04.20.09 */
 	*ires = (long) write((int) (*ichan), pbuf, (size_t) (*pnbyt));
	*ierrno = (long) errno;
	/* fprintf(stderr,"in cwrite: ires %i pnbyt %i\n",*ires,*pnbyt); */
}

clseek_(ichan, offst, iopt, ires, ierrno)
	long           *ichan, *offst, *iopt, *ires, *ierrno;
{
	extern int      errno;
	int             kopt;
	kopt = (int) (*iopt);
	switch (kopt) {
	case 0:
		kopt = SEEK_SET;
		break;
	case 1:
	        kopt = SEEK_CUR;
		break;
	case 2:
		kopt = SEEK_END;
		break;
	default:
		fprintf(stderr, "clseek: unknown optiion %d", *iopt);
		exit(2);
		break;
	}
	errno = 0;
	*ires = (long) lseek((int) (*ichan), (*offst), kopt);
	*ierrno = (long) errno;
}

cmtio_(ichan, iop, icnt, ires, ierrno)
	long           *ichan, *iop, *icnt, *ires, *ierrno;
{
	extern int      errno;
	int             kopt;
	struct mtop     magop;
	kopt = (int) (*iop);
	switch (kopt) {
	case 0:
		kopt = MTWEOF;
		break;
	case 1:
		kopt = MTFSF;
		break;
	case 2:
		kopt = MTBSF;
		break;
	case 3:
		kopt = MTFSR;
		break;
	case 4:
		kopt = MTBSR;
		break;
	case 5:
		kopt = MTREW;
		break;
	case 6:
		kopt = MTOFFL;
		break;
	case 7:
		kopt = MTNOP;
		break;
	default:
		fprintf(stderr, "cmtio: unknown optiion %d", *iop);
		exit(2);
		break;
	}
	magop.mt_op = kopt;
	magop.mt_count = (long) (*icnt);
	errno = 0;
	*ires = (long) ioctl((int) (*ichan), MTIOCTOP, &magop);
	*ierrno = (long) errno;
}


cperror_(s)
	char           *s;
{
	perror(s);
}

csleep_(psec)
	long           *psec;
{
	int             idum;
	idum = sleep((unsigned) (*psec));
}
/* This has been disabled */
cusleep_(psec)
	long           *psec;
{
	int             idum;
	/* idum = usleep((unsigned) (*psec)); */
}

cfstat_(ichan, size, istat, ierrno)
	long           *ichan, *size, *istat, *ierrno;
{
/* #define fstat fstat_ this was tried by Lapo - commented out 2004.03.14 */
	extern int      errno;
/*	extern int      fstat(); this was in original, sh suggest remove 2004.03.14 */
	extern int      fstat();
	int             dummy;
	errno = 0;
	/* printf("calling fstat in c\n"); */
	dummy = fstat((int) (*ichan), &buf);
	/* printf("fstat through in c\n"); */
	*ierrno = (long) errno;
	*size = (long) (buf.st_size);
	*istat = (long) (buf.st_mode);
}

cstat_(file, size, block, istat, timea, timem, ierrno)
	char           *file;
	long           *size, *block, *istat, *timea, *timem, *ierrno;
{
	extern int      errno;
	extern int      stat();
	int             dummy;
	errno = 0;
	dummy = stat(file, &buf);
	*ierrno = (long) errno;
	*size = (long) (buf.st_size);
	*istat = (long) (buf.st_mode);
        *block= buf.st_blksize;
	*timea=(long) buf.st_atime;
	*timem=(long) buf.st_mtime;
}

ctrun_(ichan, leng, ierrno)
	long           *ichan, *leng, *ierrno;
{
	extern int      errno, ftruncate();
	int             dummy;
	errno = 0;
	dummy = ftruncate((int) (*ichan), (unsigned long) (*leng));
	*ierrno = (long) errno;
}


cgetpid_(ires,ierrno)
	long   *ires,*ierrno;
{
	extern int errno;
	errno = 0;
	*ires=(long)getpid();
	*ierrno = (long) errno;
}

cgetppid_(ires,ierrno)
	long   *ires,*ierrno;
{
	extern int errno;
	errno = 0;
	*ires=(long)getppid();
	*ierrno = (long) errno;
}


/* this used to be called creadlink - i don't think its used anywhere */
creadlinkg_(path, file, namlen, ierrno)
	char		*path, *file;
	int		*namlen, *ierrno;
{
  extern int	errno;
	int		dummy;
	errno = 0;
	dummy = readlink(path, file, (size_t)*namlen);
	if (dummy = -1) { *ierrno = errno; };
	if (dummy!= -1) { *ierrno = dummy; };
}
