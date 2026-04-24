

/* this ALWAYS GENERATED file contains the definitions for the interfaces */


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

#pragma warning( disable: 4049 )  /* more than 64k source lines */


/* verify that the <rpcndr.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCNDR_H_VERSION__
#define __REQUIRED_RPCNDR_H_VERSION__ 475
#endif

#include "rpc.h"
#include "rpcndr.h"

#ifndef __RPCNDR_H_VERSION__
#error this stub requires an updated version of <rpcndr.h>
#endif // __RPCNDR_H_VERSION__

#ifndef COM_NO_WINDOWS_H
#include "windows.h"
#include "ole2.h"
#endif /*COM_NO_WINDOWS_H*/

#ifndef __vdi_h__
#define __vdi_h__

#if defined(_MSC_VER) && (_MSC_VER >= 1020)
#pragma once
#endif

/* Forward Declarations */ 

#ifndef __IClientVirtualDevice_FWD_DEFINED__
#define __IClientVirtualDevice_FWD_DEFINED__
typedef interface IClientVirtualDevice IClientVirtualDevice;
#endif 	/* __IClientVirtualDevice_FWD_DEFINED__ */


#ifndef __IClientVirtualDeviceSet_FWD_DEFINED__
#define __IClientVirtualDeviceSet_FWD_DEFINED__
typedef interface IClientVirtualDeviceSet IClientVirtualDeviceSet;
#endif 	/* __IClientVirtualDeviceSet_FWD_DEFINED__ */


#ifndef __IClientVirtualDeviceSet2_FWD_DEFINED__
#define __IClientVirtualDeviceSet2_FWD_DEFINED__
typedef interface IClientVirtualDeviceSet2 IClientVirtualDeviceSet2;
#endif 	/* __IClientVirtualDeviceSet2_FWD_DEFINED__ */


#ifndef __IServerVirtualDevice_FWD_DEFINED__
#define __IServerVirtualDevice_FWD_DEFINED__
typedef interface IServerVirtualDevice IServerVirtualDevice;
#endif 	/* __IServerVirtualDevice_FWD_DEFINED__ */


#ifndef __IServerVirtualDeviceSet_FWD_DEFINED__
#define __IServerVirtualDeviceSet_FWD_DEFINED__
typedef interface IServerVirtualDeviceSet IServerVirtualDeviceSet;
#endif 	/* __IServerVirtualDeviceSet_FWD_DEFINED__ */


#ifndef __IServerVirtualDeviceSet2_FWD_DEFINED__
#define __IServerVirtualDeviceSet2_FWD_DEFINED__
typedef interface IServerVirtualDeviceSet2 IServerVirtualDeviceSet2;
#endif 	/* __IServerVirtualDeviceSet2_FWD_DEFINED__ */


/* header files for imported files */
#include "unknwn.h"

