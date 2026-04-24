$parameters = $args[0]

$subscriptionId = $parameters['subscriptionId']
$resourceGroupName = $parameters['resourceGroupName']
$managedInstanceName =  $parameters['managedInstanceName']
$publicKeyFile = $parameters['publicKeyFile']
$privateKeyFile = $parameters['privateKeyFile']
$password = $parameters['password']

$Assem = @()

$Source = @"
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

namespace CL
{
    public static class CertUtil
    {
        private static class Native
        {
            public const uint ALG_CLASS_DATA_ENCRYPT = (3 << 13);
            public const uint ALG_CLASS_HASH = (4 << 13);
            public const uint ALG_SID_RC4 = 1;
            public const uint ALG_SID_SHA1 = 4;
            public const uint ALG_TYPE_ANY = 0;
            public const uint ALG_TYPE_STREAM = (4 << 9);
            public const uint AT_KEYEXCHANGE = 1;
            public const uint BLGP_STRONG_KEY_LENGTH = 0x0080;
            public const uint CALG_RC4 = (ALG_CLASS_DATA_ENCRYPT | ALG_TYPE_STREAM | ALG_SID_RC4);
            public const uint CALG_SHA1 = (ALG_CLASS_HASH | ALG_TYPE_ANY | ALG_SID_SHA1);
            public const uint CERT_KEY_PROV_INFO_PROP_ID = 2;
            public const uint CERT_SET_KEY_PROV_HANDLE_PROP_ID = 0x00000001;
            public const uint CERT_STORE_ADD_REPLACE_EXISTING_INHERIT_PROPERTIES = 5;
            public const uint CERT_STORE_PROV_MEMORY = 2;
            public const uint CERT_CLOSE_STORE_CHECK_FLAG = 2;
            public const uint CRYPT_NEWKEYSET = 0x00000008;
            public const uint EXPORT_PRIVATE_KEYS = 0x0004;
            public const uint PKCS_7_ASN_ENCODING = 0x00010000;
            public const uint PROV_RSA_FULL = 1;
            public const uint X509_ASN_ENCODING = 0x00000001;


            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptAcquireContext(ref IntPtr phProv, string szContainer, string szProvider, uint dwProvType, uint dwFlags);

            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptReleaseContext(IntPtr hProv, uint dwFlags);


            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptCreateHash(IntPtr hProv, uint Algid, IntPtr hKey, uint dwFlags, ref IntPtr phHash);

            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptHashData(IntPtr hHash, byte[] pbData, uint dwDataLen, uint dwFlags);

            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptDestroyHash(IntPtr hHash);


            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptDeriveKey(IntPtr hProv, uint Algid, IntPtr hBaseData, uint dwFlags, ref IntPtr phKey);

            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptImportKey(IntPtr hProv, byte[] pbData, UInt32 dwDataLen, IntPtr hPubKey, UInt32 dwFlags, ref IntPtr phKey);

