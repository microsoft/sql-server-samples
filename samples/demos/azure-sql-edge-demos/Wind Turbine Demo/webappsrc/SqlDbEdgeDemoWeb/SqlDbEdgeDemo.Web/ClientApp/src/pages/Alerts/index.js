import React, { Component } from 'react';
import SVG from 'react-inlinesvg';
import './Alerts.scss';
import TurbineImage from '../../assets/turbine.svg';
import LinePowerGenerated from '../../assets/line-power-generated.svg';
import LineOilTemperature from '../../assets/line-oil-temperature.svg';
import LineVibration from '../../assets/line-vibration.svg';
import LineWindSpeed from '../../assets/line-wind-speed.svg';
import LineWindDirection from '../../assets/line-wind-direction.svg';
import LineSecurityAlert from '../../assets/line-security-alerts.svg';
import GraphPowerGenerated from '../../assets/graph-power-generated.svg';
import GraphOilTemperature from '../../assets/graph-oil-temperature.svg';
import GraphVibration from '../../assets/graph-vibration.svg';
import GraphWindSpeedFarm from '../../assets/graph-wind-speed-farm.svg';
import GraphWindDirectionFarm from '../../assets/graph-wind-direction-farm.svg';
import GraphWindSpeedTurbine from '../../assets/graph-wind-speed-turbine.svg';
import GraphWindDirectionTurbine from '../../assets/graph-wind-direction-turbine.svg';
import GraphWindSpeedTurbineV2 from '../../assets/graph-wind-speed-after.svg';
import GraphWindDirectionTurbineV2 from '../../assets/graph-wind-direction-after.svg';
import RefreshIcon from '../../assets/icon-refresh.svg';

export default class Alerts extends Component {

  state = {
    progress: 0,
    selectedView: 'progress',
    hasRefreshed: false
  }

  componentDidMount() {
    this.props.onSelect('alerts');
    this.startLoading()
  }

  startLoading() {
    this.interval = setInterval(() => {
      this.setState({ progress: this.state.progress + 1 }, () => {
        if (this.state.progress === 100) {
          clearInterval(this.interval);
          this.setState({ selectedView: 'mechanical', progress: 0 });
        } 
      })
    }, 30)
  }

  onRefresh = () => {
    this.setState({ selectedView: 'progress' }, () => {
      this.interval = setInterval(() => {
        this.setState({ progress: this.state.progress + 1 }, () => {
          if (this.state.progress === 100) {
            clearInterval(this.interval)
            this.setState({ selectedView: 'environmental', progress: 0, hasRefreshed: true });
          } 
        })
      }, 30)
    })
  }

