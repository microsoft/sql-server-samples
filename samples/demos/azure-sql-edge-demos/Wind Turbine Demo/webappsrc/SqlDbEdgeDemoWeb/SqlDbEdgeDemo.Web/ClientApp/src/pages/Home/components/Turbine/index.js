import React, { Component } from 'react'
import './Turbine.scss';

export default class Turbine extends Component {
  
  state = {
    rotationDegrees: 0,
    slowRotationDegrees: 0
  }

  componentDidMount() {
    this.interval = setInterval(() => {
      this.setState({
        rotationDegrees: this.state.rotationDegrees === 360 ? 10 : this.state.rotationDegrees + 10,
        slowRotationDegrees: this.state.slowRotationDegrees === 360 ? 5 : this.state.slowRotationDegrees + 5,
      })
    }, 3000/36);
  }

  render() {
    const { rotationDegrees, slowRotationDegrees } = this.state;
    return (
      <div className="Turbine" style={{ transform: `scale(${this.props.scale ? this.props.scale : 1})`, transformOrigin: 0 }}>
        <svg xmlns="http://www.w3.org/2000/svg" width="30.836" height="287.058" viewBox="0 0 30.836 287.058" className="base">
            <g transform="translate(-660.743 -587.33)">
                <path className="a" d="M773.076,807.434c0,2.083-6.059,3.771-13.533,3.771s-13.532-1.688-13.532-3.771V773.461l6.014-225.189h15.036l6.015,225.189Z" transform="translate(-82.493 63.058)"/>
                <path d="M773.076,773.461c0,2.083-6.059,3.771-13.533,3.771s-13.532-1.688-13.532-3.771v33.973c0,2.083,6.059,3.771,13.532,3.771s13.533-1.688,13.533-3.771Z" transform="translate(-82.493 63.058)" style={{ fill: '#f15a24', stroke: '#000', strokeMiterlimit: 10, strokeWidth: '.25px'}}/>
                <path className="a" d="M763.772,559.976,745,550.381c-1.407,0-1.917-10.7-1.405-12.1l9.5-11.405a4.493,4.493,0,0,1,3.474-2.548h14.845a2.509,2.509,0,0,1,2.463,2.548l.068,11.67a13.78,13.78,0,0,1-.33,3.089l-6.369,15.8A4.031,4.031,0,0,1,763.772,559.976Z" transform="translate(-82.493 63.13)"/>
            </g>
        </svg>
        <svg xmlns="http://www.w3.org/2000/svg" width="180" height="180" viewBox="0 0 220 220" className="top">
          <g transform="translate(-558 -503.873)">
              <rect className="a" width="24.053" height="23.408" rx="6.332" transform="translate(660.702 599.699)"/>
              <g transform={`translate(-82.493 63.13)${this.props.slow ? 'rotate('+ slowRotationDegrees+ ', 755.221, 548.272)' : 'rotate('+ rotationDegrees+ ', 755.221, 548.272)'}`}>
                  <circle className="a" cx="12.989" cy="12.989" r="12.989" transform="translate(742.232 535.283)"/>
                  <path className="a" d="M761.348,550.827h2.8a.8.8,0,0,0,.228-.456,6.969,6.969,0,0,1-.587-2.02v-.158a6.993,6.993,0,0,1,.587-2.02.8.8,0,0,0-.228-.456h-2.8Z"/>
                  <path className="a" d="M763.729,550.381l93.181-4.867a1.569,1.569,0,0,0,1.454-1.882l-.941-4.571a1.568,1.568,0,0,0-1.5-1.251l-86.342-1.826a2.128,2.128,0,0,0-2.168,1.947c-.229,2.686-.925,7.253-3.032,8.287C761.348,547.7,763.729,550.381,763.729,550.381Z"/>
                  <line className="a" y1="2.349" x2="79.514" transform="translate(770.392 543.824)"/>
                  <path className="a" d="M752.79,539.847l-50.8-78.263a1.568,1.568,0,0,0-2.357-.318l-3.488,3.1a1.568,1.568,0,0,0-.333,1.927L737.4,541.98a2.125,2.125,0,0,0,2.769.9c2.44-1.144,6.744-2.825,8.693-1.517C751.664,543.248,752.79,539.847,752.79,539.847Z"/>
                  <path className="a" d="M754.368,541.687l-1.4-2.427a.8.8,0,0,0-.509.031c-.2.114-.638,1.045-1.456,1.518l-.137.078a6.953,6.953,0,0,1-2.042.5.794.794,0,0,0-.281.426l1.4,2.427Z"/>
                  <line className="a" x1="41.791" y1="67.686" transform="translate(704.024 468.495)"/>
                  <path className="a" d="M749.138,554.589l-42.375,83.13a1.568,1.568,0,0,0,.9,2.2l4.429,1.47a1.567,1.567,0,0,0,1.835-.676l44.752-73.861a2.128,2.128,0,0,0-.6-2.851c-2.212-1.541-5.819-4.428-5.661-6.77C752.647,553.864,749.138,554.589,749.138,554.589Z"/>
                  <path className="a" d="M749.943,552.3l-1.4,2.426a.794.794,0,0,0,.281.426,6.986,6.986,0,0,1,2.042.5l.137.079c.818.472,1.258,1.4,1.456,1.518a.8.8,0,0,0,.509.03l1.4-2.426Z"/>
                  <line className="a" x1="37.722" y2="70.035" transform="translate(711.728 562.462)"/>
              </g>
              <circle className="a" cx="7.518" cy="7.518" r="7.518" transform="translate(665.21 603.885)"/>
          </g>
        </svg>
      </div>
    )
  }
}