            [DllImport("advapi32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptDestroyKey(IntPtr phKey);


            [DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CryptExportPublicKeyInfo(IntPtr hCryptProv, uint dwKeySpec, uint dwCertEncodingType, IntPtr pInfo, ref int pcbInfo);

            [DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern IntPtr CertCreateCertificateContext(uint dwCertEncodingType, IntPtr pbCertEncoded, int cbCertEncoded);

            [DllImport("crypt32.dll", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CertFreeCertificateContext(IntPtr pCertContext);

            [DllImport("crypt32.DLL", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern IntPtr CertOpenStore(uint dwStoreProvider, uint dwEncodingType, IntPtr hCryptProv, uint dwFlags, IntPtr pvPara);

            [DllImport("crypt32.DLL", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern IntPtr CertCloseStore(IntPtr hCertStore, uint dwFlags);

            [DllImport("crypt32.DLL", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CertAddCertificateContextToStore(IntPtr hCertStore, IntPtr pCertContext, uint dwAddDisposition, ref IntPtr ppStoreContext);

            [DllImport("crypt32.DLL", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool CertSetCertificateContextProperty(IntPtr pCertContext, uint dwPropId, uint dwFlags, ref CRYPT_KEY_PROV_INFO pvData);

            [DllImport("crypt32.DLL", CharSet = CharSet.Auto, SetLastError = true)]
            public static extern bool PFXExportCertStoreEx(IntPtr hStore, ref CRYPT_DATA_BLOB pPFX, IntPtr szPassword, IntPtr pvPara, uint dwFlags);


            [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
            public struct CRYPT_KEY_PROV_INFO
            {
                [MarshalAs(UnmanagedType.LPWStr)]
                public string pwszContainerName;
                [MarshalAs(UnmanagedType.LPWStr)]
                public string pwszProvName;
                public uint dwProvType;
                public uint dwFlags;
                public uint cProvParam;
                public IntPtr rgProvParam;
                public uint dwKeySpec;
            }

            [StructLayout(LayoutKind.Sequential)]
            internal struct CRYPT_DATA_BLOB
            {
                public int cbData;
                public IntPtr pbData;
            }
        }


        private static bool ImportPvk(IntPtr phProv, byte[] privateKeyBytes, string password, ref IntPtr privateKey)
        {
            privateKey = IntPtr.Zero;
            var result = false;
            using (var ms = new MemoryStream(privateKeyBytes))
            using (var r = new BinaryReader(ms))
            {
                var magic = r.ReadInt32();
                var reserved = r.ReadInt32();
                var keytype = r.ReadInt32();
                var encrypted = r.ReadInt32();
                var saltLength = r.ReadInt32();
                var keyLength = r.ReadInt32();
                var salt = r.ReadBytes(saltLength);

                var key = r.ReadBytes(keyLength);

                var enc = Encoding.UTF8;
                var passwordBytes = enc.GetBytes(password);

                var pHash = IntPtr.Zero;
                var phKey = IntPtr.Zero;

                if (!Native.CryptCreateHash(phProv, Native.CALG_SHA1, IntPtr.Zero, 0, ref pHash))
                {
                    goto End;
                }

                if (!Native.CryptHashData(pHash, salt, (uint)salt.Length, 0))
                {
                    goto End;
                }

                if (!Native.CryptHashData(pHash, passwordBytes, (uint)passwordBytes.Length, 0))
                {
                    goto End;
                }

                if (!Native.CryptDeriveKey(phProv, Native.CALG_RC4, pHash, Native.BLGP_STRONG_KEY_LENGTH << 16, ref phKey))
                {
                    goto End;
                }

                if (!Native.CryptImportKey(phProv, key, (uint)keyLength, phKey, 1, ref privateKey))
                {
                    goto End;
                }

                result = true;

                End:
                {
                    if (pHash != IntPtr.Zero)
                    {
                        Native.CryptDestroyHash(pHash);
                    }
                    if (phKey != IntPtr.Zero)
                    {
                        Native.CryptDestroyKey(phKey);
                    }
                }
                return result;
            }
        }

        public static string CerPvkToPfx(string publicKeyBlob, string privateKeyBlob, string password)
        {
            string result = null;

            var publicKeyBytes = Convert.FromBase64String(publicKeyBlob);
            var privateKeyBytes = Convert.FromBase64String(privateKeyBlob);

            var container = Guid.NewGuid().ToString();

            var phProv = IntPtr.Zero;
            var pPublicKeyInfo = IntPtr.Zero;
            var pPrivateKey = IntPtr.Zero;
            var pPublicKey = IntPtr.Zero;
            var pCertificateContext = IntPtr.Zero;
            var pMemoryStore = IntPtr.Zero;
            var pNewCertificateContext = IntPtr.Zero;
            var pszPassword = IntPtr.Zero;
            GCHandle pfxDataHandle = default(GCHandle);

            if (!Native.CryptAcquireContext(ref phProv, container, null, 1, Native.CRYPT_NEWKEYSET))
            {
                goto End;
            }

            if (!ImportPvk(phProv, privateKeyBytes, password, ref pPrivateKey))
            {
                goto End;
            }

            var keySpec = Native.AT_KEYEXCHANGE;
            var pubKeyInfoCb = 0;
            if (!Native.CryptExportPublicKeyInfo(phProv, keySpec, Native.PKCS_7_ASN_ENCODING | Native.X509_ASN_ENCODING, IntPtr.Zero, ref pubKeyInfoCb))
            {
                goto End;
            }

            pPublicKeyInfo = Marshal.AllocHGlobal(pubKeyInfoCb);
            if (!Native.CryptExportPublicKeyInfo(phProv, keySpec, Native.PKCS_7_ASN_ENCODING | Native.X509_ASN_ENCODING, pPublicKeyInfo, ref pubKeyInfoCb))
            {
                goto End;
            }

            var publicKeySize = publicKeyBytes.Length;
            pPublicKey = Marshal.AllocHGlobal(publicKeySize);
            Marshal.Copy(publicKeyBytes, 0, pPublicKey, publicKeySize);
            pCertificateContext = Native.CertCreateCertificateContext(Native.PKCS_7_ASN_ENCODING | Native.X509_ASN_ENCODING, pPublicKey, publicKeySize);
            if (pCertificateContext == IntPtr.Zero)
            {
                goto End;
            }

            pMemoryStore = Native.CertOpenStore(Native.CERT_STORE_PROV_MEMORY, 0, IntPtr.Zero, 0, IntPtr.Zero);
            if (pMemoryStore == IntPtr.Zero)
            {
                goto End;
            }

            if (!Native.CertAddCertificateContextToStore(pMemoryStore, pCertificateContext, Native.CERT_STORE_ADD_REPLACE_EXISTING_INHERIT_PROPERTIES, ref pNewCertificateContext))
            {
                goto End;
            }

            var cryptKeyProvInfo = new Native.CRYPT_KEY_PROV_INFO();
            cryptKeyProvInfo.pwszContainerName = container;
            cryptKeyProvInfo.dwProvType = Native.PROV_RSA_FULL;
            cryptKeyProvInfo.dwFlags = Native.CERT_SET_KEY_PROV_HANDLE_PROP_ID;
            cryptKeyProvInfo.dwKeySpec = keySpec;

            if (!Native.CertSetCertificateContextProperty(pNewCertificateContext, Native.CERT_KEY_PROV_INFO_PROP_ID, 0, ref cryptKeyProvInfo))
            {
                goto End;
            }

            var cryptDataBlob = new Native.CRYPT_DATA_BLOB();
            pszPassword = Marshal.StringToHGlobalUni(password);
            if (!Native.PFXExportCertStoreEx(pMemoryStore, ref cryptDataBlob, pszPassword, IntPtr.Zero, Native.EXPORT_PRIVATE_KEYS))
            {
                goto End;
            }

            var pfxData = new byte[cryptDataBlob.cbData];
            pfxDataHandle = GCHandle.Alloc(pfxData, GCHandleType.Pinned);
            cryptDataBlob.pbData = pfxDataHandle.AddrOfPinnedObject();

            if (!Native.PFXExportCertStoreEx(pMemoryStore, ref cryptDataBlob, pszPassword, IntPtr.Zero, Native.EXPORT_PRIVATE_KEYS))
            {
                goto End;
            }

            result = Convert.ToBase64String(pfxData);

            End:
            {
                if (pPublicKey != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(pPublicKey);
                }
                if (pPublicKeyInfo != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(pPublicKeyInfo);
                }
                if (pPrivateKey != IntPtr.Zero)
                {
                    Native.CryptDestroyKey(pPrivateKey);
                }
                if (pCertificateContext != IntPtr.Zero)
                {
                    Native.CertFreeCertificateContext(pCertificateContext);
                }
                if (pNewCertificateContext != IntPtr.Zero)
                {
                    Native.CertFreeCertificateContext(pNewCertificateContext);
                }
                if (pMemoryStore != IntPtr.Zero)
                {
                    Native.CertCloseStore(pMemoryStore, Native.CERT_CLOSE_STORE_CHECK_FLAG);
                }
                if (pszPassword != IntPtr.Zero)
                {
                    Marshal.FreeHGlobal(pszPassword);
                }
                if (pfxDataHandle.IsAllocated)
                {
                    pfxDataHandle.Free();
                }
                if (phProv != IntPtr.Zero)
                {
                    Native.CryptReleaseContext(phProv, 0u);
                }
            }

            return result;
        }
    }
}

"@

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp -ErrorAction SilentlyContinue

function EnsureLogin ()
{
    $context = Get-AzureRmContext
    If( $null -eq $context.Subscription)
    {
        Write-Host "Loging in ..."
        If($null -eq (Login-AzureRmAccount -ErrorAction SilentlyContinue -ErrorVariable Errors))
        {
            Write-Host ("Login failed: {0}" -f $Errors[0].Exception.Message) -ForegroundColor Red
            Break
        }
    }
    Write-Host "User logedin." -ForegroundColor Green
}

function Select-SubscriptionId {
    param (
        $subscriptionId
    )
    Write-Host "Selecting subscription '$subscriptionId'."
    $context = Get-AzureRmContext
    If($context.Subscription.Id -ne $subscriptionId)
    {
        Try
        {
            Select-AzureRmSubscription -SubscriptionId $subscriptionId -ErrorAction Stop | Out-null
        }
        Catch
        {
            Write-Host "Subscription selection failed: $_" -ForegroundColor Red
            Break
        }
    }
    Write-Host "Subscription selected." -ForegroundColor Green
}

function VerifyPSVersion
{
    Write-Host "Verifying PowerShell version, must be 5.0 or higher."
    if($PSVersionTable.PSVersion.Major -ge 5)
    {
        Write-Host "PowerShell version verified." -ForegroundColor Green
    }
    else
    {
        Write-Host "You need to install PowerShell version 5.0 or heigher." -ForegroundColor Red
        Break;
    }
}

function EnsureSqlModule
{
    function VerifySqlModule
    {
        param ($module)

        Write-Host "Verifying AzureRM.Sql module version, must be 4.10.0.0 or higher."
        if(
            ($module.Version.Major -gt 4) -or
            (($module.Version.Major -eq 4) -and ($module.Version.Minor -ge 10))
          )
        {
            Write-Host "Module AzureRM.Sql verified." -ForegroundColor Green
        }
        else
        {
            Write-Host "Trying to update AzureRM.Sql module."
            try
            {
                Update-Module AzureRM.Sql -ErrorAction Stop | Out-null
                Write-Host "AzureRM.Sql module updated, you need to restart session for changes to be applied." -ForegroundColor Yellow
            }
            catch
            {
                Write-Host "Update module failed: $_" -ForegroundColor Yellow
                Write-Host "Trying to install AzureRM.Sql module."
                try
                {
                    Install-Module AzureRM.Sql -Force -ErrorAction Stop | Out-null
                    Write-Host "AzureRM.Sql module installed, you need to restart session for changes to be applied." -ForegroundColor Yellow
                }
                catch
                {
                    Write-Host "Install module failed: $_" -ForegroundColor Red
                }
            }
            Break;
        }
    }

    Write-Host "Checking if AzureRM.Sql module is imported."
    $module = Get-Module AzureRM.Sql
    If($null -eq $module)
    {
        Import-Module AzureRM.Sql
        $module = Get-Module AzureRM.Sql
        Write-Host "Module AzureRM.Sql imported." -ForegroundColor Green
    }
    VerifySqlModule $module
}

VerifyPSVersion
EnsureSqlModule

EnsureLogin

Select-SubscriptionId -subscriptionId $subscriptionId

Write-Host "Loading .cer file."

$publicKeyBytes = Get-Content $publicKeyFile -Encoding Byte
$base64EncodedPublicKey = [System.Convert]::ToBase64String($publicKeyBytes)

Write-Host "Loading .pvk file."

$privateKeyBytes = Get-Content $privateKeyFile -Encoding Byte
$base64EncodedPrivateKey = [System.Convert]::ToBase64String($privateKeyBytes)

Write-Host "Creating .pfx blob."

$base64EncodedCert = [CL.CertUtil]::CerPvkToPfx($base64EncodedPublicKey, $base64EncodedPrivateKey, $password)

$securePrivateBlob = $base64EncodedCert  | ConvertTo-SecureString -AsPlainText -Force
$securePassword = $password | ConvertTo-SecureString -AsPlainText -Force

Write-Host "Adding TDE certificate."


Try
{
    Add-AzureRmSqlManagedInstanceTransparentDataEncryptionCertificate -ResourceGroupName $resourceGroupName -ManagedInstanceName $managedInstanceName -PrivateBlob $securePrivateBlob -Password $securePassword -ErrorAction Stop | Out-Null
    Write-Host "TDE certificate added." -ForegroundColor Green
}
Catch
{
    Write-Host "Failed: $_" -ForegroundColor Red
}






