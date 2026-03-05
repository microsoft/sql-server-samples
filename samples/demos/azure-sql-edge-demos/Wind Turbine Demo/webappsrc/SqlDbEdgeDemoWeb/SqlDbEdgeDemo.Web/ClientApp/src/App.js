// node_modules
import React, { Component } from 'react'
import { BrowserRouter as Router, Route, Redirect } from "react-router-dom";
import "normalize.css";
import "./styles/global.scss";

// local components
import { Layout } from "./components/Layout";
import { Home } from "./pages/Home";
import Alerts from './pages/Alerts';

export default class App extends Component {
  state = {
    selected: 'dashboard',
    showAlert: false,
    showToast: false
  }

  componentDidMount() {
    this.pollForAlert();
  }

  componentWillUnmount() {
    clearInterval(this.interval);
  }

  pollForAlert = () => {
    this.interval = setInterval(()=> {
      fetch('/api/device').then(res => res.json()).then(json => {
        const showToast = (this.state.showAlert && json.alert === false) || (this.state.showToast && json.alert === false);
        this.setState({ showAlert: json.alert ? json.alert : false, showToast });
      }).catch();
    }, 1000);
  }

  onSelect = (selected) => {
    this.setState({ selected });
  }

  setShowToast = (showToast) => {
    this.setState({ showToast });
  }

  render() {
    const { selected, showAlert, showToast } = this.state;
    return (
      <Router>
        <Layout selected={selected} showToast={showToast} setShowToast={this.setShowToast}>
          <Route path="/" exact render={() => <Redirect to="/dashboard" />}/>
          <Route path="/dashboard" exact render={() => <Home onSelect={this.onSelect} showAlert={showAlert} />} />
          <Route path="/alerts" exact render={() => <Alerts onSelect={this.onSelect} />} />
        </Layout>
      </Router>
    )
  }
}
