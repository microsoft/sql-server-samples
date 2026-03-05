$parameters = $args[0]

$hostName = $parameters['hostName']
$port = $parameters['port']
$publicCertificateFile = $parameters['publicCertificateFile']

$Assem = @()

$Source = @" 

using System;
using System.IO;

namespace CL
{
    /// <summary>
    /// Enum describing TDS Message Status
    /// </summary>
    public enum TDSMessageStatus : byte
    {
        /// <summary>
        /// Normal TDS Message Status
        /// </summary>
        Normal,

        /// <summary>
        /// TDS Message Terminator
        /// The packet is the last packet in the whole request.
        /// </summary>
        EndOfMessage,

        /// <summary>
        /// IgnoreEvent TDS Message Status
        /// Ignore this event (0x01 MUST also be set).
        /// </summary>
        IgnoreEvent,

        /// <summary>
        /// ResetConnection TDS Message Status
        /// Reset this connection before processing event.
        /// </summary>
        ResetConnection = 0x08,

        /// <summary>
        /// ResetConnectionSkipTran TDS Message Status
        /// Reset the connection before processing event but do not modify the transaction
        /// state (the state will remain the same before and after the reset). 
        /// </summary>
        ResetConnectionSkipTran = 0x10
    }

    /// <summary>
    /// Enum describing TDS Message Type
    /// </summary>
    public enum TDSMessageType : byte
    {
        /// <summary>
        /// SQL Batch Message
        /// </summary>
        SQLBatch = 1,

        /// <summary>
        /// TDS7 Pre Login Message
        /// </summary>
        PreTDS7Login,

        /// <summary>
        ///  RPC Message
        /// </summary>
        RPC,

        /// <summary>
        /// Tabular Result Message
        /// </summary>
        TabularResult,

        /// <summary>
        /// Attention Signal Message
        /// </summary>
        AttentionSignal = 6,

        /// <summary>
        /// Bulk Load Data Message
        /// </summary>
        BulkLoadData,

        /// <summary>
        /// Federated Authentication Token Message
        /// </summary>
        FedAuthToken,

        /// <summary>
        /// Transaction Manager Request Message
        /// </summary>
        TransactionManagerRequest = 14,

        /// <summary>
        /// TDS7 Login Message
        /// </summary>
        TDS7Login = 16,

        /// <summary>
        /// SSPI Message
        /// </summary>
        SSPI,

        /// <summary>
        /// PreLogin Message
        /// </summary>
        PreLogin
    }

    /// <summary>
    /// Utility class used for read and write operations on a stream containing data in big-endian byte order
    /// </summary>
    public static class BigEndianUtilities
    {
        /// <summary>
        /// Used to write value to stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream to to write the value to.</param>
        /// <param name="value">Value to write to MemoryStream.</param>
        public static void WriteUShort(MemoryStream stream, ushort value)
        {
            stream.WriteByte((byte)(value >> 8));
            stream.WriteByte((byte)value);
        }

        /// <summary>
        /// Used to write value to stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream to to write the value to.</param>
        /// <param name="value">Value to write to MemoryStream.</param>
        public static void WriteUInt(MemoryStream stream, uint value)
        {
            stream.WriteByte((byte)(value >> 24));
            stream.WriteByte((byte)(value >> 16));
            stream.WriteByte((byte)(value >> 8));
            stream.WriteByte((byte)value);
        }

        /// <summary>
        /// Used to write value to stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream to to write the value to.</param>
        /// <param name="value">Value to write to MemoryStream.</param>
        public static void WriteULong(MemoryStream stream, ulong value)
        {
            stream.WriteByte((byte)(value >> 56));
            stream.WriteByte((byte)(value >> 48));
            stream.WriteByte((byte)(value >> 40));
            stream.WriteByte((byte)(value >> 32));
            stream.WriteByte((byte)(value >> 24));
            stream.WriteByte((byte)(value >> 16));
            stream.WriteByte((byte)(value >> 8));
            stream.WriteByte((byte)value);
        }

        /// <summary>
        /// Used to write byte array to stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream to to write the value to.</param>
        /// <param name="array">Array to write to MemoryStream.</param>
        public static void WriteByteArray(MemoryStream stream, byte[] array)
        {
            for (int i = array.Length - 1; i >= 0; i--)
            {
                stream.WriteByte(array[i]);
            }
        }

        /// <summary>
        /// Used to read a UShort value from stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream from which to read the value.</param>
        /// <returns>UShort value read from the stream.</returns>
        public static ushort ReadUShort(MemoryStream stream)
        {
            ushort result = 0;
            for (int i = 0; i < 2; i++)
            {
                result <<= 8;
                result |= Convert.ToByte(stream.ReadByte());
            }

            return result;
        }

