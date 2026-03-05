import React, { useState, useEffect } from 'react';
import './PulseRing.scss';

export const PulseRing = () => {

  const [status, setStatus] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      if (status === 3) {
        setStatus(0);
      } else {
        setStatus(status + 1);
      }
    }, 300);
    return () => {
      clearInterval(interval);
    }
  })

  return (
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 185.458 118.271" className="PulseRing">
        <g transform="translate(-1060.043 -454.703)">
            <g transform="matrix(0.999, 0.052, -0.052, 0.999, 1065.747, 454.703)" style={{ strokeWidth: '2px', stroke: 'rgba(0,153,154,.15)', fill:'none', opacity: status === 3 ? 1 : 0}}>
                <ellipse class="e" cx="90" cy="54.5" rx="90" ry="54.5"/>
                <ellipse class="f" cx="90" cy="54.5" rx="89" ry="53.5"/>
            </g>
            <g transform="matrix(0.999, 0.052, -0.052, 0.999, 1089.714, 466.959)" style={{ stroke: 'rgba(0,153,154,.3)', strokeWidth: '2px', fill:'none', opacity: status > 2 ? 1 : 0 }}>
                <ellipse class="e" cx="66" cy="39.5" rx="66" ry="39.5"/>
                <ellipse class="f" cx="66" cy="39.5" rx="65" ry="38.5"/>
            </g>
            <g transform="matrix(0.999, 0.052, -0.052, 0.999, 1106.69, 475.901)" style={{ stroke: 'rgba(0,153,154,.65)', strokeWidth: '2px', fill: 'none', opacity: status > 1 ? 1 : 0 }}>
                <ellipse class="e" cx="48" cy="29" rx="48" ry="29"/>
                <ellipse class="f" cx="48" cy="29" rx="47" ry="28"/>
            </g>
            <g transform="matrix(0.999, 0.052, -0.052, 0.999, 1123.665, 487.843)" style={{ stroke: '#00999a', strokeWidth: '2px', fill:'none', opacity: status > 0 ? 1 : 0 }}>
                <ellipse class="e" cx="30" cy="17" rx="30" ry="17"/>
                <ellipse class="f" cx="30" cy="17" rx="29" ry="16"/>
            </g>
        </g>
    </svg>

  )
}