#ifdef __cplusplus
extern "C"{
#endif 

void * __RPC_USER MIDL_user_allocate(size_t);
void __RPC_USER MIDL_user_free( void * ); 

/* interface __MIDL_itf_vdi_0000 */
/* [local] */ 


#pragma pack(push, _vdi_h_)

#pragma pack(8)
struct VDConfig
    {
    unsigned long deviceCount;
    unsigned long features;
    unsigned long prefixZoneSize;
    unsigned long alignment;
    unsigned long softFileMarkBlockSize;
    unsigned long EOMWarningSize;
    unsigned long serverTimeOut;
    unsigned long blockSize;
    unsigned long maxIODepth;
    unsigned long maxTransferSize;
    unsigned long bufferAreaSize;
    } ;

enum VDFeatures
    {	VDF_Removable	= 0x1,
	VDF_Rewind	= 0x2,
	VDF_Position	= 0x10,
	VDF_SkipBlocks	= 0x20,
	VDF_ReversePosition	= 0x40,
	VDF_Discard	= 0x80,
	VDF_FileMarks	= 0x100,
	VDF_RandomAccess	= 0x200,
	VDF_SnapshotPrepare	= 0x400,
	VDF_EnumFrozenFiles	= 0x800,
	VDF_VSSWriter	= 0x1000,
	VDF_WriteMedia	= 0x10000,
	VDF_ReadMedia	= 0x20000,
	VDF_LatchStats	= 0x80000000,
	VDF_LikePipe	= 0,
	VDF_LikeTape	= ( ( ( ( ( VDF_FileMarks | VDF_Removable )  | VDF_Rewind )  | VDF_Position )  | VDF_SkipBlocks )  | VDF_ReversePosition ) ,
	VDF_LikeDisk	= VDF_RandomAccess
    } ;

enum VDCommands
    {	VDC_Read	= 1,
	VDC_Write	= ( VDC_Read + 1 ) ,
	VDC_ClearError	= ( VDC_Write + 1 ) ,
	VDC_Rewind	= ( VDC_ClearError + 1 ) ,
	VDC_WriteMark	= ( VDC_Rewind + 1 ) ,
	VDC_SkipMarks	= ( VDC_WriteMark + 1 ) ,
	VDC_SkipBlocks	= ( VDC_SkipMarks + 1 ) ,
	VDC_Load	= ( VDC_SkipBlocks + 1 ) ,
	VDC_GetPosition	= ( VDC_Load + 1 ) ,
	VDC_SetPosition	= ( VDC_GetPosition + 1 ) ,
	VDC_Discard	= ( VDC_SetPosition + 1 ) ,
	VDC_Flush	= ( VDC_Discard + 1 ) ,
	VDC_Snapshot	= ( VDC_Flush + 1 ) ,
	VDC_MountSnapshot	= ( VDC_Snapshot + 1 ) ,
	VDC_PrepareToFreeze	= ( VDC_MountSnapshot + 1 ) ,
	VDC_FileInfoBegin	= ( VDC_PrepareToFreeze + 1 ) ,
	VDC_FileInfoEnd	= ( VDC_FileInfoBegin + 1 ) 
    } ;

enum VDWhence
    {	VDC_Beginning	= 0,
	VDC_Current	= ( VDC_Beginning + 1 ) ,
	VDC_End	= ( VDC_Current + 1 ) 
    } ;
struct VDC_Command
    {
    DWORD commandCode;
    DWORD size;
    DWORDLONG position;
    BYTE *buffer;
    } ;


extern RPC_IF_HANDLE __MIDL_itf_vdi_0000_v0_0_c_ifspec;
extern RPC_IF_HANDLE __MIDL_itf_vdi_0000_v0_0_s_ifspec;

#ifndef __IClientVirtualDevice_INTERFACE_DEFINED__
#define __IClientVirtualDevice_INTERFACE_DEFINED__

/* interface IClientVirtualDevice */
/* [object][uuid] */ 


EXTERN_C const IID IID_IClientVirtualDevice;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("40700424-0080-11d2-851f-00c04fc21759")
    IClientVirtualDevice : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE GetCommand( 
            /* [in] */ DWORD dwTimeOut,
            /* [out] */ struct VDC_Command **ppCmd) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE CompleteCommand( 
            /* [in] */ struct VDC_Command *pCmd,
            /* [in] */ DWORD dwCompletionCode,
            /* [in] */ DWORD dwBytesTransferred,
            /* [in] */ DWORDLONG dwlPosition) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IClientVirtualDeviceVtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IClientVirtualDevice * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IClientVirtualDevice * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IClientVirtualDevice * This);
        
        HRESULT ( STDMETHODCALLTYPE *GetCommand )( 
            IClientVirtualDevice * This,
            /* [in] */ DWORD dwTimeOut,
            /* [out] */ struct VDC_Command **ppCmd);
        
        HRESULT ( STDMETHODCALLTYPE *CompleteCommand )( 
            IClientVirtualDevice * This,
            /* [in] */ struct VDC_Command *pCmd,
            /* [in] */ DWORD dwCompletionCode,
            /* [in] */ DWORD dwBytesTransferred,
            /* [in] */ DWORDLONG dwlPosition);
        
        END_INTERFACE
    } IClientVirtualDeviceVtbl;

    interface IClientVirtualDevice
    {
        CONST_VTBL struct IClientVirtualDeviceVtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IClientVirtualDevice_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IClientVirtualDevice_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IClientVirtualDevice_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#define IClientVirtualDevice_GetCommand(This,dwTimeOut,ppCmd)	\
    ( (This)->lpVtbl -> GetCommand(This,dwTimeOut,ppCmd) ) 

#define IClientVirtualDevice_CompleteCommand(This,pCmd,dwCompletionCode,dwBytesTransferred,dwlPosition)	\
    ( (This)->lpVtbl -> CompleteCommand(This,pCmd,dwCompletionCode,dwBytesTransferred,dwlPosition) ) 

#endif /* COBJMACROS */


#endif 	/* C style interface */



HRESULT STDMETHODCALLTYPE IClientVirtualDevice_GetCommand_Proxy( 
    IClientVirtualDevice * This,
    /* [in] */ DWORD dwTimeOut,
    /* [out] */ struct VDC_Command **ppCmd);


void __RPC_STUB IClientVirtualDevice_GetCommand_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDevice_CompleteCommand_Proxy( 
    IClientVirtualDevice * This,
    /* [in] */ struct VDC_Command *pCmd,
    /* [in] */ DWORD dwCompletionCode,
    /* [in] */ DWORD dwBytesTransferred,
    /* [in] */ DWORDLONG dwlPosition);


void __RPC_STUB IClientVirtualDevice_CompleteCommand_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IClientVirtualDevice_INTERFACE_DEFINED__ */


#ifndef __IClientVirtualDeviceSet_INTERFACE_DEFINED__
#define __IClientVirtualDeviceSet_INTERFACE_DEFINED__

/* interface IClientVirtualDeviceSet */
/* [object][uuid] */ 


EXTERN_C const IID IID_IClientVirtualDeviceSet;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("40700425-0080-11d2-851f-00c04fc21759")
    IClientVirtualDeviceSet : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE Create( 
            /* [in] */ LPCWSTR lpName,
            /* [in] */ struct VDConfig *pCfg) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE GetConfiguration( 
            /* [in] */ DWORD dwTimeOut,
            /* [out] */ struct VDConfig *pCfg) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE OpenDevice( 
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IClientVirtualDevice **ppVirtualDevice) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE Close( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE SignalAbort( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE OpenInSecondary( 
            /* [in] */ LPCWSTR lpSetName) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE GetBufferHandle( 
            /* [in] */ BYTE *pBuffer,
            /* [out] */ DWORD *pBufferHandle) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE MapBufferHandle( 
            /* [in] */ DWORD dwBuffer,
            /* [out] */ BYTE **ppBuffer) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IClientVirtualDeviceSetVtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IClientVirtualDeviceSet * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IClientVirtualDeviceSet * This);
        
        HRESULT ( STDMETHODCALLTYPE *Create )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ LPCWSTR lpName,
            /* [in] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *GetConfiguration )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ DWORD dwTimeOut,
            /* [out] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *OpenDevice )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IClientVirtualDevice **ppVirtualDevice);
        
        HRESULT ( STDMETHODCALLTYPE *Close )( 
            IClientVirtualDeviceSet * This);
        
        HRESULT ( STDMETHODCALLTYPE *SignalAbort )( 
            IClientVirtualDeviceSet * This);
        
        HRESULT ( STDMETHODCALLTYPE *OpenInSecondary )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ LPCWSTR lpSetName);
        
        HRESULT ( STDMETHODCALLTYPE *GetBufferHandle )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ BYTE *pBuffer,
            /* [out] */ DWORD *pBufferHandle);
        
        HRESULT ( STDMETHODCALLTYPE *MapBufferHandle )( 
            IClientVirtualDeviceSet * This,
            /* [in] */ DWORD dwBuffer,
            /* [out] */ BYTE **ppBuffer);
        
        END_INTERFACE
    } IClientVirtualDeviceSetVtbl;

    interface IClientVirtualDeviceSet
    {
        CONST_VTBL struct IClientVirtualDeviceSetVtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IClientVirtualDeviceSet_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IClientVirtualDeviceSet_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IClientVirtualDeviceSet_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#define IClientVirtualDeviceSet_Create(This,lpName,pCfg)	\
    ( (This)->lpVtbl -> Create(This,lpName,pCfg) ) 

#define IClientVirtualDeviceSet_GetConfiguration(This,dwTimeOut,pCfg)	\
    ( (This)->lpVtbl -> GetConfiguration(This,dwTimeOut,pCfg) ) 

#define IClientVirtualDeviceSet_OpenDevice(This,lpName,ppVirtualDevice)	\
    ( (This)->lpVtbl -> OpenDevice(This,lpName,ppVirtualDevice) ) 

#define IClientVirtualDeviceSet_Close(This)	\
    ( (This)->lpVtbl -> Close(This) ) 

#define IClientVirtualDeviceSet_SignalAbort(This)	\
    ( (This)->lpVtbl -> SignalAbort(This) ) 

#define IClientVirtualDeviceSet_OpenInSecondary(This,lpSetName)	\
    ( (This)->lpVtbl -> OpenInSecondary(This,lpSetName) ) 

#define IClientVirtualDeviceSet_GetBufferHandle(This,pBuffer,pBufferHandle)	\
    ( (This)->lpVtbl -> GetBufferHandle(This,pBuffer,pBufferHandle) ) 

#define IClientVirtualDeviceSet_MapBufferHandle(This,dwBuffer,ppBuffer)	\
    ( (This)->lpVtbl -> MapBufferHandle(This,dwBuffer,ppBuffer) ) 

#endif /* COBJMACROS */


#endif 	/* C style interface */



HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_Create_Proxy( 
    IClientVirtualDeviceSet * This,
    /* [in] */ LPCWSTR lpName,
    /* [in] */ struct VDConfig *pCfg);


void __RPC_STUB IClientVirtualDeviceSet_Create_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_GetConfiguration_Proxy( 
    IClientVirtualDeviceSet * This,
    /* [in] */ DWORD dwTimeOut,
    /* [out] */ struct VDConfig *pCfg);


void __RPC_STUB IClientVirtualDeviceSet_GetConfiguration_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_OpenDevice_Proxy( 
    IClientVirtualDeviceSet * This,
    /* [in] */ LPCWSTR lpName,
    /* [out] */ IClientVirtualDevice **ppVirtualDevice);


void __RPC_STUB IClientVirtualDeviceSet_OpenDevice_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_Close_Proxy( 
    IClientVirtualDeviceSet * This);


void __RPC_STUB IClientVirtualDeviceSet_Close_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_SignalAbort_Proxy( 
    IClientVirtualDeviceSet * This);


void __RPC_STUB IClientVirtualDeviceSet_SignalAbort_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_OpenInSecondary_Proxy( 
    IClientVirtualDeviceSet * This,
    /* [in] */ LPCWSTR lpSetName);


void __RPC_STUB IClientVirtualDeviceSet_OpenInSecondary_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_GetBufferHandle_Proxy( 
    IClientVirtualDeviceSet * This,
    /* [in] */ BYTE *pBuffer,
    /* [out] */ DWORD *pBufferHandle);


void __RPC_STUB IClientVirtualDeviceSet_GetBufferHandle_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet_MapBufferHandle_Proxy( 
    IClientVirtualDeviceSet * This,
    /* [in] */ DWORD dwBuffer,
    /* [out] */ BYTE **ppBuffer);


void __RPC_STUB IClientVirtualDeviceSet_MapBufferHandle_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IClientVirtualDeviceSet_INTERFACE_DEFINED__ */


#ifndef __IClientVirtualDeviceSet2_INTERFACE_DEFINED__
#define __IClientVirtualDeviceSet2_INTERFACE_DEFINED__

/* interface IClientVirtualDeviceSet2 */
/* [object][uuid] */ 


EXTERN_C const IID IID_IClientVirtualDeviceSet2;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("d0e6eb07-7a62-11d2-8573-00c04fc21759")
    IClientVirtualDeviceSet2 : public IClientVirtualDeviceSet
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE CreateEx( 
            /* [in] */ LPCWSTR lpInstanceName,
            /* [in] */ LPCWSTR lpName,
            /* [in] */ struct VDConfig *pCfg) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE OpenInSecondaryEx( 
            /* [in] */ LPCWSTR lpInstanceName,
            /* [in] */ LPCWSTR lpSetName) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IClientVirtualDeviceSet2Vtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IClientVirtualDeviceSet2 * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IClientVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *Create )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpName,
            /* [in] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *GetConfiguration )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ DWORD dwTimeOut,
            /* [out] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *OpenDevice )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IClientVirtualDevice **ppVirtualDevice);
        
        HRESULT ( STDMETHODCALLTYPE *Close )( 
            IClientVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *SignalAbort )( 
            IClientVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *OpenInSecondary )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpSetName);
        
        HRESULT ( STDMETHODCALLTYPE *GetBufferHandle )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ BYTE *pBuffer,
            /* [out] */ DWORD *pBufferHandle);
        
        HRESULT ( STDMETHODCALLTYPE *MapBufferHandle )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ DWORD dwBuffer,
            /* [out] */ BYTE **ppBuffer);
        
        HRESULT ( STDMETHODCALLTYPE *CreateEx )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpInstanceName,
            /* [in] */ LPCWSTR lpName,
            /* [in] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *OpenInSecondaryEx )( 
            IClientVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpInstanceName,
            /* [in] */ LPCWSTR lpSetName);
        
        END_INTERFACE
    } IClientVirtualDeviceSet2Vtbl;

    interface IClientVirtualDeviceSet2
    {
        CONST_VTBL struct IClientVirtualDeviceSet2Vtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IClientVirtualDeviceSet2_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IClientVirtualDeviceSet2_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IClientVirtualDeviceSet2_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#define IClientVirtualDeviceSet2_Create(This,lpName,pCfg)	\
    ( (This)->lpVtbl -> Create(This,lpName,pCfg) ) 

#define IClientVirtualDeviceSet2_GetConfiguration(This,dwTimeOut,pCfg)	\
    ( (This)->lpVtbl -> GetConfiguration(This,dwTimeOut,pCfg) ) 

#define IClientVirtualDeviceSet2_OpenDevice(This,lpName,ppVirtualDevice)	\
    ( (This)->lpVtbl -> OpenDevice(This,lpName,ppVirtualDevice) ) 

#define IClientVirtualDeviceSet2_Close(This)	\
    ( (This)->lpVtbl -> Close(This) ) 

#define IClientVirtualDeviceSet2_SignalAbort(This)	\
    ( (This)->lpVtbl -> SignalAbort(This) ) 

#define IClientVirtualDeviceSet2_OpenInSecondary(This,lpSetName)	\
    ( (This)->lpVtbl -> OpenInSecondary(This,lpSetName) ) 

#define IClientVirtualDeviceSet2_GetBufferHandle(This,pBuffer,pBufferHandle)	\
    ( (This)->lpVtbl -> GetBufferHandle(This,pBuffer,pBufferHandle) ) 

#define IClientVirtualDeviceSet2_MapBufferHandle(This,dwBuffer,ppBuffer)	\
    ( (This)->lpVtbl -> MapBufferHandle(This,dwBuffer,ppBuffer) ) 


#define IClientVirtualDeviceSet2_CreateEx(This,lpInstanceName,lpName,pCfg)	\
    ( (This)->lpVtbl -> CreateEx(This,lpInstanceName,lpName,pCfg) ) 

#define IClientVirtualDeviceSet2_OpenInSecondaryEx(This,lpInstanceName,lpSetName)	\
    ( (This)->lpVtbl -> OpenInSecondaryEx(This,lpInstanceName,lpSetName) ) 

#endif /* COBJMACROS */


#endif 	/* C style interface */



HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet2_CreateEx_Proxy( 
    IClientVirtualDeviceSet2 * This,
    /* [in] */ LPCWSTR lpInstanceName,
    /* [in] */ LPCWSTR lpName,
    /* [in] */ struct VDConfig *pCfg);


void __RPC_STUB IClientVirtualDeviceSet2_CreateEx_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IClientVirtualDeviceSet2_OpenInSecondaryEx_Proxy( 
    IClientVirtualDeviceSet2 * This,
    /* [in] */ LPCWSTR lpInstanceName,
    /* [in] */ LPCWSTR lpSetName);


void __RPC_STUB IClientVirtualDeviceSet2_OpenInSecondaryEx_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IClientVirtualDeviceSet2_INTERFACE_DEFINED__ */


/* interface __MIDL_itf_vdi_0011 */
/* [local] */ 

struct VDS_Command
    {
    DWORD commandCode;
    DWORD size;
    DWORDLONG inPosition;
    DWORDLONG outPosition;
    BYTE *buffer;
    BYTE *completionRoutine;
    BYTE *completionContext;
    DWORD completionCode;
    DWORD bytesTransferred;
    } ;


extern RPC_IF_HANDLE __MIDL_itf_vdi_0011_v0_0_c_ifspec;
extern RPC_IF_HANDLE __MIDL_itf_vdi_0011_v0_0_s_ifspec;

#ifndef __IServerVirtualDevice_INTERFACE_DEFINED__
#define __IServerVirtualDevice_INTERFACE_DEFINED__

/* interface IServerVirtualDevice */
/* [object][uuid] */ 


EXTERN_C const IID IID_IServerVirtualDevice;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("b5e7a131-a7bd-11d1-84c2-00c04fc21759")
    IServerVirtualDevice : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE SendCommand( 
            /* [in] */ struct VDS_Command *pCmd) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE CloseDevice( void) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IServerVirtualDeviceVtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IServerVirtualDevice * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IServerVirtualDevice * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IServerVirtualDevice * This);
        
        HRESULT ( STDMETHODCALLTYPE *SendCommand )( 
            IServerVirtualDevice * This,
            /* [in] */ struct VDS_Command *pCmd);
        
        HRESULT ( STDMETHODCALLTYPE *CloseDevice )( 
            IServerVirtualDevice * This);
        
        END_INTERFACE
    } IServerVirtualDeviceVtbl;

    interface IServerVirtualDevice
    {
        CONST_VTBL struct IServerVirtualDeviceVtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IServerVirtualDevice_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IServerVirtualDevice_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IServerVirtualDevice_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#define IServerVirtualDevice_SendCommand(This,pCmd)	\
    ( (This)->lpVtbl -> SendCommand(This,pCmd) ) 

#define IServerVirtualDevice_CloseDevice(This)	\
    ( (This)->lpVtbl -> CloseDevice(This) ) 

#endif /* COBJMACROS */


#endif 	/* C style interface */



HRESULT STDMETHODCALLTYPE IServerVirtualDevice_SendCommand_Proxy( 
    IServerVirtualDevice * This,
    /* [in] */ struct VDS_Command *pCmd);


void __RPC_STUB IServerVirtualDevice_SendCommand_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDevice_CloseDevice_Proxy( 
    IServerVirtualDevice * This);


void __RPC_STUB IServerVirtualDevice_CloseDevice_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IServerVirtualDevice_INTERFACE_DEFINED__ */


#ifndef __IServerVirtualDeviceSet_INTERFACE_DEFINED__
#define __IServerVirtualDeviceSet_INTERFACE_DEFINED__

/* interface IServerVirtualDeviceSet */
/* [object][uuid] */ 


EXTERN_C const IID IID_IServerVirtualDeviceSet;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("b5e7a132-a7bd-11d1-84c2-00c04fc21759")
    IServerVirtualDeviceSet : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE Open( 
            /* [in] */ LPCWSTR lpName) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE GetConfiguration( 
            /* [out] */ struct VDConfig *pCfg) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE SetConfiguration( 
            /* [in] */ struct VDConfig *pCfg) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE ExecuteCompletionAgent( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE OpenDevice( 
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IServerVirtualDevice **ppVirtualDevice) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE AllocateBuffer( 
            /* [out] */ BYTE **ppBuffer,
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE FreeBuffer( 
            /* [in] */ BYTE *pBuffer,
            /* [in] */ DWORD dwSize) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE IsSharedBuffer( 
            /* [in] */ BYTE *pBuffer) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE SignalAbort( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE Close( void) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IServerVirtualDeviceSetVtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IServerVirtualDeviceSet * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IServerVirtualDeviceSet * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IServerVirtualDeviceSet * This);
        
        HRESULT ( STDMETHODCALLTYPE *Open )( 
            IServerVirtualDeviceSet * This,
            /* [in] */ LPCWSTR lpName);
        
        HRESULT ( STDMETHODCALLTYPE *GetConfiguration )( 
            IServerVirtualDeviceSet * This,
            /* [out] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *SetConfiguration )( 
            IServerVirtualDeviceSet * This,
            /* [in] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *ExecuteCompletionAgent )( 
            IServerVirtualDeviceSet * This);
        
        HRESULT ( STDMETHODCALLTYPE *OpenDevice )( 
            IServerVirtualDeviceSet * This,
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IServerVirtualDevice **ppVirtualDevice);
        
        HRESULT ( STDMETHODCALLTYPE *AllocateBuffer )( 
            IServerVirtualDeviceSet * This,
            /* [out] */ BYTE **ppBuffer,
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment);
        
        HRESULT ( STDMETHODCALLTYPE *FreeBuffer )( 
            IServerVirtualDeviceSet * This,
            /* [in] */ BYTE *pBuffer,
            /* [in] */ DWORD dwSize);
        
        HRESULT ( STDMETHODCALLTYPE *IsSharedBuffer )( 
            IServerVirtualDeviceSet * This,
            /* [in] */ BYTE *pBuffer);
        
        HRESULT ( STDMETHODCALLTYPE *SignalAbort )( 
            IServerVirtualDeviceSet * This);
        
        HRESULT ( STDMETHODCALLTYPE *Close )( 
            IServerVirtualDeviceSet * This);
        
        END_INTERFACE
    } IServerVirtualDeviceSetVtbl;

    interface IServerVirtualDeviceSet
    {
        CONST_VTBL struct IServerVirtualDeviceSetVtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IServerVirtualDeviceSet_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IServerVirtualDeviceSet_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IServerVirtualDeviceSet_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#define IServerVirtualDeviceSet_Open(This,lpName)	\
    ( (This)->lpVtbl -> Open(This,lpName) ) 

#define IServerVirtualDeviceSet_GetConfiguration(This,pCfg)	\
    ( (This)->lpVtbl -> GetConfiguration(This,pCfg) ) 

#define IServerVirtualDeviceSet_SetConfiguration(This,pCfg)	\
    ( (This)->lpVtbl -> SetConfiguration(This,pCfg) ) 

#define IServerVirtualDeviceSet_ExecuteCompletionAgent(This)	\
    ( (This)->lpVtbl -> ExecuteCompletionAgent(This) ) 

#define IServerVirtualDeviceSet_OpenDevice(This,lpName,ppVirtualDevice)	\
    ( (This)->lpVtbl -> OpenDevice(This,lpName,ppVirtualDevice) ) 

#define IServerVirtualDeviceSet_AllocateBuffer(This,ppBuffer,dwSize,dwAlignment)	\
    ( (This)->lpVtbl -> AllocateBuffer(This,ppBuffer,dwSize,dwAlignment) ) 

#define IServerVirtualDeviceSet_FreeBuffer(This,pBuffer,dwSize)	\
    ( (This)->lpVtbl -> FreeBuffer(This,pBuffer,dwSize) ) 

#define IServerVirtualDeviceSet_IsSharedBuffer(This,pBuffer)	\
    ( (This)->lpVtbl -> IsSharedBuffer(This,pBuffer) ) 

#define IServerVirtualDeviceSet_SignalAbort(This)	\
    ( (This)->lpVtbl -> SignalAbort(This) ) 

#define IServerVirtualDeviceSet_Close(This)	\
    ( (This)->lpVtbl -> Close(This) ) 

#endif /* COBJMACROS */


#endif 	/* C style interface */



HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_Open_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [in] */ LPCWSTR lpName);


void __RPC_STUB IServerVirtualDeviceSet_Open_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_GetConfiguration_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [out] */ struct VDConfig *pCfg);


void __RPC_STUB IServerVirtualDeviceSet_GetConfiguration_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_SetConfiguration_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [in] */ struct VDConfig *pCfg);


