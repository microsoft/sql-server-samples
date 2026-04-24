import React, { Component } from 'react';
import IconClose from '../../assets/icon-close.svg';
import IconTick from '../../assets/icon-tick.svg';
import './Toast.scss';

export default class Toast extends Component {
  render() {
    return (
      <div className="Toast">
        <img src={IconTick} alt="icon tick" className="icon-tick" />
        <span>Alert resolved</span>
        <img src={IconClose} alt="icon close" className="icon-close" onClick={this.props.onClose} />
      </div>
    )
  }
}