  render() {
    const { selectedView, progress, hasRefreshed } = this.state;
    return (
      <div className="Alerts">
        <img src={TurbineImage} alt="turbine" className="turbine"/>
        {selectedView === 'mechanical' && <>
          <img src={LinePowerGenerated} alt="" className="line power-generated" />
          <img src={LineOilTemperature} alt="" className="line oil-temperature" />
          <img src={LineVibration} alt="" className="line vibration" />
          <img src={LineSecurityAlert} alt="" className="line security" />
        </>}
        {selectedView === 'environmental' && <>
          <img src={LineWindSpeed} alt="" className="line wind-speed" />
          <img src={LineWindDirection} alt="" className="line wind-direction" />
        </>}
        {selectedView === 'progress' && <div className="loader">
          <p>Running Query for Unit 34…</p>
          <div className="progress-border">
            <div className="progress" style={{width: `${progress}%`}}></div>
          </div>
        </div>}
        {selectedView !== 'progress' && <div className="content-wrap">
          <>
          <div className="menu">
            <button onClick={() => this.setState({ selectedView: 'mechanical'})} className={selectedView === 'mechanical' ? 'selected' : ''}>Mechanical</button>
            <button onClick={() => this.setState({ selectedView: 'environmental'})} className={selectedView === 'environmental' ? 'selected' : ''}>Environmental</button>
          </div>
          <button className="refresh" onClick={this.onRefresh}>
            <img className="icon" src={RefreshIcon} alt="refresh" />
            Refresh
          </button>
          </>
          {selectedView === 'mechanical' && <div className="mechanical-wrap">
            <div className="panel power">
              <div className="panel-heading">
                <h3>Power Generated</h3>
                <span className="legend">
                  <div className="ball"></div>Expected
                  <div className="ball actual"></div>Actual
                </span>
              </div>
              <SVG src={GraphPowerGenerated} alt="" className="graph power-generated" />
            </div>
            <div className="panel vibrations">
              <div className="panel-heading">
                <h3>Vibration</h3>
                <span className="legend">
                  <div className="ball"></div>Expected
                  <div className="ball actual"></div>Actual
                </span>
              </div>
              <SVG src={GraphVibration} alt="" className="graph vibration" />
            </div>
            <div className="panel security">
              <div className="panel-heading">
                <h3>Security Alert</h3>
              </div>
              <p className="padded">No events visible to current user</p>
            </div>
            <div className="panel oil">
              <div className="panel-heading">
                <h3>Oil Temperature</h3>
                <span className="legend">
                  <div className="ball"></div>Expected
                  <div className="ball actual"></div>Actual
                </span>
              </div>
              <SVG src={GraphOilTemperature} alt="" className="graph oil-temperature" />
            </div>
            <div className="stats-panels">
              <div className="panel small">
                <div className="panel-heading">
                  <h3>Fire</h3>
                </div>
                <p>None detected</p>
              </div>
              <div className="panel small">
                <div className="panel-heading">
                  <h3>Malfunction</h3>
                </div>
                <p>None detected</p>
              </div>
              <div className="panel small">
                <div className="panel-heading">
                  <h3>Part Failure</h3>
                </div>
                <p>None detected</p>
              </div>
            </div>
          </div>}
          {selectedView === 'environmental' && <div className="environmental-wrap">
              <div className="left-panels">
                <div className="panel">
                  <div className="panel-heading">
                    <h3>Wind Speed (farm)</h3>
                  </div>
                  <SVG src={GraphWindSpeedFarm} alt="" className="graph wind-speed-farm" />
                </div>
                <div className="panel">
                  <div className="panel-heading">
                    <h3>Wind Direction (farm)</h3>
                  </div>
                  <SVG src={GraphWindDirectionFarm} alt="" className="graph wind-direction-farm" />
                </div>
                <div className="bottom-panels">
                  <div className="panel">
                    <div className="panel-heading">
                      <h3>Temperature</h3>
                    </div>
                    <div className="stat">32°F</div>
                  </div>
                  <div className="panel">
                    <div className="panel-heading">
                      <h3>Humidity</h3>
                    </div>
                    <div className="stat">12%</div>
                  </div>
                </div>
              </div>
              <div className="right-panels">
                <div className="panel">
                  <div className="panel-heading">
                    <h3>Wind Speed (turbine)</h3>
                  </div>
                  <SVG src={hasRefreshed ? GraphWindSpeedTurbineV2 : GraphWindSpeedTurbine} alt="" className="graph wind-speed-turbine" />
                </div>
                <div className="panel">
                  <div className="panel-heading">
                    <h3>Wind Direction (turbine)</h3>
                  </div>
                  <SVG src={hasRefreshed ? GraphWindDirectionTurbineV2 : GraphWindDirectionTurbine} alt="" className="graph wind-direction-turbine" />
                </div>
                <div className="bottom-panels">
                  <div className="panel">
                    <div className="panel-heading">
                      <h3>Temperature</h3>
                    </div>
                    <div className="stat">32°F</div>
                  </div>
                  <div className="panel">
                    <div className="panel-heading">
                      <h3>Humidity</h3>
                    </div>
                    <div className="stat">12%</div>
                  </div>
                </div>
              </div>
          </div>}
        </div>}
      </div>
    )
  }
}