void __RPC_STUB IServerVirtualDeviceSet_SetConfiguration_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_ExecuteCompletionAgent_Proxy( 
    IServerVirtualDeviceSet * This);


void __RPC_STUB IServerVirtualDeviceSet_ExecuteCompletionAgent_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_OpenDevice_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [in] */ LPCWSTR lpName,
    /* [out] */ IServerVirtualDevice **ppVirtualDevice);


void __RPC_STUB IServerVirtualDeviceSet_OpenDevice_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_AllocateBuffer_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [out] */ BYTE **ppBuffer,
    /* [in] */ DWORD dwSize,
    /* [in] */ DWORD dwAlignment);


void __RPC_STUB IServerVirtualDeviceSet_AllocateBuffer_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_FreeBuffer_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [in] */ BYTE *pBuffer,
    /* [in] */ DWORD dwSize);


void __RPC_STUB IServerVirtualDeviceSet_FreeBuffer_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_IsSharedBuffer_Proxy( 
    IServerVirtualDeviceSet * This,
    /* [in] */ BYTE *pBuffer);


void __RPC_STUB IServerVirtualDeviceSet_IsSharedBuffer_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_SignalAbort_Proxy( 
    IServerVirtualDeviceSet * This);


void __RPC_STUB IServerVirtualDeviceSet_SignalAbort_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet_Close_Proxy( 
    IServerVirtualDeviceSet * This);


