// node_modules
import React, { Component } from 'react';
import './Home.scss';
import { Link } from 'react-router-dom';
import Turbine from './components/Turbine';
import Grid from '../../assets/grid.svg';
import Line from '../../assets/line-issue.svg';
import { PulseRing } from './components/PulseRIng';

const turbinesData = [
  {
    left: '14.15',
    top: '6.25',
    scale: 0.45
  },
  {
    left: '24.65',
    top: '7',
    scale: 0.45
  },
  {
    left: '34.3',
    top: '7.7',
    scale: 0.45
  },
  {
    left: '45.35',
    top: '8.5',
    scale: 0.45
  },
  {
    left: '59.2',
    top: '9.5',
    scale: 0.45
  },
  {
    left: '70',
    top: '10.2',
    scale: 0.45
  },
  {
    left: '77.55',
    top: '10.8',
    scale: 0.45
  },
  {
    left: '2.25',
    top: '6.2',
    scale: 0.6
  },
  {
    left: '13.65',
    top: '7.3',
    scale: 0.6
  },
  {
    left: '24',
    top: '8.4',
    scale: 0.6
  },
  {
    left: '37.3',
    top: '9.65',
    scale: 0.6
  },
  {
    left: '53.3',
    top: '11.3',
    scale: 0.6
  },
  {
    left: '66.9',
    top: '12.6',
    scale: 0.6
  },
  {
    left: '76.5',
    top: '13.6',
    scale: 0.6
  },
  {
    left: '0.5',
    top: '7.9',
    scale: 0.75
  },
  {
    left: '12.5',
    top: '9.3',
    scale: 0.75
  },
  {
    left: '27.9',
    top: '11.2',
    scale: 0.75
  },
  {
    left: '46.9',
    top: '13.6',
    scale: 0.75
  },
  {
    left: '63.35',
    top: '15.6',
    scale: 0.75
  },
  {
    left: '75.45',
    top: '17.2',
    scale: 0.75
  },
  {
    left: '0.15',
    top: '9.9',
    scale: 0.95
  },
  {
    left: '17.65',
    top: '12.5',
    scale: 0.95
  },
  {
    left: '39.6',
    top: '15.7',
    scale: 0.95,
    canSlowDown: true
  },
  {
    left: '59.3',
    top: '18.5',
    scale: 0.95
  },
  {
    left: '74.1',
    top: '20.5',
    scale: 0.95
  },
  {
    left: '2.85',
    top: '14.9',
    scale: 1.20
  },
  {
    left: '28.8',
    top: '19.6',
    scale: 1.20
  },
  {
    left: '53.1',
    top: '24.1',
    scale: 1.20
  },
  {
    left: '72.25',
    top: '27.5',
    scale: 1.20
  },
  {
    left: '10.7',
    top: '24.5',
    scale: 1.7
  },
  {
    left: '42.4',
    top: '32.7',
    scale: 1.7
  },
  {
    left: '68.4',
    top: '40.7',
    scale: 1.7
  }
]

export class Home extends Component {
  
  componentDidMount() {
    this.props.onSelect('dashboard');
  }

  render() {
      return (
          <div className="Home">
            {this.props.showAlert && <PulseRing />}
            <img src={Grid} alt="grid" className="grid" />
            {turbinesData.map((t, i) =>
              <div className="turbine-wrap" key={`turbine-${i}`} style={{ left: `${t.left}vw`, top: `${t.top}vw` }}>
                <Turbine scale={t.scale} slow={t.canSlowDown && this.props.showAlert} />
              </div>
            )}
            {this.props.showAlert &&
            <>
              <img src={Line} alt="" className="line-issue" />
              <div className="alert">
                <h3>Issue Detected</h3>
                <p>Unit 34 is experiencing an issue…</p>
                <Link to="/alerts"><button>VIEW</button></Link>
              </div>
            </>}
          </div>
      )
  }
}