        /// <summary>
        /// Used to read a UInt value from stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream from which to read the value.</param>
        /// <returns>UInt value read from the stream.</returns>
        public static uint ReadUInt(MemoryStream stream)
        {
            uint result = 0;
            for (int i = 0; i < 4; i++)
            {
                result <<= 8;
                result |= Convert.ToByte(stream.ReadByte());
            }

            return result;
        }

        /// <summary>
        /// Used to read a ULong value from stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream from which to read the value.</param>
        /// <returns>ULong value read from the stream.</returns>
        public static ulong ReadULong(MemoryStream stream)
        {
            ulong result = 0;
            for (int i = 0; i < 8; i++)
            {
                result <<= 8;
                result |= Convert.ToByte(stream.ReadByte());
            }

            return result;
        }

        /// <summary>
        /// Used to read a byte array from stream in big endian order.
        /// </summary>
        /// <param name="stream">MemoryStream from which to read the array.</param>
        /// <param name="length">Length of the array to read.</param>
        /// <returns>Byte Array read from the stream.</returns>
        public static byte[] ReadByteArray(MemoryStream stream, uint length)
        {
            byte[] result = new byte[length];
            for (int i = 1; i <= length; i++)
            {
                result[length - i] = Convert.ToByte(stream.ReadByte());
            }

            return result;
        }
    }

    /// <summary>
    /// Class describing TDS Packet Header
    /// </summary>
    public class TDSPacketHeader
    {
        /// <summary>
        /// Initializes a new instance of the <see cref="TDSPacketHeader" /> class.
        /// </summary>
        public TDSPacketHeader()
        {
        }

        /// <summary>
        /// Initializes a new instance of the <see cref="TDSPacketHeader" /> class.
        /// </summary>
        /// <param name="type">TDS Message Type</param>
        /// <param name="status">TDS Message Status</param>
        /// <param name="spid">SPID number</param>
        /// <param name="packet">Packet number</param>
        /// <param name="window">Window number</param>
        public TDSPacketHeader(TDSMessageType type, TDSMessageStatus status, ushort spid = 0x0000, byte packet = 0x00, byte window = 0x00)
        {
            this.Type = type;
            this.Status = status;
            this.SPID = spid;
            this.Packet = packet;
            this.Window = window;
        }

        /// <summary>
        /// Gets or sets TDS Message Type.
        /// </summary>
        public TDSMessageType Type { get; set; }

        /// <summary>
        /// Gets or sets TDS Message Status.
        /// </summary>
        public TDSMessageStatus Status { get; set; }

        /// <summary>
        /// Gets or sets TDS Message Length.
        /// </summary>
        public ushort Length { get; set; }

        /// <summary>
        /// Gets or sets SPID.
        /// </summary>
        public ushort SPID { get; set; }

        /// <summary>
        /// Gets or sets Packet Number.
        /// </summary>
        public byte Packet { get; set; }

        /// <summary>
        /// Gets or sets Window Number.
        /// </summary>
        public byte Window { get; set; }

        /// <summary>
        /// Gets converted (to int) Packet Length.
        /// </summary>
        public int ConvertedPacketLength
        {
            get
            {
                return Convert.ToInt32(this.Length);
            }
        }

        /// <summary>
        /// Used to pack IPackageable to a stream.
        /// </summary>
        /// <param name="stream">MemoryStream in which IPackageable is packet into.</param>
        public void Pack(MemoryStream stream)
        {
            stream.WriteByte((byte)this.Type);
            stream.WriteByte((byte)this.Status);
            BigEndianUtilities.WriteUShort(stream, this.Length);
            BigEndianUtilities.WriteUShort(stream, this.SPID);
            stream.WriteByte(this.Packet);
            stream.WriteByte(this.Window);
        }

        /// <summary>
        /// Used to unpack IPackageable from a stream.
        /// </summary>
        /// <param name="stream">MemoryStream from which to unpack IPackageable.</param>
        /// <returns>Returns true if successful.</returns>
        public bool Unpack(MemoryStream stream)
        {
            this.Type = (TDSMessageType)stream.ReadByte();
            this.Status = (TDSMessageStatus)stream.ReadByte();
            this.Length = BigEndianUtilities.ReadUShort(stream);
            this.SPID = BigEndianUtilities.ReadUShort(stream);
            this.Packet = Convert.ToByte(stream.ReadByte());
            this.Window = Convert.ToByte(stream.ReadByte());

            return true;
        }
    }