void __RPC_STUB IServerVirtualDeviceSet_Close_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IServerVirtualDeviceSet_INTERFACE_DEFINED__ */


#ifndef __IServerVirtualDeviceSet2_INTERFACE_DEFINED__
#define __IServerVirtualDeviceSet2_INTERFACE_DEFINED__

/* interface IServerVirtualDeviceSet2 */
/* [object][uuid] */ 


EXTERN_C const IID IID_IServerVirtualDeviceSet2;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("AECBD0D6-24C6-11d3-85B7-00C04FC21759")
    IServerVirtualDeviceSet2 : public IUnknown
    {
    public:
        virtual HRESULT STDMETHODCALLTYPE Open( 
            /* [in] */ LPCWSTR lpInstanceName,
            /* [in] */ LPCWSTR lpSetName) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE GetConfiguration( 
            /* [out] */ struct VDConfig *pCfg) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE BeginConfiguration( 
            /* [in] */ DWORD dwFeatures,
            /* [in] */ DWORD dwBlockSize,
            /* [in] */ DWORD dwAlignment,
            /* [in] */ DWORD dwMaxTransferSize,
            /* [in] */ DWORD dwTimeout) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE EndConfiguration( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE RequestBuffers( 
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment,
            /* [in] */ DWORD dwCount) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE QueryAvailableBuffers( 
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment,
            /* [out] */ DWORD *pCount) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE ExecuteCompletionAgent( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE OpenDevice( 
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IServerVirtualDevice **ppVirtualDevice) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE AllocateBuffer( 
            /* [out] */ BYTE **ppBuffer,
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE FreeBuffer( 
            /* [in] */ BYTE *pBuffer,
            /* [in] */ DWORD dwSize) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE IsSharedBuffer( 
            /* [in] */ BYTE *pBuffer) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE SignalAbort( void) = 0;
        
        virtual HRESULT STDMETHODCALLTYPE Close( void) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IServerVirtualDeviceSet2Vtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE *QueryInterface )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void **ppvObject);
        
        ULONG ( STDMETHODCALLTYPE *AddRef )( 
            IServerVirtualDeviceSet2 * This);
        
        ULONG ( STDMETHODCALLTYPE *Release )( 
            IServerVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *Open )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpInstanceName,
            /* [in] */ LPCWSTR lpSetName);
        
        HRESULT ( STDMETHODCALLTYPE *GetConfiguration )( 
            IServerVirtualDeviceSet2 * This,
            /* [out] */ struct VDConfig *pCfg);
        
        HRESULT ( STDMETHODCALLTYPE *BeginConfiguration )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ DWORD dwFeatures,
            /* [in] */ DWORD dwBlockSize,
            /* [in] */ DWORD dwAlignment,
            /* [in] */ DWORD dwMaxTransferSize,
            /* [in] */ DWORD dwTimeout);
        
        HRESULT ( STDMETHODCALLTYPE *EndConfiguration )( 
            IServerVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *RequestBuffers )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment,
            /* [in] */ DWORD dwCount);
        
        HRESULT ( STDMETHODCALLTYPE *QueryAvailableBuffers )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment,
            /* [out] */ DWORD *pCount);
        
        HRESULT ( STDMETHODCALLTYPE *ExecuteCompletionAgent )( 
            IServerVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *OpenDevice )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ LPCWSTR lpName,
            /* [out] */ IServerVirtualDevice **ppVirtualDevice);
        
        HRESULT ( STDMETHODCALLTYPE *AllocateBuffer )( 
            IServerVirtualDeviceSet2 * This,
            /* [out] */ BYTE **ppBuffer,
            /* [in] */ DWORD dwSize,
            /* [in] */ DWORD dwAlignment);
        
        HRESULT ( STDMETHODCALLTYPE *FreeBuffer )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ BYTE *pBuffer,
            /* [in] */ DWORD dwSize);
        
        HRESULT ( STDMETHODCALLTYPE *IsSharedBuffer )( 
            IServerVirtualDeviceSet2 * This,
            /* [in] */ BYTE *pBuffer);
        
        HRESULT ( STDMETHODCALLTYPE *SignalAbort )( 
            IServerVirtualDeviceSet2 * This);
        
        HRESULT ( STDMETHODCALLTYPE *Close )( 
            IServerVirtualDeviceSet2 * This);
        
        END_INTERFACE
    } IServerVirtualDeviceSet2Vtbl;

    interface IServerVirtualDeviceSet2
    {
        CONST_VTBL struct IServerVirtualDeviceSet2Vtbl *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IServerVirtualDeviceSet2_QueryInterface(This,riid,ppvObject)	\
    ( (This)->lpVtbl -> QueryInterface(This,riid,ppvObject) ) 

#define IServerVirtualDeviceSet2_AddRef(This)	\
    ( (This)->lpVtbl -> AddRef(This) ) 

#define IServerVirtualDeviceSet2_Release(This)	\
    ( (This)->lpVtbl -> Release(This) ) 


#define IServerVirtualDeviceSet2_Open(This,lpInstanceName,lpSetName)	\
    ( (This)->lpVtbl -> Open(This,lpInstanceName,lpSetName) ) 

#define IServerVirtualDeviceSet2_GetConfiguration(This,pCfg)	\
    ( (This)->lpVtbl -> GetConfiguration(This,pCfg) ) 

#define IServerVirtualDeviceSet2_BeginConfiguration(This,dwFeatures,dwBlockSize,dwAlignment,dwMaxTransferSize,dwTimeout)	\
    ( (This)->lpVtbl -> BeginConfiguration(This,dwFeatures,dwBlockSize,dwAlignment,dwMaxTransferSize,dwTimeout) ) 

#define IServerVirtualDeviceSet2_EndConfiguration(This)	\
    ( (This)->lpVtbl -> EndConfiguration(This) ) 

#define IServerVirtualDeviceSet2_RequestBuffers(This,dwSize,dwAlignment,dwCount)	\
    ( (This)->lpVtbl -> RequestBuffers(This,dwSize,dwAlignment,dwCount) ) 

#define IServerVirtualDeviceSet2_QueryAvailableBuffers(This,dwSize,dwAlignment,pCount)	\
    ( (This)->lpVtbl -> QueryAvailableBuffers(This,dwSize,dwAlignment,pCount) ) 

#define IServerVirtualDeviceSet2_ExecuteCompletionAgent(This)	\
    ( (This)->lpVtbl -> ExecuteCompletionAgent(This) ) 

#define IServerVirtualDeviceSet2_OpenDevice(This,lpName,ppVirtualDevice)	\
    ( (This)->lpVtbl -> OpenDevice(This,lpName,ppVirtualDevice) ) 

#define IServerVirtualDeviceSet2_AllocateBuffer(This,ppBuffer,dwSize,dwAlignment)	\
    ( (This)->lpVtbl -> AllocateBuffer(This,ppBuffer,dwSize,dwAlignment) ) 

#define IServerVirtualDeviceSet2_FreeBuffer(This,pBuffer,dwSize)	\
    ( (This)->lpVtbl -> FreeBuffer(This,pBuffer,dwSize) ) 

#define IServerVirtualDeviceSet2_IsSharedBuffer(This,pBuffer)	\
    ( (This)->lpVtbl -> IsSharedBuffer(This,pBuffer) ) 

#define IServerVirtualDeviceSet2_SignalAbort(This)	\
    ( (This)->lpVtbl -> SignalAbort(This) ) 

#define IServerVirtualDeviceSet2_Close(This)	\
    ( (This)->lpVtbl -> Close(This) ) 

#endif /* COBJMACROS */


#endif 	/* C style interface */



HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_Open_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ LPCWSTR lpInstanceName,
    /* [in] */ LPCWSTR lpSetName);


