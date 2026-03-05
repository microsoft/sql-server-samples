using System;
using System.Collections;
using System.Collections.Generic;

namespace SensorModule.DataStructures
{
  /// <inheritdoc/>
  /// <summary>
  /// Ring buffer.
  /// 
  /// When writing to a full buffer:
  /// PushBack -> removes this[0] / Front()
  /// PushFront -> removes this[Size-1] / Back()
  /// 
  /// this implementation is inspired by
  /// http://www.boost.org/doc/libs/1_53_0/libs/Ring_buffer/doc/Ring_buffer.html
  /// because I liked their interface.
  /// </summary>
  public class RingBuffer<T> : IEnumerable<T>
  {
    private readonly T[] _buffer;

    /// <summary>
    /// The _start. Index of the first element in buffer.
    /// </summary>
    private int _start;

    /// <summary>
    /// The _end. Index after the last element in the buffer.
    /// </summary>
    private int _end;

    /// <summary>
    /// The _size. Buffer size.
    /// </summary>
    private int _size;

    public RingBuffer(int capacity)
      : this(capacity, new T[] { })
    {
    }

    /// <summary>
    /// Initializes a new instance of the <see cref="RingBuffer{T}"/> class.
    /// 
    /// </summary>
    /// <param name='capacity'>
    /// Buffer capacity. Must be positive.
    /// </param>
    /// <param name='items'>
    /// Items to fill buffer with. Items length must be less than capacity.
    /// Suggestion: use Skip(x).Take(y).ToArray() to build this argument from
    /// any enumerable.
    /// </param>
    public RingBuffer(int capacity, T[] items)
    {
      if (capacity < 1)
      {
        throw new ArgumentException(
          "Ring buffer cannot have negative or zero capacity.", nameof(capacity));
      }
      if (items == null)
      {
        throw new ArgumentNullException(nameof(items));
      }
      if (items.Length > capacity)
      {
        throw new ArgumentException(
          "Too many items to fit Ring buffer", nameof(items));
      }

      _buffer = new T[capacity];

      Array.Copy(items, _buffer, items.Length);
      _size = items.Length;

      _start = 0;
      _end = _size == capacity ? 0 : _size;
    }

    /// <summary>
    /// Maximum capacity of the buffer. Elements pushed into the buffer after
    /// maximum capacity is reached (IsFull = true), will remove an element.
    /// </summary>
    public int Capacity { get { return _buffer.Length; } }

    public bool IsFull
    {
      get
      {
        return Size == Capacity;
      }
    }

    public bool IsEmpty
    {
      get
      {
        return Size == 0;
      }
    }

    /// <summary>
    /// Current buffer size (the number of elements that the buffer has).
    /// </summary>
    public int Size { get { return _size; } }

    /// <summary>
    /// Element at the front of the buffer - this[0].
    /// </summary>
    /// <returns>The value of the element of type T at the front of the buffer.</returns>
    public T Front()
    {
      ThrowIfEmpty();
      return _buffer[_start];
    }

    /// <summary>
    /// Element at the back of the buffer - this[Size - 1].
    /// </summary>
    /// <returns>The value of the element of type T at the back of the buffer.</returns>
    public T Back()
    {
      ThrowIfEmpty();
      return _buffer[(_end != 0 ? _end : Capacity) - 1];
    }

    public T this[int index]
    {
      get
      {
        if (IsEmpty)
        {
          throw new IndexOutOfRangeException(string.Format("Cannot access index {0}. Buffer is empty", index));
        }
        if (index >= _size)
        {
          throw new IndexOutOfRangeException(string.Format("Cannot access index {0}. Buffer size is {1}", index, _size));
        }
        int actualIndex = InternalIndex(index);
        return _buffer[actualIndex];
      }
      set
      {
        if (IsEmpty)
        {
          throw new IndexOutOfRangeException(string.Format("Cannot access index {0}. Buffer is empty", index));
        }
        if (index >= _size)
        {
          throw new IndexOutOfRangeException(string.Format("Cannot access index {0}. Buffer size is {1}", index, _size));
        }
        int actualIndex = InternalIndex(index);
        _buffer[actualIndex] = value;
      }
    }

    /// <summary>
    /// Pushes a new element to the back of the buffer. Back()/this[Size-1]
    /// will now return this element.
    /// 
    /// When the buffer is full, the element at Front()/this[0] will be 
    /// popped to allow for this new element to fit.
    /// </summary>
    /// <param name="item">Item to push to the back of the buffer</param>
    public void PushBack(T item)
    {
      if (IsFull)
      {
        _buffer[_end] = item;
        Increment(ref _end);
        _start = _end;
      }
      else
      {
        _buffer[_end] = item;
        Increment(ref _end);
        ++_size;
      }
    }