    /// <summary>
    /// Stream used to pass TDS messages.
    /// </summary>
    public class TDSStream : Stream
    {
        /// <summary>
        /// TDS Packet Size used for communication
        /// </summary>
        private readonly int negotiatedPacketSize;

        /// <summary>
        /// Current Inbound TDS Packet Header
        /// </summary>
        private TDSPacketHeader currentInboundTDSHeader;

        /// <summary>
        /// Current position within the Inbound TDS Packet
        /// </summary>
        private int currentInboundPacketPosition;

        /// <summary>
        /// Current Outbound TDS Packet Header
        /// </summary>
        private TDSPacketHeader currentOutboundTDSHeader;

        /// <summary>
        /// TDS Connection Timeout
        /// </summary>
        private TimeSpan timeout;

        /// <summary>
        /// Initializes a new instance of the <see cref="TDSStream"/> class.
        /// </summary>
        /// <param name="innerStream">Inner stream used for communication</param>
        /// <param name="timeout">Communication failure timeout</param>
        /// <param name="negotiatedPacketSize">Packet size</param>
        public TDSStream(Stream innerStream, TimeSpan timeout, int negotiatedPacketSize)
        {
            this.InnerStream = innerStream;
            this.timeout = timeout;
            this.negotiatedPacketSize = negotiatedPacketSize;
        }

        /// <summary>
        /// Gets or sets the Inner Stream.
        /// </summary>
        public Stream InnerStream { get; set; }

        /// <summary>
        /// Gets a value indicating whether inbound message is terminated.
        /// </summary>
        public bool InboundMessageTerminated
        {
            get
            {
                return this.currentInboundTDSHeader == null;
            }
        }

        /// <summary>
        /// Gets or sets the current outbound message type.
        /// </summary>
        public TDSMessageType CurrentOutboundMessageType { get; set; }

        /// <summary>
        /// Gets or sets CanTimeout Flag.
        /// </summary>
        public override bool CanTimeout { get { return true; } }

        /// <summary>
        /// Gets or sets CanRead Flag.
        /// </summary>
        public override bool CanRead { get { return this.InnerStream.CanRead; } }

        /// <summary>
        /// Gets or sets CanSeek Flag.
        /// </summary>
        public override bool CanSeek { get { return this.InnerStream.CanSeek; } }

        /// <summary>
        /// Gets or sets CanWrite Flag.
        /// </summary>
        public override bool CanWrite { get { return this.InnerStream.CanWrite; } }

        /// <summary>
        /// Gets or sets Stream Length.
        /// </summary>
        public override long Length { get { return this.InnerStream.Length; } }

        /// <summary>
        /// Gets or sets Stream Position.
        /// </summary>
        public override long Position
        {
            get
            {
                return this.InnerStream.Position;
            }
            set
            {
                this.InnerStream.Position = value;
            }
        }

        /// <summary>
        /// Flushes stream output.
        /// </summary>
        public override void Flush()
        {
            this.InnerStream.Flush();
        }

        /// <summary>
        /// Reads from stream.
        /// </summary>
        /// <param name="buffer">Buffer used to store read data.</param>
        /// <param name="offset">Offset within buffer.</param>
        /// <param name="count">Number of bytes to read.</param>
        /// <returns>Returns number of successfully read bytes.</returns>
        public override int Read(byte[] buffer, int offset, int count)
        {
            var startTime = DateTime.Now;
            var bytesReadTotal = 0;

            while (bytesReadTotal < count && DateTime.Now - this.timeout < startTime)
            {
                if (this.currentInboundTDSHeader == null || this.currentInboundPacketPosition >= this.currentInboundTDSHeader.ConvertedPacketLength)
                {
                    byte[] headerBuffer = new byte[8];
                    int curPos = 0;
                    do
                    {
                        curPos += this.InnerStream.Read(headerBuffer, curPos, 8 - curPos);

                        if (curPos == 0)
                        {
                            throw new Exception("Failure to read from network stream.");
                        }
                    }
                    while (curPos < 8 && DateTime.Now - this.timeout < startTime);

                    if (DateTime.Now - this.timeout >= startTime)
                    {
                        throw new TimeoutException("Reading from network stream timed out.");
                    }

                    this.currentInboundTDSHeader = new TDSPacketHeader();
                    this.currentInboundTDSHeader.Unpack(new MemoryStream(headerBuffer));
                    this.currentInboundPacketPosition = 8;
                }

                var bytesToReadFromCurrentPacket = Math.Min(count - bytesReadTotal, this.currentInboundTDSHeader.ConvertedPacketLength - this.currentInboundPacketPosition);

                do
                {
                    var bytesRead = this.InnerStream.Read(buffer, offset + bytesReadTotal, bytesToReadFromCurrentPacket);

                    if (bytesRead == 0)
                    {
                        throw new Exception("Failure to read from network stream.");
                    }

                    bytesToReadFromCurrentPacket -= bytesRead;
                    this.currentInboundPacketPosition += bytesRead;
                    bytesReadTotal += bytesRead;
                }
                while (bytesToReadFromCurrentPacket > 0 && DateTime.Now - this.timeout < startTime);

                if (this.currentInboundTDSHeader != null && this.currentInboundPacketPosition >= this.currentInboundTDSHeader.ConvertedPacketLength && (this.currentInboundTDSHeader.Status & TDSMessageStatus.EndOfMessage) == TDSMessageStatus.EndOfMessage)
                {
                    this.currentInboundTDSHeader = null;
                    return bytesReadTotal;
                }
            }

            if (DateTime.Now - this.timeout >= startTime)
            {
                throw new TimeoutException("Reading from network stream timed out.");
            }

            return bytesReadTotal;
        }