void __RPC_STUB IServerVirtualDeviceSet2_Open_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_GetConfiguration_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [out] */ struct VDConfig *pCfg);


void __RPC_STUB IServerVirtualDeviceSet2_GetConfiguration_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_BeginConfiguration_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ DWORD dwFeatures,
    /* [in] */ DWORD dwBlockSize,
    /* [in] */ DWORD dwAlignment,
    /* [in] */ DWORD dwMaxTransferSize,
    /* [in] */ DWORD dwTimeout);


void __RPC_STUB IServerVirtualDeviceSet2_BeginConfiguration_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_EndConfiguration_Proxy( 
    IServerVirtualDeviceSet2 * This);


void __RPC_STUB IServerVirtualDeviceSet2_EndConfiguration_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_RequestBuffers_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ DWORD dwSize,
    /* [in] */ DWORD dwAlignment,
    /* [in] */ DWORD dwCount);


void __RPC_STUB IServerVirtualDeviceSet2_RequestBuffers_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_QueryAvailableBuffers_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ DWORD dwSize,
    /* [in] */ DWORD dwAlignment,
    /* [out] */ DWORD *pCount);


void __RPC_STUB IServerVirtualDeviceSet2_QueryAvailableBuffers_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_ExecuteCompletionAgent_Proxy( 
    IServerVirtualDeviceSet2 * This);