    /// <summary>
    /// Pushes a new element to the front of the buffer. Front()/this[0]
    /// will now return this element.
    /// 
    /// When the buffer is full, the element at Back()/this[Size-1] will be 
    /// popped to allow for this new element to fit.
    /// </summary>
    /// <param name="item">Item to push to the front of the buffer</param>
    public void PushFront(T item)
    {
      if (IsFull)
      {
        Decrement(ref _start);
        _end = _start;
        _buffer[_start] = item;
      }
      else
      {
        Decrement(ref _start);
        _buffer[_start] = item;
        ++_size;
      }
    }

    /// <summary>
    /// Removes the element at the back of the buffer. Decreasing the 
    /// Buffer size by 1.
    /// </summary>
    public void PopBack()
    {
      ThrowIfEmpty("Cannot take elements from an empty buffer.");
      Decrement(ref _end);
      _buffer[_end] = default(T);
      --_size;
    }

    /// <summary>
    /// Removes the element at the front of the buffer. Decreasing the 
    /// Buffer size by 1.
    /// </summary>
    public void PopFront()
    {
      ThrowIfEmpty("Cannot take elements from an empty buffer.");
      _buffer[_start] = default(T);
      Increment(ref _start);
      --_size;
    }

    /// <summary>
    /// Copies the buffer contents to an array, according to the logical
    /// contents of the buffer (i.e. independent of the internal 
    /// order/contents)
    /// </summary>
    /// <returns>A new array with a copy of the buffer contents.</returns>
    public T[] ToArray()
    {
      T[] newArray = new T[Size];
      int newArrayOffset = 0;
      var segments = new ArraySegment<T>[2] { ArrayOne(), ArrayTwo() };
      foreach (ArraySegment<T> segment in segments)
      {
        Array.Copy(segment.Array, segment.Offset, newArray, newArrayOffset, segment.Count);
        newArrayOffset += segment.Count;
      }
      return newArray;
    }

    #region IEnumerable<T> implementation
    public IEnumerator<T> GetEnumerator()
    {
      var segments = new ArraySegment<T>[2] { ArrayOne(), ArrayTwo() };
      foreach (ArraySegment<T> segment in segments)
      {
        for (int i = 0; i < segment.Count; i++)
        {
          yield return segment.Array[segment.Offset + i];
        }
      }
    }
    #endregion
    #region IEnumerable implementation
    IEnumerator IEnumerable.GetEnumerator()
    {
      return (IEnumerator)GetEnumerator();
    }
    #endregion

    private void ThrowIfEmpty(string message = "Cannot access an empty buffer.")
    {
      if (IsEmpty)
      {
        throw new InvalidOperationException(message);
      }
    }

    /// <summary>
    /// Increments the provided index variable by one, wrapping
    /// around if necessary.
    /// </summary>
    /// <param name="index"></param>
    private void Increment(ref int index)
    {
      if (++index == Capacity)
      {
        index = 0;
      }
    }

    /// <summary>
    /// Decrements the provided index variable by one, wrapping
    /// around if necessary.
    /// </summary>
    /// <param name="index"></param>
    private void Decrement(ref int index)
    {
      if (index == 0)
      {
        index = Capacity;
      }
      index--;
    }

    /// <summary>
    /// Converts the index in the argument to an index in <code>_buffer</code>
    /// </summary>
    /// <returns>
    /// The transformed index.
    /// </returns>
    /// <param name='index'>
    /// External index.
    /// </param>
    private int InternalIndex(int index)
    {
      return _start + (index < (Capacity - _start) ? index : index - Capacity);
    }

    // doing ArrayOne and ArrayTwo methods returning ArraySegment<T> as seen here: 
    // http://www.boost.org/doc/libs/1_37_0/libs/Ring_buffer/doc/Ring_buffer.html#classboost_1_1Ring__buffer_1957cccdcb0c4ef7d80a34a990065818d
    // http://www.boost.org/doc/libs/1_37_0/libs/Ring_buffer/doc/Ring_buffer.html#classboost_1_1Ring__buffer_1f5081a54afbc2dfc1a7fb20329df7d5b
    // should help a lot with the code.

    #region Array items easy access.
    // The array is composed by at most two non-contiguous segments, 
    // the next two methods allow easy access to those.

    private ArraySegment<T> ArrayOne()
    {
      if (IsEmpty)
      {
        return new ArraySegment<T>(new T[0]);
      }
      else if (_start < _end)
      {
        return new ArraySegment<T>(_buffer, _start, _end - _start);
      }
      else
      {
        return new ArraySegment<T>(_buffer, _start, _buffer.Length - _start);
      }
    }

    private ArraySegment<T> ArrayTwo()
    {
      if (IsEmpty)
      {
        return new ArraySegment<T>(new T[0]);
      }
      else if (_start < _end)
      {
        return new ArraySegment<T>(_buffer, _end, 0);
      }
      else
      {
        return new ArraySegment<T>(_buffer, 0, _end);
      }
    }
    #endregion
  }
}