        /// <summary>
        /// Write to stream.
        /// </summary>
        /// <param name="buffer">Buffer containing data that's being written.</param>
        /// <param name="offset">Offset within buffer.</param>
        /// <param name="count">Number of bytes to write.</param>
        public override void Write(byte[] buffer, int offset, int count)
        {
            this.currentOutboundTDSHeader = new TDSPacketHeader(this.CurrentOutboundMessageType, TDSMessageStatus.Normal, 0, 1);

            var bytesSent = 0;

            while (bytesSent < count)
            {
                if (count - bytesSent + 8 < this.negotiatedPacketSize)
                {
                    this.currentOutboundTDSHeader.Status = TDSMessageStatus.EndOfMessage;
                }

                var bufferSize = Math.Min(count - bytesSent + 8, this.negotiatedPacketSize);
                byte[] packetBuffer = new byte[bufferSize];

                this.currentOutboundTDSHeader.Length = Convert.ToUInt16(bufferSize);
                this.currentOutboundTDSHeader.Pack(new MemoryStream(packetBuffer));
                Array.Copy(buffer, offset + bytesSent, packetBuffer, 8, bufferSize - 8);

                this.InnerStream.Write(packetBuffer, 0, bufferSize);
                bytesSent += bufferSize - 8;

                this.currentOutboundTDSHeader.Packet = (byte)((this.currentOutboundTDSHeader.Packet + 1) % 256);
            }
        }

        /// <summary>
        /// Seek within stream.
        /// </summary>
        /// <param name="offset">Offset from origin.</param>
        /// <param name="origin">Origin to seek from.</param>
        /// <returns>The new position within current stream.</returns>
        public override long Seek(long offset, SeekOrigin origin)
        {
            return this.InnerStream.Seek(offset, origin);
        }

        /// <summary>
        /// Set stream length.
        /// </summary>
        /// <param name="value">New length.</param>
        public override void SetLength(long value)
        {
            this.InnerStream.SetLength(value);
        }

        /// <summary>
        /// Close this stream.
        /// </summary>
        public override void Close()
        {
            this.InnerStream.Close();
            base.Close();
        }
    }

}

"@

function Using-Object
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [AllowNull()]
        [Object]
        $InputObject,

        [Parameter(Mandatory = $true)]
        [scriptblock]
        $ScriptBlock
    )

    try
    {
        . $ScriptBlock
    }
    finally
    {
        if ($null -ne $InputObject -and $InputObject -is [System.IDisposable])
        {
            $InputObject.Dispose()
        }
    }
}

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp -ErrorAction SilentlyContinue

$preLoginMessage = "AAAQAAYBABYAAQUAFwAk/wAAAAEAAACZ2dq6TF91Tqd3QhqNHRpv9/WwhLbfCUO6JBKeUqXXDAAAAAA="
$tcpClient = New-Object System.Net.Sockets.TcpClient($hostName, $port)


Using-Object($stream = New-Object CL.TDSStream($tcpClient.GetStream(), [TimeSpan]::FromSeconds(30), 4096)) {
    $stream.CurrentOutboundMessageType = [CL.TDSMessageType]::PreLogin
    $writeBuffer = [Convert]::FromBase64String($preLoginMessage)
    $stream.Write($writeBuffer, 0, $writeBuffer.Length)
    $readBuffer = New-Object System.Byte[] 4096
    $bytesRead = $stream.Read($readBuffer, 0, $readBuffer.Length)
    $sslStream = New-Object System.Net.Security.SslStream($stream, $true)
    $sslStream.AuthenticateAsClient($hostName)
    $certificate = $sslStream.RemoteCertificate
    [System.IO.File]::WriteAllBytes($publicCertificateFile,$certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))    
}