void __RPC_STUB IServerVirtualDeviceSet2_ExecuteCompletionAgent_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_OpenDevice_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ LPCWSTR lpName,
    /* [out] */ IServerVirtualDevice **ppVirtualDevice);


void __RPC_STUB IServerVirtualDeviceSet2_OpenDevice_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_AllocateBuffer_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [out] */ BYTE **ppBuffer,
    /* [in] */ DWORD dwSize,
    /* [in] */ DWORD dwAlignment);


void __RPC_STUB IServerVirtualDeviceSet2_AllocateBuffer_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_FreeBuffer_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ BYTE *pBuffer,
    /* [in] */ DWORD dwSize);


void __RPC_STUB IServerVirtualDeviceSet2_FreeBuffer_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_IsSharedBuffer_Proxy( 
    IServerVirtualDeviceSet2 * This,
    /* [in] */ BYTE *pBuffer);


void __RPC_STUB IServerVirtualDeviceSet2_IsSharedBuffer_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_SignalAbort_Proxy( 
    IServerVirtualDeviceSet2 * This);


void __RPC_STUB IServerVirtualDeviceSet2_SignalAbort_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


HRESULT STDMETHODCALLTYPE IServerVirtualDeviceSet2_Close_Proxy( 
    IServerVirtualDeviceSet2 * This);


