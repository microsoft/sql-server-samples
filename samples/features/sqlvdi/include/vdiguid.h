

/* this ALWAYS GENERATED file contains the IIDs and CLSIDs */

/* link this file in with the server and any clients */


 /* File created by MIDL compiler version 7.00.0408 */
/* at Tue Sep 28 18:18:04 2004
 */
/* Compiler settings for vdi.idl:
    Oicf, W1, Zp8, env=Win32 (32b run)
    protocol : dce , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
//@@MIDL_FILE_HEADING(  )

#if !defined(_M_IA64) && !defined(_M_AMD64)


#pragma warning( disable: 4049 )  /* more than 64k source lines */


#ifdef __cplusplus
extern "C"{
#endif 


#include <rpc.h>
#include <rpcndr.h>

#ifdef _MIDL_USE_GUIDDEF_

#ifndef INITGUID
#define INITGUID
#include <guiddef.h>
#undef INITGUID
#else
#include <guiddef.h>
#endif

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        DEFINE_GUID(name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8)

#else // !_MIDL_USE_GUIDDEF_

#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        const type name = {l,w1,w2,{b1,b2,b3,b4,b5,b6,b7,b8}}

#endif !_MIDL_USE_GUIDDEF_

MIDL_DEFINE_GUID(IID, IID_IClientVirtualDevice,0x40700424,0x0080,0x11d2,0x85,0x1f,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IClientVirtualDeviceSet,0x40700425,0x0080,0x11d2,0x85,0x1f,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IClientVirtualDeviceSet2,0xd0e6eb07,0x7a62,0x11d2,0x85,0x73,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IServerVirtualDevice,0xb5e7a131,0xa7bd,0x11d1,0x84,0xc2,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IServerVirtualDeviceSet,0xb5e7a132,0xa7bd,0x11d1,0x84,0xc2,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IServerVirtualDeviceSet2,0xAECBD0D6,0x24C6,0x11d3,0x85,0xB7,0x00,0xC0,0x4F,0xC2,0x17,0x59);

#undef MIDL_DEFINE_GUID

#ifdef __cplusplus
}
#endif



#endif /* !defined(_M_IA64) && !defined(_M_AMD64)*/



/* this ALWAYS GENERATED file contains the IIDs and CLSIDs */

/* link this file in with the server and any clients */


 /* File created by MIDL compiler version 7.00.0408 */
/* at Tue Sep 28 18:18:04 2004
 */
/* Compiler settings for vdi.idl:
    Oicf, W1, Zp8, env=Win64 (32b run,appending)
    protocol : dce , ms_ext, c_ext, robust
    error checks: allocation ref bounds_check enum stub_data 
    VC __declspec() decoration level: 
         __declspec(uuid()), __declspec(selectany), __declspec(novtable)
         DECLSPEC_UUID(), MIDL_INTERFACE()
*/
//@@MIDL_FILE_HEADING(  )

#if defined(_M_IA64) || defined(_M_AMD64)


#pragma warning( disable: 4049 )  /* more than 64k source lines */


#ifdef __cplusplus
extern "C"{
#endif 


#include <rpc.h>
#include <rpcndr.h>

#ifdef _MIDL_USE_GUIDDEF_

#ifndef INITGUID
#define INITGUID
#include <guiddef.h>
#undef INITGUID
#else
#include <guiddef.h>
#endif

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        DEFINE_GUID(name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8)

#else // !_MIDL_USE_GUIDDEF_

#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

#define MIDL_DEFINE_GUID(type,name,l,w1,w2,b1,b2,b3,b4,b5,b6,b7,b8) \
        const type name = {l,w1,w2,{b1,b2,b3,b4,b5,b6,b7,b8}}

#endif !_MIDL_USE_GUIDDEF_

MIDL_DEFINE_GUID(IID, IID_IClientVirtualDevice,0x40700424,0x0080,0x11d2,0x85,0x1f,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IClientVirtualDeviceSet,0x40700425,0x0080,0x11d2,0x85,0x1f,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IClientVirtualDeviceSet2,0xd0e6eb07,0x7a62,0x11d2,0x85,0x73,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IServerVirtualDevice,0xb5e7a131,0xa7bd,0x11d1,0x84,0xc2,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IServerVirtualDeviceSet,0xb5e7a132,0xa7bd,0x11d1,0x84,0xc2,0x00,0xc0,0x4f,0xc2,0x17,0x59);


MIDL_DEFINE_GUID(IID, IID_IServerVirtualDeviceSet2,0xAECBD0D6,0x24C6,0x11d3,0x85,0xB7,0x00,0xC0,0x4F,0xC2,0x17,0x59);

#undef MIDL_DEFINE_GUID

#ifdef __cplusplus
}
#endif



#endif /* defined(_M_IA64) || defined(_M_AMD64)*/