void __RPC_STUB IServerVirtualDeviceSet2_Close_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IServerVirtualDeviceSet2_INTERFACE_DEFINED__ */


/* interface __MIDL_itf_vdi_0014 */
/* [local] */ 

const IID CLSID_WINFS_ClientVirtualDeviceSet = {0x50b99b13, 0x7b84, 0x44d3, {0x9c, 0x98, 0x26, 0x52, 0xbf, 0x14, 0x4d, 0x96}};
const IID CLSID_WINFS_ServerVirtualDeviceSet = {0x92e6b26b, 0x57da, 0x47ed, {0x81, 0x53, 0xdf, 0xf1, 0x87, 0xa7, 0x6d, 0xde}};
#define CLSID_MSSQL_ClientVirtualDeviceSet IID_IClientVirtualDeviceSet
#define CLSID_MSSQL_ServerVirtualDeviceSet IID_IServerVirtualDeviceSet

#pragma pack(pop, _vdi_h_)


extern RPC_IF_HANDLE __MIDL_itf_vdi_0014_v0_0_c_ifspec;
extern RPC_IF_HANDLE __MIDL_itf_vdi_0014_v0_0_s_ifspec;

/* Additional Prototypes for ALL interfaces */

/* end of Additional Prototypes */

#ifdef __cplusplus
}
#endif

#endif


